{ config, pkgs, inputs, lib, ... }:

{
  home.username = "cavelasco";
  home.homeDirectory = "/home/cavelasco";
  home.stateVersion = "22.11";
  nixpkgs = {
		config = {
			allowUnfree = true;
			allowUnfreePredicate = (_: true);
		};
	};

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.packages = with pkgs; [
        bat
        fzf
        ripgrep
        jq
        tree
        eza
	];
  
  programs.neovim = {
  	enable = true;
  	viAlias = true;
	vimAlias = true;
  	};

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

	xdg.configFile."hypr/hyprland.conf".source = ../dots/hypr/hyprland.conf;

	xdg.configFile.nvim.source = ../dots/nvim-frankenstein;

}
