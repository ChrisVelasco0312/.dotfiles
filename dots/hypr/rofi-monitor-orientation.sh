#!/usr/bin/env bash

# Change the orientation of the currently focused monitor.
set -euo pipefail

monitor_json=$(hyprctl monitors -j)
monitor=$(printf '%s' "$monitor_json" | jq -r '
    map(select(.focused)) | .[0].name // empty
')

if [ -z "$monitor" ]; then
    notify-send "Monitor Orientation" "No focused monitor detected"
    exit 0
fi

monitor_config=$(printf '%s' "$monitor_json" | jq -r --arg target "$monitor" '
    map(select(.name == $target)) | .[0] as $monitor |
    ($monitor.availableModes
        | map(select((split("@")[1] | rtrimstr("Hz") | tonumber) == $monitor.refreshRate))
        | .[0] // "" | sub("Hz$"; "")) as $mode |
    [$monitor.name, ($mode // ("\($monitor.width)x\($monitor.height)@\($monitor.refreshRate)")),
     "\($monitor.x)x\($monitor.y)", ($monitor.scale | tostring)] | @tsv
')
IFS=$'\t' read -r monitor mode position scale <<< "$monitor_config"

transform=$(printf '%s' "$monitor_json" | jq -r --arg target "$monitor" \
    'map(select(.name == $target)) | .[0].transform // 0')
case "$transform" in
    0) current="Normal" ;;
    1) current="90 degrees" ;;
    2) current="180 degrees" ;;
    3) current="270 degrees" ;;
    *) current="Transform $transform" ;;
esac

selected=$(printf '%s\n' \
    "Normal" \
    "90 degrees" \
    "180 degrees" \
    "270 degrees" | \
    rofi -dmenu -p "  $monitor orientation ($current)" -theme-str 'window {width: 25%;}')

case "$selected" in
    "Normal") transform=0 ;;
    "90 degrees") transform=1 ;;
    "180 degrees") transform=2 ;;
    "270 degrees") transform=3 ;;
    *) exit 0 ;;
esac

hyprctl eval "hl.monitor({ output = \"$monitor\", mode = \"$mode\", position = \"$position\", scale = $scale, transform = $transform })"
notify-send "Monitor Orientation" "$monitor: $selected"
