#!/usr/bin/env bash

nm-applet --indicator &
waybar &
dunst &
awww-daemon &
~/.dotfiles/dots/hypr/scripts/battery-alert.sh &

# Start wallpaper cycling based on Last.fm scrobbles
(
  sleep 2
  python3 ~/.dotfiles/dots/hypr/background-cycle.py &
) &
