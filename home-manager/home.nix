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
    };

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
    qutebrowser
    # editors
    vscode
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
    python312Packages.pylsp-mypy
    python312Packages.python-lsp-black
    python312Packages.python-lsp-ruff
    python312Packages.pyls-isort
    python312Packages.pylsp-rope
    ruff
    mypy
    black
    isort
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
    # PYTHON
    python312
    python312Packages.pip
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
    pandoc
    fish
    fd
    htop
    pavucontrol
    brightnessctl
    mission-center
    # Fonts & Cursors
    # (nerdfonts.override {
    #   fonts = [ "JetBrainsMono" "Inconsolata" ];
    # })
    capitaine-cursors
    hunspell
    hunspellDicts.es_CO
    hunspellDicts.es-es
    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.inconsolata
    # APPS
    postman # API testing
    anki # spaced repetition cards
    ardour # audio editing
    zotero # research management
    xournalpp # handwritten note taking
    kdePackages.okular 
    feh #image viewer
    gparted # Partition editor
    vlc # Cross-platform media player
    libsForQt5.dolphin # file manager
    libsForQt5.dolphin-plugins
    libsForQt5.breeze-icons # icons
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
    spotify # music stream
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
    spotify
    obs-studio
    inkscape
    obsidian
    hyprshot
    kitty
    kitty-themes
    ffmpeg
    # Phone microphone streaming
    mumble
    pulseaudio
    # DAW
    reaper
    # Cloud
    google-cloud-sdk
  ];

  # ---- GITHUB SSH -------#
  programs.ssh.enable = true;
  services.ssh-agent.enable = true;
  programs.ssh.matchBlocks = {
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
  programs.ssh.addKeysToAgent = "yes";
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
      alias gemini="npx https://github.com/google-gemini/gemini-cli"
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

  # CURSOR APPIMAGE INSTALLATION - using systemd service for better network access
  home.activation.createCursorDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
        
        # Check if Cursor already exists and is recent (less than 7 days old)
        if [ -f "$HOME/Applications/Cursor.AppImage" ]; then
          if [ $(find "$HOME/Applications/Cursor.AppImage" -mtime -7 2>/dev/null | wc -l) -gt 0 ]; then
            echo "Cursor AppImage is recent, skipping download."
            exit 0
          fi
        fi
        
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
      WantedBy = [ "default.target" ];
    };
  };
}
