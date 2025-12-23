#!/usr/bin/env bash

swww daemon &
swww img ~/.config/hypr/background.jpg &
nm-applet --indicator &
waybar &
dunst

