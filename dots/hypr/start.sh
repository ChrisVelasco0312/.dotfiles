#!/usr/bin/env bash

hyprctl setcursor capitaine-cursors 24 &
swww init &
swww img ~/.config/hypr/background.jpg &
nm-applet --indicator &
waybar &
dunst

