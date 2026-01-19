# Windows 11 VM with GPU Passthrough - Implementation Plan

> **Goal:** Create a second GRUB boot option that launches NixOS in headless mode and automatically starts a Windows 11 VM with full GPU passthrough using QEMU/KVM.

---

## ⚠️ IMPORTANT RULES FOR AI AGENTS ⚠️

**READ THIS BEFORE MAKING ANY CHANGES:**

1. **DO NOT run `nixos-rebuild` commands** — Only the user runs these manually.

2. **DO NOT run `reboot`, `shutdown`, or `poweroff` commands** — Only the user initiates reboots.

3. **DO NOT run any NixOS system commands** — Ask the user first before suggesting any system-level command.

4. **STOP and notify the user** when:
   - Configuration changes are complete and a rebuild is needed
   - A reboot is required to test changes
   - Any destructive or system-altering command is needed

5. **Workflow:**
   - Agent makes configuration file changes
   - Agent STOPS and tells user: "Changes complete. Please run: `sudo nixos-rebuild switch --flake ~/.dotfiles#nixos`"
   - User runs the command and reports result
   - Agent continues or troubleshoots based on result

6. **Before each session:** Check the "Current Progress" section below to see what's already done.

---

## Expected Workflow (Stop Points)

```
┌─────────────────────────────────────────────────────────────┐
│  AGENT: Makes config file changes (Steps 1-4)               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  🛑 STOP: "Please run: sudo nixos-rebuild switch ..."       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  USER: Runs rebuild command, reports success/failure        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  🛑 STOP: "Please reboot and select 'NixOS - windows-vm'"   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  USER: Reboots, tests, reports results in new session       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  AGENT: Reviews results, troubleshoots or continues         │
└─────────────────────────────────────────────────────────────┘
```

---

## Hardware Information

| Component | Details |
|-----------|---------|
| **CPU** | AMD Ryzen 5 1600 Six-Core (AMD-V supported) |
| **GPU** | NVIDIA GeForce GTX 1060 6GB |
| **GPU PCI Address** | `26:00.0` (GPU), `26:00.1` (Audio) |
| **GPU PCI IDs** | `10de:1c03` (GPU), `10de:10f1` (Audio) |
| **IOMMU Group** | Group 15 (contains only GPU + Audio — perfect isolation) |
| **VM Disk** | `/dev/sdb` — ADATA SU630 447GB SSD (GPT formatted, ready) |
| **System Disk** | `/dev/nvme0n1` — WD_BLACK SN770 1TB (NixOS) |

---

## Verification Commands

Run these to verify hardware status at any time:

```bash
# Check IOMMU is active
sudo dmesg | grep -i -E "iommu|amd-vi" | head -20

# Check GPU IOMMU group
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=${d#*/iommu_groups/*}; n=${n%%/*}
  printf 'IOMMU Group %s: ' "$n"
  lspci -nns "${d##*/}"
done | sort -V | grep -i nvidia

# Check GPU PCI IDs
lspci -nn | grep -i nvidia

# Check disk status
lsblk /dev/sdb -o NAME,SIZE,TYPE,FSTYPE,PARTLABEL

# Check if vfio-pci is bound to GPU (after VM boot config)
lspci -nnk -d 10de:1c03
lspci -nnk -d 10de:10f1
```

---

## Current Progress

- [x] Verify CPU supports virtualization (AMD-V) ✅
- [x] Verify IOMMU (AMD-Vi) is active ✅
- [x] Identify GPU PCI IDs ✅
- [x] Verify GPU is in isolated IOMMU group ✅
- [x] Format VM disk (`/dev/sdb`) with GPT ✅
- [x] Step 1: Add IOMMU kernel parameters to NixOS ✅
- [x] Step 2: Create NixOS specialisation for VM boot ✅
- [x] Step 3: Configure VFIO to grab GPU in VM specialisation ✅
- [x] Step 4: Create QEMU launch script/service ✅
- [x] Step 5: Create systemd service to auto-start VM ✅
- [x] Step 6: Test VM boot option
- [x] Step 7: Install Windows 11 in the VM
- [x] Step 8: Install GPU drivers in Windows

---

## Implementation Steps

### Step 1: Add IOMMU Kernel Parameters

**File:** `nixos/configuration.nix`

Add `amd_iommu=on` to existing kernel parameters:

```nix
boot.kernelParams = [ 
  "processor.max_cstate=1" 
  "nvidia_drm.modeset=1" 
  "idle=nomwait"
  "amd_iommu=on"  # <-- ADD THIS
];
```

**Note:** This enables IOMMU for both boot options. It doesn't affect normal desktop usage.

---

### Step 2: Create NixOS Specialisation

**File:** `nixos/configuration.nix` (or create a new module)

Add a specialisation that:
- Disables greetd (no GUI starts)
- Loads vfio-pci module early
- Binds GPU to vfio-pci driver

```nix
specialisation.windows-vm.configuration = {
  system.nixos.tags = [ "windows-vm" ];
  
  # Disable display manager - boot to TTY only
  services.greetd.enable = lib.mkForce false;
  
  # Don't load nvidia driver in this mode
  boot.blacklistedKernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  
  # Load VFIO modules early
  boot.initrd.kernelModules = lib.mkForce [ 
    "vfio_pci" 
    "vfio" 
    "vfio_iommu_type1" 
  ];
  
  # Bind GPU to vfio-pci at boot
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:1c03,10de:10f1
    softdep nvidia pre: vfio-pci
  '';
  
  # Auto-start the Windows VM
  systemd.services.windows-vm = {
    description = "Windows 11 VM with GPU Passthrough";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "root";
      ExecStart = "/etc/nixos/scripts/start-windows-vm.sh";
      Restart = "on-failure";
    };
  };
};
```

