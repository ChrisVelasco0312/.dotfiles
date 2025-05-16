{ config, pkgs, inputs, lib, vimUtils, ... }:

let
  cursorTheme = {
    name = "capitaine-cursors";
    size = 24;
    package = pkgs.capitaine-cursors;
  };
  githubKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519_personal";
  workKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519_work";
in
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


  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
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

    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      name = cursorTheme.name;
      size = cursorTheme.size;
      package = cursorTheme.package;
    };

    sessionVariables = {
      EDITOR = "nvim";
      XCURSOR_THEME = cursorTheme.name;
      XCURSOR_SIZE = toString cursorTheme.size;
    };

    shellAliases = {
      l = "eza";
      ls = "eza";
      cat = "bat";
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-cursor-theme-name = cursorTheme.name;
      gtk-cursor-theme-size = cursorTheme.size;
    };
    gtk4.extraConfig = {
      gtk-cursor-theme-name = cursorTheme.name;
      gtk-cursor-theme-size = cursorTheme.size;
    };
  };

  wayland.windowManager.hyprland.settings = {
    env = [
      "XCURSOR_THEME,${cursorTheme.name}"
      "XCURSOR_SIZE,${toString cursorTheme.size}"
    ];
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # editors
    vscode
    # code-cursor
    # LANGUAGES
    devbox
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
    docker-compose
    # java
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
    brightnessctl
    mission-center
    # Fonts & Cursors
    (nerdfonts.override {
      fonts = [ "JetBrainsMono" "Inconsolata" ];
    })
    capitaine-cursors
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
    zotero
    stremio
    qbittorrent
    xournalpp
    okular
    feh
    gparted
    vlc
    nautilus
    breeze-icons
    spotify
    obs-studio
    (pkgs.writeShellScriptBin "obsidian" ''
      exec ${pkgs.obsidian}/bin/obsidian --disable-gpu "$@"
    '')
    kitty
    kitty-themes
  ];
  
  # ---- GITHUB SSH -------#
  programs.ssh.enable = true;
  services.ssh-agent.enable = true;
  programs.ssh.matchBlocks = {
    "github.com" = {
      user = "git";
      hostname = "github.com";
      identityFile = githubKeyPath;
    };
    "github-work" = {
      user = "git";
      hostname = "github.com";
      identityFile = workKeyPath;
      identitiesOnly = true;
    };
  };
  programs.ssh.addKeysToAgent = "yes";
  systemd.user.services = {
    add-github-ssh-key = {
      Unit = {
        Description = "Add GitHub SSH key to ssh-agent";
        After = [ "ssh-agent.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.openssh}/bin/ssh-add ${githubKeyPath}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    add-work-ssh-key = {
      Unit = {
        Description = "Add Work (GitHub Alias) SSH key to ssh-agent";
        After = [ "ssh-agent.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.openssh}/bin/ssh-add ${workKeyPath}"; # Uses workKeyPath
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };



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

  ## CONFIG FILES
  xdg.configFile."waybar/config".source = ../dots/waybar/config;
  xdg.configFile."waybar/style.css".source = ../dots/waybar/style.css;
  xdg.configFile."kitty/kitty.conf".source = ../dots/kitty/kitty.conf;
  xdg.configFile."hypr/hyprland.conf".force = true;
  xdg.configFile."hypr/hyprland.conf".source = ../dots/hypr/hyprland.conf;
  xdg.configFile."hypr/start.sh".source = ../dots/hypr/start.sh;
  xdg.configFile."hypr/background.jpg".source = ../dots/hypr/background.jpg;
  xdg.configFile."nvim/ftplugin/java.lua".source = ./programs/neovim/nvim-lua/ftplugin/java.lua;

  # Optional fallback WM config
  # xdg.configFile.awesome.source = ../dots/awesome;

  # VIRTUALIZATION
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
}
