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

# Remount on exit
cleanup() {
  echo "Remounting /mnt/myfiles..."
  sudo mount /mnt/myfiles 2>/dev/null || true
}
trap cleanup EXIT

$QEMU_CMD \
  -name "Windows11-GPU" \
  -enable-kvm \
  -machine q35,accel=kvm \
  -cpu host,kvm=on \
  -smp cores=6,threads=1 \
  -m 16G \
  \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS" \
  \
  -drive file=/dev/disk/by-id/ata-ADATA_SU630_2J3320030962,format=raw,if=none,id=disk0,cache=none \
  -device ahci,id=ahci \
  -device ide-hd,drive=disk0,bus=ahci.0 \
  \
  -drive file="$MYFILES_DISK",format=raw,if=none,id=disk1,cache=writethrough,detect-zeroes=on \
  -device virtio-blk-pci,drive=disk1,physical_block_size=4096,logical_block_size=512 \
  \
  -device vfio-pci,host=26:00.0,multifunction=on \
  -device vfio-pci,host=26:00.1 \
  \
  -device e1000,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  \
  -usb \
  -device usb-host,vendorid=0x04f2,productid=0x0402 \
  -device usb-host,vendorid=0x0bda,productid=0x8771 \
  -device usb-host,vendorid=0x1235,productid=0x8219 \
  \
  -vga std \
  -vnc 0.0.0.0:0 \
  -monitor stdio
