#!/usr/bin/env bash

# Rofi Music Launcher with MPD and Tidal tabs
# Usage: ./rofi-music.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean up any leftover state
rm -f /tmp/rofi-tidal-state

# Launch rofi with MPD, Tidal and Wallpaper as tabs (modi)
rofi -show MPD \
    -modi "MPD:$SCRIPT_DIR/rofi-mpd.sh,Tidal:$SCRIPT_DIR/rofi-tidal.py,Wallpaper:$SCRIPT_DIR/rofi-wallpaper.sh" \
    -theme-str 'window {width: 60%;}' \
    -matching normal \
    -sort false
