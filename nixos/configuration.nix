# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;
  networking.hostName = "nixos"; # Define your hostname. networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  hardware.pulseaudio.enable = false;

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


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cavelasco = {
    isNormalUser = true;
    description = "cavelasco";
    extraGroups = [ "networkmanager" "wheel"];
    packages = with pkgs; [
      brave
    ];
    shell = pkgs.zsh;
  };
  #docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  users.extraGroups.docker.members = [ "cavelasco" ];

  # Allow unfree packages
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
  system.stateVersion = "24.11"; 

}
