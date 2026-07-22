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

  # Create mount point directories and swap directory
  systemd.tmpfiles.rules = [
    "d /mnt/myfiles 0755 cavelasco users -"
    "d /swap 0555 root root -"
  ];

  # Swap file (16GB) - for memory overflow and hibernation
  # To resize: adjust size below and run: sudo nixos-rebuild switch
  swapDevices = [
    { device = "/swap/swapfile"; size = 16 * 1024; }
  ];

  boot.kernelParams = [ "nvidia_drm.modeset=1" ];
  boot.kernel.sysctl."kernel.sysrq" = 1;

  # Ensure Xbox Wireless Controller over Bluetooth gets a proper HID driver
  boot.kernelModules = [ "pstore" "snd-seq" "snd-rawmidi" "hid_microsoft" ];

  services.journald.extraConfig = ''
    Storage=persistent
  '';

  # --- Graphics Configuration ---
  # NVIDIA VA-API for hardware video decoding (phones, etc.)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libvdpau-va-gl
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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

  # Use xpadneo driver for Xbox Wireless Controller over Bluetooth
  hardware.xpadneo.enable = true;

  # Enable xone driver for Xbox One / Series accessories
  hardware.xone.enable = true;

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
        command = "${pkgs.tuigreet}/bin/tuigreet --time -cmd Hyprland";
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

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Enable sound with pipewire
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice"; type = "-"; value = "-19"; }
  ];
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

  # services.mysql = {
  #   enable = true;
  #   package = pkgs.mysql84;
  # };
  # To re-enable: uncomment above and run: sudo nixos-rebuild switch

  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_16;
  #   authentication = lib.mkOverride 10 ''
  #     # TYPE  DATABASE  USER  ADDRESS       METHOD
  #     local   all       all                 trust
  #     host    all       all   127.0.0.1/32  trust
  #     host    all       all   ::1/128       trust
  #   '';
  #   ensureUsers = [
  #     {
  #       name = "cavelasco";
  #       ensureClauses.superuser = true;
  #     }
  #   '';
  # };
  # To re-enable: uncomment above and run: sudo nixos-rebuild switch

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.cavelasco = {
    isNormalUser = true;
    description = "cavelasco";
    extraGroups = [ "networkmanager" "wheel" "git" "render" "video" "input" "plugdev" "audio" "adbusers" ];
    shell = pkgs.zsh;
  };

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
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
    pipewire.jack # pw-jack wrapper for JACK apps
    wineasio # ASIO driver for Wine

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

    # Android debugging tools
    android-tools
  ];

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


  # Tailscale VPN - accessible at: https://login.tailscale.com/admin/machines
  services.tailscale.enable = true;
  # Samba for Windows file sharing
  # To enable: uncomment below and run: sudo nixos-rebuild switch
  # services.samba = {
  #   enable = true;
  #   settings = {
  #     global = {
  #       "workgroup" = "WORKGROUP";
  #       "server string" = "nixos";
  #       "netbios name" = "nixos";
  #       "security" = "user";
  #       "hosts allow" = "100.64.0.0/10 127.0.0.1 localhost";
  #       "hosts deny" = "0.0.0.0/0";
  #     };
  #     "myfolder" = {
  #       "path" = "/mnt/myfiles";
  #       "valid users" = "cavelasco";
  #       "public" = "no";
  #       "writeable" = "yes";
  #     };
  #   };
  # };

  # Navidrome media server for streaming music
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
    stdenv.cc.cc
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
  nix.settings = {
    # 134217728 bytes = 128 MB (to fix "download buffer is full" warnings)
    download-buffer-size = 134217728;
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "26.05"; # Ensure this matches your NixOS channel

}
