# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, lib, ... }:

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

  # Environment variables specific to user sessions (e.g., graphical sessions like Hyprland)
  environment.sessionVariables = {
    TERMINAL = "kitty"; # Moved here for clarity as it's usually a session-specific variable.
    # For hardware video acceleration (e.g., in browsers like Firefox or mpv)
    NIXOS_OZONE_WL = "1"; # Enables Ozone Wayland backend for Chromium-based apps
    LIBVA_DRIVER_NAME = "nvidia"; # Specifies NVIDIA as the VA-API driver for hardware decoding
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Generally not needed with newer drivers/Wayland,
                                            # but uncomment if you face issues with specific apps.
    # GBM_BACKEND = "nvidia-drm"; # May be needed for some specific setups or older drivers,
                                  # but hardware.nvidia.modesetting.enable = true; should handle this.
  };

  # Bootloader.
  boot.loader = {
    grub.enable = true;
    grub.device = "/dev/nvme0n1";
    grub.useOSProber = true;
  };
  boot.supportedFilesystems = ["ntfs"];

  # Explicitly load NVIDIA kernel modules early during boot.
  # This helps ensure the proprietary driver is ready before the display manager starts.
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];

  # Blacklist the nouveau driver to prevent it from loading at all.
  # This ensures there are no conflicts with the proprietary NVIDIA driver.
  boot.kernelParams = [
    "modprobe.blacklist=nouveau"
    "nvidia.NVreg_UsePageAttributeTable=1" # Keep this if it was explicitly added by you
  ];

  # --- NVIDIA Proprietary Driver Configuration ---
  # Enable the NVIDIA proprietary drivers (this was the main missing switch).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    # Enable kernel mode setting (KMS) for the NVIDIA driver.
    # This is CRUCIAL for Wayland compositors like Hyprland.
    modesetting.enable = true;
    powerManagement.enable = false; # User preference
    powerManagement.finegrained = false; # User preference
    open = false; # Use the traditional proprietary driver, not the open-source kernel modules.
    nvidiaSettings = true; # Enable the NVIDIA Settings utility.
    package = config.boot.kernelPackages.nvidiaPackages.production; # Specify the production driver package.
  };
  # --- END NVIDIA Proprietary Driver Configuration ---


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
      Defaults:picloud secure_path="${lib.makeBinPath [
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
    videoDrivers = ["nvidia"];
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
  };
  services.openssh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cavelasco = {
    isNormalUser = true;
    description = "cavelasco";
    extraGroups = [ "networkmanager" "wheel" "git" ];
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
    xdg-desktop-portal         # Essential for Wayland portals (screen sharing, file dialogs etc.)
    xdg-desktop-portal-hyprland # Hyprland's specific implementation for xdg-desktop-portal
    xdg-desktop-portal-gtk     # Recommended for better compatibility with GTK apps (e.g., Firefox, GNOME apps)
  ];

  programs.zsh.enable = true;
  programs.hyprland.enable = true;

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
  ];

  nix.package = pkgs.nixVersions.stable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "24.11"; # Ensure this matches your NixOS channel
}
