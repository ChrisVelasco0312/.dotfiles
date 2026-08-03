#!/usr/bin/env bash
set -e
STATE="$XDG_RUNTIME_DIR/eww-minimized.json"
[ ! -f "$STATE" ] && echo '[]' > "$STATE"

active=$(hyprctl activewindow -j)
addr=$(echo "$active" | jq -r '.address')
[ -z "$addr" ] || [ "$addr" = "null" ] && exit 0

# Don't add duplicate if already minimized
already=$(jq --arg addr "$addr" '[.[] | select(.address == $addr)] | length' "$STATE" 2>/dev/null)
[ "$already" -gt 0 ] && exit 0

class=$(echo "$active" | jq -r '.class')
title=$(echo "$active" | jq -r '.title')
ws_id=$(echo "$active" | jq -r '.workspace.id')

jq --arg addr "$addr" --arg class "$class" --arg title "$title" --argjson ws "$ws_id" \
  '. += [{"address": $addr, "class": $class, "title": $title, "workspace": $ws}]' \
  "$STATE" > "${STATE}.tmp" && mv "${STATE}.tmp" "$STATE"

hyprctl dispatch movetoworkspacesilent "special:minimized,address:$addr"