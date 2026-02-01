#!/usr/bin/env bash

nm-applet --indicator &
waybar &
dunst &
swww-daemon &

# Start background cycle script
python3 /home/cavelasco/.dotfiles/dots/hypr/background-cycle.py &

# Start rescrobbled
rescrobbled &

