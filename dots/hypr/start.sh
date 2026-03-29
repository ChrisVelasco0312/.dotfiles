#!/usr/bin/env bash

nm-applet --indicator &
waybar &
dunst &
swww-daemon &

# Apply startup wallpaper using the same flow as the rofi picker.
# This keeps the original image sizing/behavior consistent after reboot.
(
  sleep 1
  first_recent_line="$("$HOME/.dotfiles/dots/hypr/wallpaper-picker.py" --recent 2>/dev/null | sed -n '1p')"
  first_recent_url="$(printf '%s' "$first_recent_line" | awk -F $'\x1finfo\x1f' 'NF>1{print $2}')"

  if [ -n "$first_recent_url" ]; then
    "$HOME/.dotfiles/dots/hypr/wallpaper-picker.py" --set "$first_recent_url"
  fi
) &

rescrobbled &

