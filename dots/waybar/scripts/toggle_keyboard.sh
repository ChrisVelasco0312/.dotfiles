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
    hyprctl keyword "device[$KBD]:enabled" true
    rm "$STATE_FILE"
    echo "󰌌"
else
    hyprctl keyword "device[$KBD]:enabled" false
    touch "$STATE_FILE"
    echo "<span color='#888888'>󰌌</span>"
fi