{ config, pkgs, inputs, lib, ... }:

{
  home = {
    username = "cavelasco";
    homeDirectory = "/home/cavelasco";
    stateVersion = "23.05";
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
        node2nix
        nodejs
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
	];
  
  programs.neovim = {
  	enable = true;
  	viAlias = true;
	  vimAlias = true;
  };

  programs.neovim.plugins = [
   pkgs.vimPlugins.nvim-treesitter.withAllGrammars
  ];

	home.sessionVariables = {
		EDITOR="nvim";
	};
	home.shellAliases = {
		l = "eza";
		ls = "eza";
		cat = "bat";
	};

	programs.zsh = {
		enable = true;
	};
	programs.zsh.oh-my-zsh= {
		enable = true;
		plugins = ["git" "python" "docker" "fzf"];
		theme = "dpoggi";
	};

  ## CONFIGS
	xdg.configFile."hypr/hyprland.conf".source = ../dots/hypr/hyprland.conf;
  
  ## waybar
  xdg.configFile."waybar/config".source = ../dots/waybar/config;
  xdg.configFile."waybar/style.css".source = ../dots/waybar/style.css;
}
