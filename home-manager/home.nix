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
    stateVersion = "24.05";
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
    racket
    nodejs_22
    nodejs_22.pkgs.pnpm
    nodejs_22.pkgs.yarn
    nodejs_22.pkgs.typescript
    prettierd
    lua-language-server
    bun
    bat
    fzf
    ripgrep
    jq
    tree
    eza
    gcc
    fish
    pavucontrol
    mpd
    rofi
    vscode-fhs
    nitrogen
    picom
    dmenu
    unzip
    (nerdfonts.override {
      fonts = ["JetBrainsMono" "Inconsolata"];
    })
    guake
    obsidian
    lazygit
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
	programs.zsh = {
		enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
	};
	programs.zsh.oh-my-zsh= {
		enable = true;
		plugins = ["git" "python" "docker" "fzf"];
		theme = "dst";
	};

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  ## CONFIGS
  # waybar
  xdg.configFile."waybar/config".source = ../dots/waybar/config;
  xdg.configFile."waybar/style.css".source = ../dots/waybar/style.css;

  #awesome
  xdg.configFile.awesome.source = ../dots/awesome;
}
