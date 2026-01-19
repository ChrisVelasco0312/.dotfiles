#!/run/current-system/sw/bin/bash

# Windows 11 VM with GPU Passthrough
# Uses OVMF/EDK2 for UEFI boot
#
# SETUP REQUIRED BEFORE FIRST USE:
# 1. Create OVMF NVRAM copy (run the commands printed when this script starts)
#
# 2. Get USB device IDs (run `lsusb` and find keyboard/mouse):
#    Update the USB passthrough lines below with your device IDs
#
# 3. For Windows installation, add these lines temporarily:
#    -cdrom /path/to/Win11.iso \
#    -boot d \

set -e

QEMU_CMD="/run/current-system/sw/bin/qemu-system-x86_64"

# Find OVMF/EDK2 files dynamically (bundled with QEMU in NixOS)
QEMU_SHARE_DIR="$(dirname "$QEMU_CMD")/../share/qemu"

# Try common paths for EDK2/OVMF CODE file
if [[ -f "$QEMU_SHARE_DIR/edk2-x86_64-code.fd" ]]; then
  OVMF_CODE="$QEMU_SHARE_DIR/edk2-x86_64-code.fd"
elif [[ -f "/run/current-system/sw/share/qemu/edk2-x86_64-code.fd" ]]; then
  OVMF_CODE="/run/current-system/sw/share/qemu/edk2-x86_64-code.fd"
else
  # Fallback: find it in the nix store via qemu binary
  QEMU_REAL=$(readlink -f "$QEMU_CMD")
  QEMU_STORE_DIR=$(dirname "$(dirname "$QEMU_REAL")")
  OVMF_CODE="$QEMU_STORE_DIR/share/qemu/edk2-x86_64-code.fd"
fi

OVMF_VARS="/var/lib/libvirt/qemu/nvram/windows11_VARS.fd"

# Verify files exist
if [[ ! -f "$OVMF_CODE" ]]; then
  echo "ERROR: OVMF CODE file not found at: $OVMF_CODE"
  echo "Searching for it..."
  find /nix/store -maxdepth 3 -name "edk2-x86_64-code.fd" 2>/dev/null | head -3
  exit 1
fi

if [[ ! -f "$OVMF_VARS" ]]; then
  echo "ERROR: OVMF VARS file not found at: $OVMF_VARS"
  echo ""
  echo "Please create it with:"
  VARS_SOURCE=$(dirname "$OVMF_CODE")/edk2-i386-vars.fd
  echo "  sudo mkdir -p /var/lib/libvirt/qemu/nvram"
  echo "  sudo cp $VARS_SOURCE $OVMF_VARS"
  echo "  sudo chmod 644 $OVMF_VARS"
  exit 1
fi

echo "Using OVMF CODE: $OVMF_CODE"
echo "Using OVMF VARS: $OVMF_VARS"
echo "Starting Windows 11 VM..."

exec $QEMU_CMD \
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
  -drive file=/dev/sdb,format=raw,if=none,id=disk0,cache=none \
  -device ahci,id=ahci \
  -device ide-hd,drive=disk0,bus=ahci.0 \
  \
  -cdrom "/mnt/myfiles/software/Windows 11/windows_iso.iso" \
  \
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

# Notes:
# - USB passthrough: Add lines like these for keyboard/mouse (get IDs from lsusb):
#   -device usb-host,vendorid=0xXXXX,productid=0xXXXX \
# - Port 3389 is forwarded for RDP access (optional fallback)
# - GPU output goes to the physical GPU ports - connect monitor there
