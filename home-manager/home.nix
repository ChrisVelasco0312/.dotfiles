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
    ./programs/rofi ./programs/neovim
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
    # IDEs
    vscode-fhs
    # LANGUAGES
    racket
    # NODE
    nodejs_22
    nodejs_22.pkgs.pnpm
    nodejs_22.pkgs.yarn
    nodejs_22.pkgs.typescript
    bun
    # TOOLS
    lazygit
    prettierd
    lua-language-server
    unzip
    bat
    fzf
    ripgrep
    jq
    tree
    eza
    gcc
    fish
    fd
    htop
    pavucontrol
    #------
    (nerdfonts.override {
      fonts = ["JetBrainsMono" "Inconsolata"];
    })
    obsidian # markdown note taking
    xournalpp # handwritten note taking
    okular # pdf viewer
    feh #image viewer
    gparted # Partition editor
    vlc # Cross-platform media player
  ];

	home.sessionVariables = {
		EDITOR="nvim";
	};

	home.shellAliases = {
		l = "eza";
		ls = "eza";
		cat = "bat";
	};

  #ZSH
	programs.zsh = { enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
	};
	programs.zsh.oh-my-zsh= {
		enable = true;
		plugins = ["git" "python" "docker" "fzf"];
		theme = "intheloop";
	};

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  ## CONFIGS
  xdg.configFile."waybar/config".source = ../dots/waybar/config;
  xdg.configFile."waybar/style.css".source = ../dots/waybar/style.css;
  xdg.configFile."kitty/kitty.conf".source = ../dots/kitty/kitty.conf;
  xdg.configFile."hypr/hyprland.conf".force = true;
  xdg.configFile."hypr/hyprland.conf".source = ../dots/hypr/hyprland.conf;
  xdg.configFile."environment.d/cursor.conf".source = ../dots/hypr/cursor.conf;
  xdg.configFile."hypr/start.sh".source = ../dots/hypr/start.sh;
  xdg.configFile."hypr/background.jpg".source = ../dots/hypr/background.jpg;

  #awesome is the wm for emergency, because it is ugly
  # xdg.configFile.awesome.source = ../dots/awesome;
}
