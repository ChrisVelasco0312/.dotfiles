{pkgs, ... }:
{
programs.alacritty = {
		enable = true;
		settings = {
			env.TERM = "xterm-256color";
			window.padding = {
				x = 10;
				y=10;
			};
			window.decorations = "none";
			window.opacity = 0.5;
			scrolling.history = 1000;
			font = {
				normal = {
					family = "JetBrains Mono Nerd Font";
					style = "Regular";
				};
				bold = {
					family = "JetBrains Mono Nerd Font";
					style = "Bold";
				};
				italic = {
					family = "JetBrains Mono Nerd Font";
					style = "Italic";
				};
				size = 12;
			};
		};
	};
}