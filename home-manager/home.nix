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

        # Custom cursor-cli package that automatically fetches the latest version
        cursor-cli = prev.stdenv.mkDerivation rec {
          pname = "cursor-cli";
          version = "latest";

          # No source needed - we create wrapper scripts
          src = null;
          dontUnpack = true;

          nativeBuildInputs = with prev; [ makeWrapper ];

          installPhase = ''
                        mkdir -p $out/bin
            
                        # Create the installer script
                        cat > $out/bin/cursor-cli-install << 'EOF'
            ${builtins.readFile ./scripts/cursor-cli-install.sh}
            EOF
            
                        # Create the main wrapper script
                        cat > $out/bin/cursor-agent << 'EOF'
            ${builtins.readFile ./scripts/cursor-agent.sh}
            EOF
            
                        # Make scripts executable
                        chmod +x $out/bin/cursor-cli-install
                        chmod +x $out/bin/cursor-agent
            
                        # Wrap the scripts to ensure proper PATH and dependencies
                        wrapProgram $out/bin/cursor-cli-install \
                          --prefix PATH : ${prev.lib.makeBinPath [ prev.curl prev.bash ]}
            
                        wrapProgram $out/bin/cursor-agent \
                          --prefix PATH : ${prev.lib.makeBinPath [ prev.curl prev.bash ]} \
                          --prefix PATH : $out/bin
            
                        # Create symlink for convenience
                        ln -s $out/bin/cursor-agent $out/bin/cursor-cli
          '';

          meta = with prev.lib; {
            description = "Cursor CLI - AI-powered code editor command line interface";
            homepage = "https://cursor.com/cli";
            license = licenses.unfree;
            platforms = platforms.unix;
            maintainers = [ "cavelasco" ];
          };
        };
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
    brave
    google-chrome
    # editors
    vscode
    cursor-cli
    awscli2
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
    docker-compose
    #python
    (python312.withPackages (ps: with ps; [
      pip
      requests
      tidalapi
    ]))
    pipx
    ruff
    mypy
    black
    isort
    # java
    tmc-cli
    jdt-language-server
    jdk21
    lombok
    maven
    # Flutter
    flutter
    android-studio
    # NODE
    nodejs_24
    nodejs_24.pkgs.pnpm
    nodejs_24.pkgs.yarn
    nodejs_24.pkgs.typescript
    nodejs_24.pkgs.prettier
    live-server
    bun
    # TOOLS
    direnv
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
    gnumake
    cmake
    (lib.hiPrio clang)
    lldb
    gdb
    pandoc
    fish
    fd
    htop
    pavucontrol
    brightnessctl
    mission-center
    capitaine-cursors
    hunspell
    hunspellDicts.es_CO
    hunspellDicts.es-es
    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.inconsolata
    # APPS
    mongodb-compass # MongoDB GUI
    mongodb-cli
    mongodb-atlas-cli
    dbeaver-bin # SQL client
    postman # API testing
    zotero # research management
    xournalpp # handwritten note taking
    kdePackages.okular
    feh #image viewer
    gparted # Partition editor
    vlc # Cross-platform media player
    mpv # Media player for Tidal streaming
    kdePackages.breeze-icons # icons
    # GNOME/GTK theming and thumbnails
    papirus-icon-theme # Modern icon theme
    adwaita-icon-theme # Default GNOME icons (fallback)
    gst_all_1.gstreamer # Video thumbnail generation
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav # FFmpeg integration for GStreamer
    ffmpegthumbnailer # Video thumbnail generator
    webp-pixbuf-loader # WebP image support
    feishin
    streamrip
    tidal-hifi
    flatpak
    mpd
    mpc
    ncmpcpp
    spek
    rescrobbled # Added explicitly to ensure binary availability
    playerctl # For media playback control
    alsa-scarlett-gui
    #--OBSIDIAN--
    obsidian
    hyprshot # screenshot
    zotero
    qbittorrent
    xournalpp
    feh
    gparted
    vlc
    nautilus
    obs-studio
    obsidian
    hyprshot
    ghostty
    kitty
    kitty-themes
    ffmpeg
    # Phone microphone streaming
    mumble
    pulseaudio
    scrcpy
    # Android development and device control
    android-tools  # Includes ADB and fastboot
    libusb1  # USB library
    usbutils  # USB utilities for device detection
    # Cloud
    google-cloud-sdk
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
    swww-hook = {
      Unit = {
        Description = "Run swww to set wallpaper";
        Requires = [ "swww-daemon.service" ];
        After = [ "swww-daemon.service" ];
        PartOf = "swww-daemon.service";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/swww-daemon";
      };

      Install = {
        WantedBy = [ "swww-daemon.service" ];
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

  # CURSOR APPIMAGE INSTALLATION - using systemd service for better network access
  home.activation.createCursorDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create Applications directory
    mkdir -p "$HOME/Applications"
    
    # Create desktop entry directory
    mkdir -p "$HOME/.local/share/applications"
  '';

  systemd.user.services.install-cursor = {
    Unit = {
      Description = "Download and install Cursor AppImage";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "install-cursor" ''
                # Ensure directories exist
                mkdir -p "$HOME/Applications"
                mkdir -p "$HOME/.local/share/applications"
        
                echo "Fetching latest Cursor AppImage..."
        
                # Add retry logic with timeout
                for i in {1..3}; do
                  echo "Attempt $i/3..."
                  CURSOR_INFO=$(${pkgs.curl}/bin/curl --connect-timeout 30 --max-time 120 -sSfL "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=latest" 2>/dev/null)
                  if [ $? -eq 0 ] && [ -n "$CURSOR_INFO" ]; then
                    break
                  fi
                  echo "Attempt $i failed, waiting 10 seconds..."
                  sleep 10
                done
        
                if [ -z "$CURSOR_INFO" ]; then
                  echo "ERROR: Failed to fetch Cursor download information after 3 attempts."
                  exit 1
                fi
        
                DOWNLOAD_URL=$(${pkgs.jq}/bin/jq -r '.downloadUrl' <<< "$CURSOR_INFO")
        
                if [ -n "$DOWNLOAD_URL" ] && [ "$DOWNLOAD_URL" != "null" ]; then
                  echo "Downloading from $DOWNLOAD_URL..."
          
                  # Download with retry logic
                  for i in {1..3}; do
                    echo "Download attempt $i/3..."
                    if ${pkgs.curl}/bin/curl --connect-timeout 30 --max-time 300 -sSfL "$DOWNLOAD_URL" -o "$HOME/Applications/Cursor.AppImage.tmp"; then
                      chmod +x "$HOME/Applications/Cursor.AppImage.tmp"
                      mv "$HOME/Applications/Cursor.AppImage.tmp" "$HOME/Applications/Cursor.AppImage"
                      echo "Cursor AppImage downloaded successfully."
                      break
                    else
                      echo "Download attempt $i failed, waiting 10 seconds..."
                      rm -f "$HOME/Applications/Cursor.AppImage.tmp"
                      if [ $i -eq 3 ]; then
                        echo "ERROR: Failed to download Cursor AppImage after 3 attempts."
                        exit 1
                      fi
                      sleep 10
                    fi
                  done
                else
                  echo "ERROR: Could not retrieve Cursor download URL."
                  exit 1
                fi
        
                # Create desktop entry for the AppImage
                cat > "$HOME/.local/share/applications/cursor.desktop" << 'EOF'
        [Desktop Entry]
        Name=Cursor
        Exec=${pkgs.appimage-run}/bin/appimage-run %h/Applications/Cursor.AppImage
        Icon=code
        Type=Application
        Categories=Development;IDE;
        Comment=AI-first code editor
        Terminal=false
        EOF
        
                echo "Cursor installation completed successfully."
      '';
    };
    Install = {
      # Service is not automatically started - run manually with:
      # systemctl --user start install-cursor
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

  systemd.user.services.install-kdenlive = {
    Unit = {
      Description = "Download and install Kdenlive AppImage";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "install-kdenlive" ''
                # Ensure directories exist
                mkdir -p "$HOME/Applications"
                mkdir -p "$HOME/.local/share/applications"
        
                # Check if Kdenlive already exists and is recent (less than 7 days old)
                if [ -f "$HOME/Applications/Kdenlive.AppImage" ]; then
                  if [ $(find "$HOME/Applications/Kdenlive.AppImage" -mtime -7 2>/dev/null | wc -l) -gt 0 ]; then
                    echo "Kdenlive AppImage is recent, skipping download."
                    exit 0
                  fi
                fi
        
                echo "Fetching latest Kdenlive AppImage..."
        
                # Kdenlive AppImage download URL - using the official KDE download server
                DOWNLOAD_URL="https://download.kde.org/stable/kdenlive/25.08/linux/kdenlive-25.08.0-x86_64.AppImage"
        
                # Download with retry logic
                for i in {1..3}; do
                  echo "Download attempt $i/3..."
                  if ${pkgs.curl}/bin/curl --connect-timeout 30 --max-time 300 -sSfL "$DOWNLOAD_URL" -o "$HOME/Applications/Kdenlive.AppImage.tmp"; then
                    chmod +x "$HOME/Applications/Kdenlive.AppImage.tmp"
                    mv "$HOME/Applications/Kdenlive.AppImage.tmp" "$HOME/Applications/Kdenlive.AppImage"
                    echo "Kdenlive AppImage downloaded successfully."
                    break
                  else
                    echo "Download attempt $i failed, waiting 10 seconds..."
                    rm -f "$HOME/Applications/Kdenlive.AppImage.tmp"
                    if [ $i -eq 3 ]; then
                      echo "ERROR: Failed to download Kdenlive AppImage after 3 attempts."
                      exit 1
                    fi
                    sleep 10
                  fi
                done
        
                # Create desktop entry for the AppImage
                cat > "$HOME/.local/share/applications/kdenlive.desktop" << 'EOF'
        [Desktop Entry]
        Name=Kdenlive
        Exec=${pkgs.appimage-run}/bin/appimage-run %h/Applications/Kdenlive.AppImage
        Icon=kdenlive
        Type=Application
        Categories=AudioVideo;Video;VideoEditing;
        Comment=Non-linear video editor
        Terminal=false
        EOF
        
                echo "Kdenlive installation completed successfully."
      '';
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
