# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, lib, ... }:
let
  useCursorAppImage = true;
  cursorPackage = if useCursorAppImage then null else pkgs.code-cursor;
in
{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
    ];

  # System-wide environment variables (less common for user-specific settings)
  # Moved TERMINAL to environment.sessionVariables below for user session scope.
  environment.variables = {
    # Example: MY_GLOBAL_VAR = "value";
  };

  environment.sessionVariables = {
    TERMINAL = "kitty";
  };


  # Bootloader.
  boot.loader = {
    grub.enable = true;
    grub.device = "/dev/nvme0n1";
    grub.useOSProber = true;
  };
  boot.supportedFilesystems = [ "ntfs" ];

  # Auto-mount additional storage drives
  fileSystems."/mnt/myfiles" = {
    device = "/dev/disk/by-uuid/6088266F5FF8E75C";
    fsType = "ntfs";
    options = [ "defaults" "uid=1000" "gid=100" "dmask=022" "fmask=133" ];
  };

  # Create mount point directories
  systemd.tmpfiles.rules = [
    "d /mnt/myfiles 0755 cavelasco users -"
  ];

  # Explicitly load NVIDIA kernel modules early during boot.
  # This helps ensure the proprietary driver is ready before the display manager starts.
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.kernelParams = [ "processor.max_cstate=1" "nvidia_drm.modeset=1" "idle=nomwait" "amd_iommu=on" ];
  boot.kernel.sysctl."kernel.sysrq" = 1;
  boot.kernelModules = [ "pstore" "snd-seq" "snd-rawmidi" ];

  services.journald.extraConfig = ''
    Storage=persistent
  '';

  # --- NVIDIA Proprietary Driver Configuration ---
  # Enable the NVIDIA proprietary drivers (this was the main missing switch).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  # --- END NVIDIA Proprietary Driver Configuration ---
  nixpkgs.config.nvidia.acceptLicense = true;


  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "8.0.0.0" ];

  time.timeZone = "America/Bogota";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_CO.UTF-8";
    LC_IDENTIFICATION = "es_CO.UTF-8";
    LC_MEASUREMENT = "es_CO.UTF-8";
    LC_MONETARY = "es_CO.UTF-8";
    LC_NAME = "es_CO.UTF-8";
    LC_NUMERIC = "es_CO.UTF-8";
    LC_PAPER = "es_CO.UTF-8";
    LC_TELEPHONE = "es_CO.UTF-8";
    LC_TIME = "es_CO.UTF-8";
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  services.pulseaudio.enable = false;

  security.sudo = {
    enable = true;
    extraRules = [{
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl suspend";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/reboot";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/poweroff";
          options = [ "NOPASSWD" ];
        }
      ];
      groups = [ "wheel" "git" ];
    }];
    extraConfig = with pkgs; ''
      Defaults:picloud secure_path="${lib.makeBinPath [
        systemd
      ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
    '';
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "cavelasco";
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time -cmd Hyprland";
      };
    };
  };

  services.xserver = {
    # Corrected typo: "nvidea" should be "nvidia".
    # This tells X.org (used by XWayland) to use the NVIDIA driver.
    videoDrivers = [ "nvidia" ];
    enable = true;
    xkb.layout = "us, es";
    xkb.options = "erosign:e, compose:menu, grp:alt_space_toggle";
    xkb.variant = "";
    wacom.enable = true;
  };
  services.libinput = {
    touchpad.naturalScrolling = true;
    enable = true;
    mouse.naturalScrolling = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # JACK configuration for low-latency audio and MIDI
  # Using PipeWire's JACK emulation instead of traditional JACK daemon
  services.jack = {
    jackd.enable = false; # Disable traditional JACK since we use PipeWire's implementation
  };

  # Mumble server for phone microphone streaming
  services.murmur = {
    enable = true;
    bandwidth = 540000;
    bonjour = true;
    password = "phone_mic_password"; # Change this to your preferred password
    autobanTime = 0;
  };

  # PipeWire configuration for virtual audio devices
  services.pipewire.extraConfig.pipewire."97-null-sink" = {
    "context.objects" = [
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "Null-Sink";
          "node.description" = "Null Sink";
          "media.class" = "Audio/Sink";
          "audio.position" = "FL,FR";
        };
      }
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "Null-Source";
          "node.description" = "Null Source";
          "media.class" = "Audio/Source";
          "audio.position" = "FL,FR";
        };
      }
    ];
  };

  services.pipewire.extraConfig.pipewire."98-virtual-mic" = {
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "audio.position" = "FL,FR";
          "node.description" = "Mumble as Microphone";
          "capture.props" = {
            # Mumble's output node name.
            "node.target" = "Mumble";
            "node.passive" = true;
          };
          "playback.props" = {
            "node.name" = "Virtual-Mumble-Microphone";
            "media.class" = "Audio/Source";
          };
        };
      }
    ];
  };
  services.openssh.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.cavelasco = {
    isNormalUser = true;
    description = "cavelasco";
    extraGroups = [ "networkmanager" "wheel" "git" "libvirtd" "render" "video" "input" "plugdev" "audio" "adbusers" "kvm" ];
    shell = pkgs.zsh;
  };

  # Docker configuration
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  users.extraGroups.docker.members = [ "cavelasco" ];

  # Allow unfree packages (necessary for NVIDIA proprietary drivers)
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    neovim
    ranger
    git
    zsh
    gnumake
    ntfs3g
    # Hyprland-specific dependencies for better Wayland compatibility:
    xdg-desktop-portal # Essential for Wayland portals (screen sharing, file dialogs etc.)
    xdg-desktop-portal-hyprland # Hyprland's specific implementation for xdg-desktop-portal
    xdg-desktop-portal-gtk # Recommended for better compatibility with GTK apps (e.g., Firefox, GNOME apps)

    # MIDI support packages for Wine/Proton applications
    alsa-utils # ALSA utilities including aconnect, amidi
    alsa-oss # ALSA OSS compatibility layer  
    timidity # Software synthesizer and MIDI player
    qjackctl # JACK control application
    a2jmidid # ALSA to JACK MIDI bridge
    jack2 # JACK audio connection kit
    wineasio # ASIO driver for Wine

    #virtualization packages
    (
      pkgs.qemu.override {
        gtkSupport = true;
        sdlSupport = true;
        openGLSupport = true;
        spiceSupport = true;
      }
    )
    qemu_full
    virt-manager
    spice-gtk
    spice-protocol
    OVMF
    samba # Required for QEMU's smb= folder sharing

    appimage-run
    curl
    jq

    # Gaming packages
    heroic # Heroic Games Launcher for Epic Games, GOG, and Amazon Prime Games
    wineWowPackages.stable # Wine for running Windows games
    winetricks # Wine configuration utility
    vulkan-tools # Vulkan utilities
    vulkan-loader # Vulkan loader
    gamemode # Optimization daemon for games
    mangohud # Performance overlay for games
    protontricks # Proton configuration utility

    # Additional gaming dependencies
    xorg.xhost # For X11 forwarding in wine
    mesa # OpenGL implementation
    openal # Audio library for games

    # Controller support packages
    linuxConsoleTools # Tools for gamepad support
    jstest-gtk # Joystick testing tool
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      vhostUserPackages = [ pkgs.virtiofsd ];
      runAsRoot = true;
    };
    onBoot = "start";
    onShutdown = "shutdown";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    gamescopeSession.enable = true; # Enable gamescope session for Steam
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.adb.enable = true;

  services.tailscale.enable = true;

  # Open ports in the firewall for Mumble server (phone microphone)
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/mnt/myfiles/music";
      Port = 4533;
      Address = "0.0.0.0";
    };
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [
    64738 # Mumble Murmur server port
    6600
    4533
    8000
    5173
  ];
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };
  networking.firewall.allowedUDPPorts = [
    64738 # Mumble Murmur server port
  ];

  programs.zsh.enable = true;
  programs.hyprland.enable = true;

  # Enable flatpak support
  services.flatpak.enable = true;
  xdg.portal.enable = true;

  # Gaming optimizations
  programs.gamemode.enable = true; # GameMode for performance optimization
  programs.gamescope.enable = true; # Gamescope for micro-compositor

  # Enable hardware support for game controllers
  hardware.steam-hardware.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libdrm
    mesa
    libxkbcommon
    libsecret
    gtk3
    nss
    nspr
    glib
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    fira-code-symbols
  ];

  nix.package = pkgs.nixVersions.stable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "25.05"; # Ensure this matches your NixOS channel

  # ============================================================================
  # Windows VM with GPU Passthrough Specialisation
  # ============================================================================
  # This creates a second GRUB boot option "NixOS - windows-vm" that:
  # - Boots headless (no display manager)
  # - Binds the NVIDIA GPU to vfio-pci driver
  # - Auto-starts a Windows 11 VM with full GPU passthrough
  # ============================================================================
  specialisation.windows-vm.configuration = {
    system.nixos.tags = [ "windows-vm" ];

    # Disable display manager - boot to TTY only
    services.greetd.enable = lib.mkForce false;

    # Allocate hugepages for VM (16GB = 8192 x 2MB pages, +256 for overhead)
    boot.kernel.sysctl."vm.nr_hugepages" = 8448;

    # Blacklist nvidia drivers - prevents loading even if in initrd
    boot.blacklistedKernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "nouveau" ];

    # Bind GPU and USB controller to vfio-pci via kernel parameters (earliest possible binding)
    # GPU: 10de:1c03,10de:10f1 | USB controller (for Focusrite): 1022:145c
    # CPU isolation: CPUs 4-11 reserved for VM, no host scheduling/interrupts
    boot.kernelParams = [
      "vfio-pci.ids=10de:1c03,10de:10f1,1022:145c"
      "isolcpus=4-11"
      "nohz_full=4-11"
      "rcu_nocbs=4-11"
    ];

    # Load VFIO modules early in initrd
    boot.initrd.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];

    # Bind GPU and USB controller to vfio-pci at module load time (backup)
    boot.extraModprobeConfig = ''
      options vfio-pci ids=10de:1c03,10de:10f1,1022:145c
      softdep nvidia pre: vfio-pci
      softdep nouveau pre: vfio-pci
      softdep xhci_hcd pre: vfio-pci
    '';

    # Open VNC port for remote access during Windows installation
    networking.firewall.allowedTCPPorts = [ 5900 ];

    # Don't mount myfiles - it will be passed through to the VM
    fileSystems."/mnt/myfiles".enable = false;

    # Auto-start the Windows VM
    systemd.services.windows-vm = {
      description = "Windows 11 VM with GPU Passthrough";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "/home/cavelasco/.dotfiles/nixos/scripts/start-windows-vm.sh";
        Restart = "on-failure";
      };
    };
  };
}
