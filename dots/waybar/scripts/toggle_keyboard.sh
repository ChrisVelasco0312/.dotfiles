#!/usr/bin/env bash
export PATH="/run/current-system/sw/bin:/home/cavelasco/.nix-profile/bin:$PATH"

KBD="chicony-usb-keyboard"
STATE_FILE="/tmp/keyboard_disabled"

get_state() {
    if [ -f "$STATE_FILE" ]; then
        echo "off"
    else
        echo "on"
    fi
}

if [ "$1" = "--status" ]; then
    STATE=$(get_state)
    if [ "$STATE" = "on" ]; then
        echo "󰌌"
    else
        echo "<span color='#888888'>󰌌</span>"
    fi
    exit 0
fi

if [ -f "$STATE_FILE" ]; then
    # Hyprland 0.55+ Lua parser: `hyprctl keyword` no longer works for device
    # options; runtime config changes must go through the Lua `hl.device` API.
    hyprctl eval "hl.device({ name = \"$KBD\", enabled = true })" >/dev/null 2>&1
    rm "$STATE_FILE"
    echo "󰌌"
else
    hyprctl eval "hl.device({ name = \"$KBD\", enabled = false })" >/dev/null 2>&1
    touch "$STATE_FILE"
    echo "<span color='#888888'>󰌌</span>"
fi