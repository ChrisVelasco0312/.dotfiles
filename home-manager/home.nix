{ config, pkgs, inputs, lib, vimUtils, ... }:

let
  cursorTheme = {
    name = "capitaine-cursors";
    size = 24;
    package = pkgs.capitaine-cursors;
  };
  githubKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519_personal";
  workKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519_work";

  # Parse .env file from root
  env = let
    content = builtins.readFile "${config.home.homeDirectory}/.dotfiles/.env";
    lines = lib.splitString "\n" content;
    parseLine = line:
      if (builtins.match "[A-Za-z_][A-Za-z0-9_]*=.*" line) != null then
        let
          parts = lib.splitString "=" line;
          key = builtins.head parts;
          value = lib.concatStringsSep "=" (builtins.tail parts);
        in { name = key; value = value; }
      else null;
  in
    builtins.listToAttrs (builtins.filter (x: x != null) (map parseLine lines));

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

        bitwig-studio-patched = prev.bitwig-studio.overrideAttrs (oldAttrs:
          let
            customJar = builtins.path {
              path = /home/cavelasco/.dotfiles/temp/bitwig.jar;
              name = "bitwig.jar";
            };
          in {
          postInstall = (oldAttrs.postInstall or "") + ''
            customJar=${customJar}
            if [ -f "$out/opt/bitwig-studio/bin/bitwig.jar" ]; then
              cp "$customJar" "$out/opt/bitwig-studio/bin/bitwig.jar"
            elif [ -f "$out/libexec/bin/bitwig.jar" ]; then
              cp "$customJar" "$out/libexec/bin/bitwig.jar"
            elif [ -f "$out/libexec/bitwig-studio/bin/bitwig.jar" ]; then
              cp "$customJar" "$out/libexec/bitwig-studio/bin/bitwig.jar"
            else
              echo "bitwig.jar target path not found" >&2
              exit 1
            fi
          '';
        });

        })
    ];
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
    stateVersion = "25.05";

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
      XDG_DATA_DIRS = "$XDG_DATA_DIRS:$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share";
      JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
      # Flutter
      ANDROID_HOME = "$HOME/Android/Sdk";
      CHROME_EXECUTABLE = "brave";
      LASTFM_APIKEY = env.LASTFM_APIKEY or "";
      LASTFM_SECRET = env.LASTFM_SECRET or "";
      LASTFM_USER = env.LASTFM_USER or "";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.opencode/bin"
    ];

    shellAliases = {
      l = "eza";
      ls = "eza";
      cat = "bat";
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-cursor-theme-name = cursorTheme.name;
      gtk-cursor-theme-size = cursorTheme.size;
      gtk-icon-theme-name = "Papirus";
    };
    gtk4.extraConfig = {
      gtk-cursor-theme-name = cursorTheme.name;
      gtk-cursor-theme-size = cursorTheme.size;
      gtk-icon-theme-name = "Papirus";
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
    bitwig-studio-patched
    # === BROWSERS ===
    brave
    google-chrome

    # === EDITORS & IDE ===
    vscode
    github-copilot-cli
    claude-code

    # === CLOUD & DEPLOYMENT ===
    awscli2
    google-cloud-sdk

    # === LANGUAGES & RUNTIMES ===
    devbox
    racket
    lua-language-server
    markdown-oxide

    # === VIRTUALIZATION & CONTAINERS ===
    virt-manager
    qemu
    libvirt
    virt-viewer
    spice-gtk
    dnsmasq
    docker-compose

    # === PYTHON ===
    (python3.withPackages (ps: with ps; [
      pip
      requests
      tidalapi
      harlequin-postgres
    ]))
    pipx
    ruff
    mypy
    black
    isort
    uv

    # === JAVA & JVM ===
    jdk21
    maven
    jdt-language-server
    lombok
    tmc-cli

    # === FLUTTER & ANDROID ===
    flutter
    android-studio
    android-tools
    libusb1
    usbutils

    # === NODE.JS & BUN ===
    nodejs_24
    pnpm
    yarn
    typescript
    prettier
    live-server
    bun

    # === BUILD TOOLS ===
    gcc
    gnumake
    cmake
    (lib.hiPrio clang)
    lldb
    gdb

    # === DEVELOPER TOOLS ===
    direnv
    lazygit
    prettierd
    bat
    fzf
    ripgrep
    jq
    tree
    eza
    fd
    htop
    pandoc
    fish

    # === SYSTEM UTILITIES ===
    unzip
    evtest
    pavucontrol
    brightnessctl
    mission-center
    libreoffice-fresh
    weylus
    hunspell
    hunspellDicts.es_CO
    hunspellDicts.es-es

    # === FONTS ===
    nerd-fonts.jetbrains-mono
    nerd-fonts.inconsolata

    # === THEMES & ICONS ===
    papirus-icon-theme
    adwaita-icon-theme
    kdePackages.breeze-icons
    capitaine-cursors

    # === DATABASE TOOLS ===
    mongodb-compass
    mongodb-cli
    mongodb-atlas-cli
    dbeaver-bin
    postman
    harlequin

    # === PRODUCTIVITY ===
    zotero
    obsidian
    xournalpp
    epr
    kdePackages.okular

    # === IMAGE VIEWERS & FILE MANAGEMENT ===
    feh
    gparted
    nautilus

    # === VIDEO/AUDIO TOOLS ===
    kdePackages.kdenlive
    movit
    ffmpeg
    ffmpegthumbnailer
    webp-pixbuf-loader
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav

    # === MEDIA PLAYERS & STREAMING ===
    vlc
    feishin
    streamrip
    tidal-hifi
    mpd
    mpc
    ncmpcpp
    spek
    playerctl
    alsa-scarlett-gui
    rescrobbled

    # === SCREENSHOTS & RECORDING ===
    hyprshot
    satty
    grim
    slurp
    obs-studio

    # === TERMINALS ===
    ghostty
    kitty
    kitty-themes

    # === COMMUNICATION ===
    zoom-us
    mumble

    # === DOWNLOADERS & DEVICE STREAMING ===
    qbittorrent
    scrcpy
    pulseaudio

    # === FLATPAK ===
    flatpak
  ];

  # ---- GITHUB SSH -------#
  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;
  services.ssh-agent.enable = true;
  programs.ssh.matchBlocks = {
    "*" = {
      extraOptions = {
        addKeysToAgent = "yes";
      };
    };
    "github.com" = {
      user = "git";
      hostname = "github.com";
      identityFile = githubKeyPath;
      identitiesOnly = true;
    };
    "github-work" = {
      user = "git";
      hostname = "github.com";
      identityFile = workKeyPath;
      identitiesOnly = true;
    };
  };

  systemd.user.services = {
    add-github-ssh-key = {
      Unit = {
        Description = "Add GitHub SSH key to ssh-agent";
        After = [ "ssh-agent.service" ];
      };
      Service = {
        Type = "oneshot";
        Environment = [ "SSH_AUTH_SOCK=%t/ssh-agent" ];
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
        Environment = [ "SSH_AUTH_SOCK=%t/ssh-agent" ];
        ExecStart = "${pkgs.openssh}/bin/ssh-add ${workKeyPath}"; # Uses workKeyPath
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    awww-hook = {
      Unit = {
        Description = "Run awww to set wallpaper";
        Requires = [ "awww-daemon.service" ];
        After = [ "awww-daemon.service" ];
        PartOf = "awww-daemon.service";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/awww-daemon";
      };

      Install = {
        WantedBy = [ "awww-daemon.service" ];
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
    initContent = ''
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
      alias update:opencode="systemctl --user start install-opencode-cli"
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      credential.helper = "${
        pkgs.git.override { withLibsecret = true; }
      }/bin/git-credential-libsecret";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
  };

  ## CONFIG FILES
  xdg.configFile."waybar/config".source = ../dots/waybar/config;
  xdg.configFile."waybar/style.css".source = ../dots/waybar/style.css;
  xdg.configFile."kitty/kitty.conf".source = ../dots/kitty/kitty.conf;
  xdg.configFile."hypr/hyprland.conf".force = true;
  xdg.configFile."hypr/hyprland.conf".source = ../dots/hypr/hyprland.conf;
  xdg.configFile."hypr/start.sh".source = ../dots/hypr/start.sh;
  xdg.configFile."hypr/background.jpg".source = ../dots/hypr/background.jpg;
  xdg.configFile."hypr/rofi-mpd.sh".source = ../dots/hypr/rofi-mpd.sh;
  xdg.configFile."hypr/rofi-tidal.py".source = ../dots/hypr/rofi-tidal.py;
  xdg.configFile."hypr/rofi-music.sh".source = ../dots/hypr/rofi-music.sh;
  xdg.configFile."nvim/ftplugin/java.lua".source = ./programs/neovim/nvim-lua/ftplugin/java.lua;
  xdg.configFile."ncmpcpp/config".source = ../dots/ncmpcpp/config;
  xdg.configFile."ncmpcpp/bindings".source = ../dots/ncmpcpp/bindings;
  xdg.configFile."ghostty/config".source = ../dots/ghostty/config;

  # Rescrobbled configuration with secrets from .env
  xdg.configFile."rescrobbled/config.toml".text = ''
    lastfm-key = "${env.LASTFM_APIKEY or ""}"
    lastfm-secret = "${env.LASTFM_SECRET or ""}"
    player-whitelist = ["mopidy", "tidal-hifi", "Feishin", "mpd", "spotify", "mpv"]
  '';

  # Optional fallback WM config
  # xdg.configFile.awesome.source = ../dots/awesome;

  services.mpd = {
    enable = false; # Disabled in favor of Mopidy
    musicDirectory = "/mnt/myfiles/music";
    network.listenAddress = "any";
    network.port = 6600;
    extraConfig = ''
      audio_output {
        type "pulse"
        name "MPD PulseAudio"
      }
      filesystem_charset "UTF-8"
      id3v1_encoding "UTF-8"
      playlist_plugin {
        name "m3u"
        enabled "yes"
      }
      auto_update "yes"
      auto_update_depth "3"
      audio_output {
        type        "httpd"
        name        "Phone Stream"
        encoder     "vorbis"          # Best balance of quality and bandwidth
        port        "8000"            # Separate port for the audio data
        bind_to_address "0.0.0.0"
        bitrate     "128"
        format      "44100:16:2"
        always_on   "yes"             # Keeps stream alive even when paused
      }
    '';
  };

  services.mopidy = {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-mpd
      mopidy-tidal
      mopidy-local
      mopidy-mpris # Required for rescrobbled/MPRIS support
    ];
    settings = {
      core = {
        restore_state = true;
      };
      mpd = {
        hostname = "0.0.0.0";
        port = 6600;
      };
      audio = {
        output = "autoaudiosink";
      };
      tidal = {
        enabled = false;
        # login details will be in ~/.config/mopidy/mopidy.conf
      };
      file = {
        enabled = true;
        media_dirs = [ 
          "/mnt/myfiles/music|Music" 
        ];
      };
      mpris = {
        enabled = true;
      };
    };
  };

  # VIRTUALIZATION
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  systemd.user.services.install-opencode-cli = {
    Unit = {
      Description = "Install or update OpenCode CLI via official script";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "install-opencode-cli" ''
                set -euo pipefail

                # Determine installation directory (default to ~/.local/bin, like your PATH setup)
                INSTALL_DIR="''${XDG_BIN_DIR:-$HOME/.local/bin}"
                mkdir -p "''${INSTALL_DIR}"

                echo "Installing OpenCode CLI to ''${INSTALL_DIR}..."

                # Use official installer script, targeting the chosen directory
                XDG_BIN_DIR="''${INSTALL_DIR}" ${pkgs.curl}/bin/curl -fsSL "https://opencode.ai/install" | ${pkgs.bash}/bin/bash

                echo "OpenCode CLI installation completed."
      '';
    };
    Install = {
      # Not enabled by default - run manually with:
      # systemctl --user start install-opencode-cli
    };
  };

}
