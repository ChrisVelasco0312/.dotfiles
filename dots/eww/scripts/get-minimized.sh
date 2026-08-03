#!/usr/bin/env bash
STATE="$XDG_RUNTIME_DIR/eww-minimized.json"
[ ! -f "$STATE" ] && echo '[]' > "$STATE"

# Only keep windows currently in special:minimized (prunes restored/closed)
minimized_addrs=$(hyprctl clients -j | jq -r '[.[] | select(.workspace.name == "special:minimized") | .address]')
jq --argjson addrs "$minimized_addrs" \
  '[.[] | select(.address as $a | $addrs | index($a))]' \
  "$STATE" > "${STATE}.tmp" 2>/dev/null && mv "${STATE}.tmp" "$STATE"

cat "$STATE"