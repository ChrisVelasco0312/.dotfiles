{ pkgs, ... }:
let
  tmux-super-fingers = pkgs.tmuxPlugins.mkTmuxPlugin
    {
      pluginName = "tmux-super-fingers";
      version = "unstable-2023-01-06";
      src = pkgs.fetchFromGitHub {
        owner = "artemave";
        repo = "tmux_super_fingers";
        rev = "2c12044984124e74e21a5a87d00f844083e4bdf7";
        sha256 = "sha256-cPZCV8xk9QpU49/7H8iGhQYK6JwWjviL29eWabuqruc=";
      };
    };
in
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
    plugins = with pkgs;
      [
        {
          plugin = tmux-super-fingers;
          extraConfig = "set -g @super-fingers-key f";
        }
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.dracula
      ];
    extraConfig = ''
      set -g mouse on

      # act like vim
      setw -g mode-keys vi
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # map prefix to Control + a
      set -g prefix C-a

      ## THEME CONFIG
      set -g @dracula-show-powerline true
      set -g @dracula-fixed-location "NYC"
      set -g @dracula-plugins "weather"
      set -g @dracula-show-flags true
      set -g @dracula-show-left-icon session
      set -g status-position bottom

      set-option -sa terminal-features ',XXX:RGB'
    '';
  };
}
