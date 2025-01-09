#!/usr/bin/env bash

# Get volume and mute status
VOLUME=$(wpctl get-volume @DEFAULT_SINK@ | grep -oP '\d+\.\d+' | awk '{printf "%.0f", $1 * 100}')
MUTED=$(wpctl get-volume @DEFAULT_SINK@ | grep -oP '(MUTED|UNMUTED)')

if [[ "$1" == "tooltip" ]]; then
  echo -e "Volume: $VOLUME%\nMute: $MUTED"
elif [[ "$1" == "adjust" ]]; then
  case "$2" in
    up)
      wpctl set-volume @DEFAULT_SINK@ 5%+
      ;;
    down)
      wpctl set-volume @DEFAULT_SINK@ 5%-
      ;;
    mute)
      wpctl set-mute @DEFAULT_SINK@ toggle
      ;;
  esac
fi

# Output the volume for the module display
echo "$VOLUME%"