---

### Step 3: Create QEMU Launch Script

**File:** `nixos/scripts/start-windows-vm.sh` (create this)

```bash
#!/usr/bin/env bash

# Windows 11 VM with GPU Passthrough
# Uses OVMF for UEFI boot

QEMU_CMD="/run/current-system/sw/bin/qemu-system-x86_64"

exec $QEMU_CMD \
  -name "Windows11-GPU" \
  -enable-kvm \
  -machine q35,accel=kvm \
  -cpu host,kvm=on \
  -smp cores=6,threads=1 \
  -m 16G \
  \
  -drive if=pflash,format=raw,readonly=on,file=/run/current-system/sw/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=/var/lib/libvirt/qemu/nvram/windows11_VARS.fd \
  \
  -drive file=/dev/sdb,format=raw,if=virtio,cache=none \
  \
  -device vfio-pci,host=26:00.0,multifunction=on \
  -device vfio-pci,host=26:00.1 \
  \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
  \
  -usb \
  -device usb-host,vendorid=0xXXXX,productid=0xXXXX \
  \
  -vga none \
  -nographic

# Notes:
# - Replace USB vendorid/productid with your keyboard/mouse IDs (use `lsusb`)
# - The OVMF VARS file needs to be created first (copy from OVMF_VARS.fd)
# - Port 3389 is forwarded for RDP access (optional fallback)
```

---

### Step 4: Additional Configuration Needed

#### 4.1 Create OVMF NVRAM copy (run once)

```bash
sudo mkdir -p /var/lib/libvirt/qemu/nvram
sudo cp /run/current-system/sw/share/OVMF/OVMF_VARS.fd /var/lib/libvirt/qemu/nvram/windows11_VARS.fd
sudo chmod 644 /var/lib/libvirt/qemu/nvram/windows11_VARS.fd
```

#### 4.2 Get USB device IDs for keyboard/mouse

```bash
lsusb
# Find your keyboard and mouse, note the ID (e.g., 046d:c52b)
# Format: vendorid=0x046d,productid=0xc52b
```

#### 4.3 Download Windows 11 ISO

Download from Microsoft and place it somewhere accessible. Add to QEMU command for first boot:

```bash
-cdrom /path/to/Win11.iso \
-boot d \
```

---

### Step 5: Rebuild NixOS (USER ACTION REQUIRED)

> ⚠️ **AGENT STOP POINT:** Do NOT run these commands. Tell the user to run them manually.

After making configuration changes, **tell the user:**

"Configuration changes are complete. Please run the following command to rebuild NixOS:"

```bash
cd ~/.dotfiles
sudo nixos-rebuild switch --flake .#nixos
```

**After rebuild succeeds, tell the user:**

"Rebuild complete. Please reboot your system and select the appropriate boot option from GRUB."

This will:
1. Update the main NixOS configuration
2. Create the specialisation
3. Add a new GRUB entry: "NixOS - windows-vm"

---

## Boot Options After Implementation

| GRUB Entry | Description |
|------------|-------------|
| **NixOS** | Normal boot → greetd → Hyprland (desktop) |
| **NixOS - windows-vm** | Headless boot → GPU bound to vfio-pci → Windows VM starts |

---

## Troubleshooting

### GPU not releasing from nvidia driver
- Ensure `nvidia` modules are blacklisted in the specialisation
- Check with: `lspci -nnk -d 10de:1c03` — should show `vfio-pci` as driver

### IOMMU errors
- Verify IOMMU is enabled in BIOS (search for "IOMMU" or "AMD-Vi")
- Check kernel params: `cat /proc/cmdline | grep iommu`

### VM won't start
- Check systemd service: `journalctl -u windows-vm -f`
- Verify OVMF paths exist
- Ensure `/dev/sdb` permissions allow root access

### No display output
- GPU passthrough means output goes to the physical GPU ports
- Connect monitor to the GPU, not motherboard
- Windows needs GPU drivers installed first (use RDP initially if needed)

---

## Files Modified/Created

| File | Purpose |
|------|---------|
| `nixos/configuration.nix` | Add IOMMU params, specialisation |
| `nixos/scripts/start-windows-vm.sh` | QEMU launch script |
| `/var/lib/libvirt/qemu/nvram/windows11_VARS.fd` | UEFI variables storage |

---

## References

- [NixOS Specialisations](https://nixos.wiki/wiki/Specialisation)
- [VFIO GPU Passthrough Guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [Single GPU Passthrough](https://github.com/joeknock90/Single-GPU-Passthrough)
- [QEMU Documentation](https://www.qemu.org/docs/master/)

---

## Session Notes

*Add notes here as you progress through implementation:*

- **2026-01-19:** Initial hardware verification complete. Disk formatted. Plan created.
- **2026-01-19:** Steps 1-5 implemented. Added `amd_iommu=on` kernel param, created specialisation with VFIO config, and created QEMU launch script. Ready for rebuild.
