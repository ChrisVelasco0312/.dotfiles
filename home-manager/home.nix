{ config, pkgs, inputs, lib, vimUtils, ... }:

{

  nixpkgs = {
    overlays = [
      (final: prev: {
        vimPlugins = prev.vimPlugins // {
          own-lualine-nvim = prev.vimUtils.buildVimPlugin {
            name = "lualine";
            src = inputs.plugin-lualine;
          };
        };
      })
    ];
  };

  imports = [
    ./programs/tmux/tmux.nix
    ./programs/rofi
    ./programs/neovim
    ./programs/firefox/firefox.nix
  ];

  home = {
    username = "cavelasco";
    homeDirectory = "/home/cavelasco";
    stateVersion = "24.11";
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.packages = with pkgs; [
    # LANGUAGES
    racket
    lua-language-server
    markdown-oxide
    #virtualization
    virt-manager #GUI for virtual machines
    qemu # Core QEMU tools
    libvirt # Libvirt tools
    virt-viewer # remote viewing
    spice-gtk # Spice support
    dnsmasq # Virtual network bridges
    #java
    jdt-language-server
    jdk23
    lombok
    maven
    # NODE
    nodejs_22
    nodejs_22.pkgs.pnpm
    nodejs_22.pkgs.yarn
    nodejs_22.pkgs.typescript
    nodejs_22.pkgs.prettier
    live-server
    bun
    # TOOLS
    lazygit
    zoom-us
    prettierd
    evtest
    unzip
    bat
    fzf
    ripgrep
    jq
    tree
    eza
    gcc
    pandoc
    fish
    fd
    htop
    pavucontrol
    brightnessctl # change brightness
    #------
    (nerdfonts.override {
      fonts = [ "JetBrainsMono" "Inconsolata" ];
    })
    hunspell
    hunspellDicts.es_CO
    hunspellDicts.es-es
    # APPS
    anki # spaced repetition cards
    ardour # audio editing
    kdenlive # video editing
    zotero # research management
    stremio # movies
    xournalpp # handwritten note taking
    okular # pdf viewer
    feh #image viewer
    gparted # Partition editor
    vlc # Cross-platform media player
    dolphin # file manager
    breeze-icons # icons
    spotify # music stream
    #--OBSIDIAN--
    obsidian
    hyprshot # screenshot
    kitty
    kitty-themes
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.shellAliases = {
    l = "eza";
    ls = "eza";
    cat = "bat";
  };

  #ZSH
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "python" "docker" "fzf" ];
      theme = "intheloop";
    };
    initExtra = ''
      function ranger-cd {
        local tmp="$(mktemp -t "ranger_cd.XXXXXXXXXX")"
        ranger --choosedir="$tmp" "$@"
        if [ -f "$tmp" ]; then
          local dir="$(cat "$tmp")"
          rm -f "$tmp"
          [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
        fi
      }
      alias ranger="ranger-cd"
    '';
  };

  programs.git = {
    enable = true;
    extraConfig = {
      credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";
    };

  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  ## CONFIGS
  xdg.configFile."waybar/config".source = ../dots/waybar/config;
  xdg.configFile."waybar/style.css".source = ../dots/waybar/style.css;
  # -- TERMINALS --
  xdg.configFile."kitty/kitty.conf".source = ../dots/kitty/kitty.conf;
  #-----------------
  xdg.configFile."hypr/hyprland.conf".force = true;
  xdg.configFile."hypr/hyprland.conf".source = ../dots/hypr/hyprland.conf;
  xdg.configFile."environment.d/cursor.conf".source = ../dots/hypr/cursor.conf;
  xdg.configFile."hypr/start.sh".source = ../dots/hypr/start.sh;
  xdg.configFile."hypr/background.jpg".source = ../dots/hypr/background.jpg;
  xdg.configFile."nvim/ftplugin/java.lua".source = ./programs/neovim/nvim-lua/ftplugin/java.lua;

  #awesome is the wm for emergency, because it is ugly
  # xdg.configFile.awesome.source = ../dots/awesome;

  # VIRTUALIZATION
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
}
