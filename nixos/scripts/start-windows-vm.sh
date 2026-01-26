#!/run/current-system/sw/bin/bash

# Windows 11 VM with GPU Passthrough
# Uses OVMF/EDK2 for UEFI boot

set -e

QEMU_CMD="/run/current-system/sw/bin/qemu-system-x86_64"

# Find OVMF/EDK2 files dynamically
QEMU_SHARE_DIR="$(dirname "$QEMU_CMD")/../share/qemu"
if [[ -f "$QEMU_SHARE_DIR/edk2-x86_64-code.fd" ]]; then
  OVMF_CODE="$QEMU_SHARE_DIR/edk2-x86_64-code.fd"
elif [[ -f "/run/current-system/sw/share/qemu/edk2-x86_64-code.fd" ]]; then
  OVMF_CODE="/run/current-system/sw/share/qemu/edk2-x86_64-code.fd"
else
  QEMU_REAL=$(readlink -f "$QEMU_CMD")
  QEMU_STORE_DIR=$(dirname "$(dirname "$QEMU_REAL")")
  OVMF_CODE="$QEMU_STORE_DIR/share/qemu/edk2-x86_64-code.fd"
fi

OVMF_VARS="/var/lib/libvirt/qemu/nvram/windows11_VARS.fd"

if [[ ! -f "$OVMF_CODE" ]]; then
  echo "ERROR: OVMF CODE not found: $OVMF_CODE"
  exit 1
fi

if [[ ! -f "$OVMF_VARS" ]]; then
  echo "ERROR: OVMF VARS not found. Create with:"
  echo "  sudo cp $(dirname "$OVMF_CODE")/edk2-i386-vars.fd $OVMF_VARS"
  exit 1
fi

# Ensure myfiles disk is not mounted
echo "Ensuring /mnt/myfiles is unmounted..."
sudo umount -f /mnt/myfiles 2>/dev/null || true
sleep 1

# Verify disk is accessible
MYFILES_DISK="/dev/disk/by-id/ata-ST2000DM001-9YN164_W1E0DC7R"
if [[ ! -e "$MYFILES_DISK" ]]; then
  echo "ERROR: Myfiles disk not found: $MYFILES_DISK"
  exit 1
fi

echo "Starting Windows 11 VM..."
echo "Myfiles disk: $MYFILES_DISK"

# Setup tap device for bridged networking
TAP_DEV="tap-winvm"
BRIDGE="virbr0"

echo "Setting up network bridge..."
/run/current-system/sw/bin/ip tuntap add dev $TAP_DEV mode tap
/run/current-system/sw/bin/ip link set $TAP_DEV up
/run/current-system/sw/bin/ip link set $TAP_DEV master $BRIDGE

# Cleanup on exit
cleanup() {
  echo "Cleaning up tap device..."
  /run/current-system/sw/bin/ip link set $TAP_DEV down 2>/dev/null || true
  /run/current-system/sw/bin/ip tuntap del dev $TAP_DEV mode tap 2>/dev/null || true
  echo "Remounting /mnt/myfiles..."
  sudo mount /mnt/myfiles 2>/dev/null || true
}
trap cleanup EXIT

TASKSET_CMD="/run/current-system/sw/bin/taskset"
CHRT_CMD="/run/current-system/sw/bin/chrt"

# CPU pinning: Run QEMU on CPUs 4-11 (cores 2-5)
# This leaves cores 0-1 (CPUs 0-3) for host OS and QEMU I/O
# We use -smp 6 (3 cores/6 threads) to leave 1 physical core (2 threads)
# on the pinned set (4-11) for QEMU emulator threads/IO to prevent audio starvation.
exec $TASKSET_CMD -c 4-11 $CHRT_CMD -f 1 $QEMU_CMD \
  -name "Windows11-GPU" \
  -enable-kvm \
  -machine q35,accel=kvm,kernel-irqchip=on \
  -cpu host,kvm=on,topoext=on,host-cache-info=on,hv_time,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_vpindex,hv_synic,hv_stimer,hv_reset \
  -smp 6,sockets=1,cores=3,threads=2 \
  -m 16G \
  -mem-prealloc \
  -mem-path /dev/hugepages \
  -overcommit mem-lock=on \
  \
  -rtc base=localtime,driftfix=slew \
  -global kvm-pit.lost_tick_policy=delay \
  -global ICH9-LPC.disable_s3=1 \
  \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS" \
  \
  -drive file=/dev/disk/by-id/ata-ADATA_SU630_2J3320030962,format=raw,if=none,id=disk0,cache=none,aio=native,discard=unmap \
  -device virtio-blk-pci,drive=disk0,bootindex=1 \
  \
  -drive file="$MYFILES_DISK",format=raw,if=none,id=disk1,cache=writethrough,detect-zeroes=on \
  -device virtio-blk-pci,drive=disk1,physical_block_size=4096,logical_block_size=512 \
  \
  -device vfio-pci,host=26:00.0,multifunction=on \
  -device vfio-pci,host=26:00.1 \
  \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:56 \
  -netdev tap,id=net0,ifname=$TAP_DEV,script=no,downscript=no \
  \
  -device vfio-pci,host=27:00.3 \
  \
  -usb \
  -device usb-host,vendorid=0x0bda,productid=0x8771 \
  \
  -vga std \
  -vnc 0.0.0.0:0 \
  -monitor stdio
