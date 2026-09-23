#!/usr/bin/env bash
set -e
STATE="$XDG_RUNTIME_DIR/eww-minimized.json"
addr="$1"
[ -z "$addr" ] && exit 1

ws=$(jq -r --arg addr "$addr" '.[] | select(.address == $addr) | .workspace' "$STATE")
[ -z "$ws" ] && exit 1

hyprctl dispatch "hl.dsp.window.move({ workspace = $ws, follow = true, window = 'address:$addr' })"
hyprctl dispatch "hl.dsp.focus({ window = 'address:$addr' })"

jq --arg addr "$addr" 'map(select(.address != $addr))' "$STATE" > "${STATE}.tmp" && mv "${STATE}.tmp" "$STATE"
