# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
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

  # Environment variables specific to user sessions (e.g., graphical sessions like Hyprland)
  environment.sessionVariables = {
    TERMINAL = "kitty"; 
    LIBVA_DRIVER_NAME = "iHD";         # Use "iHD" for Intel Media Driver
    VDPAU_DRIVER = "va_gl";            # Needed for some VDPAU backends
    NIXOS_OZONE_WL = "1";              # Improves support for Chromium apps under Wayland
  };

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables =  true;


  # Bootloader.
  boot.loader = {
    grub.enable = true;
    grub.device = "nodev";
    grub.useOSProber = true;
    grub.efiSupport = true;
  };
  boot.supportedFilesystems = [ "ntfs" ];

  # Explicitly load NVIDIA kernel modules early during boot.
  # This helps ensure the proprietary driver is ready before the display manager starts.
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.kernelParams = ["processor.max_cstate=1" "nvidia_drm.modeset=1" "idle=nomwait"];
  boot.kernel.sysctl."kernel.sysrq" = 1;
  boot.kernelModules = [ "pstore" ];

  services.journald.extraConfig = ''
    Storage=persistent
  '';

  # --- NVIDIA Proprietary Driver Configuration ---
  # Enable the NVIDIA proprietary drivers (this was the main missing switch).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver  # For newer Intel iGPUs
      vaapiIntel          # Legacy support, just in case
      vaapiVdpau
      libvdpau-va-gl
    ];
  };


  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true; # Enable networking

  # Set your time zone.
  time.timeZone = "America/Bogota";

  # Select internationalisation properties.
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

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  hardware.pulseaudio.enable = false; # Disabled in favor of PipeWire

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
      Defaults secure_path="${lib.makeBinPath [
        systemd
      ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
    '';
  };

  services.greetd = {
    enable = true;
    vt = 3;
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
    videoDrivers = [ "intel" ];
    enable = true;
    xkb.layout = "us, latam";
    xkb.options = "grp:win_space_toggle";
    xkb.variant = "";
    wacom.enable = true;
  }; services.libinput = { touchpad.naturalScrolling = true;
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
  };
  services.openssh.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.cavelasco = {
    isNormalUser = true;
    description = "cavelasco";
    extraGroups = [ "networkmanager" "wheel" "git" "libvirtd" "render" "video"];
    # packages = with pkgs; [
    #   brave
    # ];
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

    appimage-run
    curl
    jq
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

  
  system.activationScripts.createApplicationsDir = {
    text = ''
      mkdir -p /home/cavelasco/Applications
      chown cavelasco:users /home/cavelasco/Applications
      chmod 755 /home/cavelasco/Applications
    '';
    deps = [ ];
  };

  system.activationScripts.installCursor = {
    text = ''
          # Create desktop entry for AppImage version
          DESKTOP_FILE="/home/cavelasco/.local/share/applications/cursor.desktop"
          mkdir -p "$(dirname "$DESKTOP_FILE")"
    
          # Ensure Applications directory exists
          mkdir -p "/home/cavelasco/Applications"
          chown cavelasco:users "/home/cavelasco/Applications"
          chmod 755 "/home/cavelasco/Applications"
    
          # Fetch the latest Cursor AppImage
          echo "Fetching latest Cursor AppImage..."
          CURSOR_INFO=$(${pkgs.curl}/bin/curl -sSfL "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=latest")
          DOWNLOAD_URL=$(${pkgs.jq}/bin/jq -r '.downloadUrl' <<< "$CURSOR_INFO")
    
          if [ -n "$DOWNLOAD_URL" ] && [ "$DOWNLOAD_URL" != "null" ]; then
            echo "Downloading from $DOWNLOAD_URL..."
            ${pkgs.curl}/bin/curl -sSfL "$DOWNLOAD_URL" -o "/home/cavelasco/Applications/Cursor.AppImage.tmp"
            if [ $? -eq 0 ]; then
              chmod +x "/home/cavelasco/Applications/Cursor.AppImage.tmp"
              mv "/home/cavelasco/Applications/Cursor.AppImage.tmp" "/home/cavelasco/Applications/Cursor.AppImage"
              chown cavelasco:users "/home/cavelasco/Applications/Cursor.AppImage"
              echo "Cursor AppImage downloaded successfully."
            else
              echo "ERROR: Failed to download Cursor AppImage."
              rm -f "/home/cavelasco/Applications/Cursor.AppImage.tmp"
            fi
          else
            echo "WARNING: Could not retrieve Cursor download URL. Skipping download."
          fi
    
          # Create desktop entry for the AppImage
          cat > "$DESKTOP_FILE" << EOF
      [Desktop Entry]
      Name=Cursor
      Exec=${pkgs.appimage-run}/bin/appimage-run /home/cavelasco/Applications/Cursor.AppImage
      Icon=code
      Type=Application
      Categories=Development;IDE;
      Comment=AI-first code editor
      Terminal=false
      EOF
    '';
    deps = [ ];
  };


  programs.zsh.enable = true;
  programs.hyprland.enable = true;

  programs.nix-ld.enable =  true;
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
  ];
  
  nix.settings = {
    download-buffer-size =  524288000;
  } ;
  nix.package = pkgs.nix;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "25.05"; # Ensure this matches your NixOS channel
}
