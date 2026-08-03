#!/usr/bin/env bash
SCRIPT_DIR="$HOME/.config/eww/scripts"

if [ $# -eq 0 ]; then
  "$SCRIPT_DIR/get-minimized.sh" | \
    jq -r '.[] | "\(.address)\t\(.class): \(.title)"'
else
  addr=$(echo "$1" | awk '{print $1}')
  [ -n "$addr" ] && "$SCRIPT_DIR/restore.sh" "$addr"
fi
