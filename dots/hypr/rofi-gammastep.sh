#!/usr/bin/env bash

# Rofi menu for Hyprsunset blue light filter control
# Usage: ./rofi-gammastep.sh

OPTIONS="\
Disable
Day (6500K)
Evening (4500K)
Night (3500K)
Deep Night (2500K)
Custom..."

selected=$(echo "$OPTIONS" | rofi -dmenu -p "  Blue Light Filter" -theme-str 'window {width: 25%;}')

set_temp() {
    pkill -x hyprsunset 2>/dev/null
    sleep 0.1
    hyprsunset -t "$1" &
    disown
}

case "$selected" in
    "Disable")
        pkill -x hyprsunset
        notify-send "Blue Light Filter" "Disabled"
        ;;
    "Day (6500K)")
        set_temp 6500
        notify-send "Blue Light Filter" "Day mode (6500K)"
        ;;
    "Evening (4500K)")
        set_temp 4500
        notify-send "Blue Light Filter" "Evening mode (4500K)"
        ;;
    "Night (3500K)")
        set_temp 3500
        notify-send "Blue Light Filter" "Night mode (3500K)"
        ;;
    "Deep Night (2500K)")
        set_temp 2500
        notify-send "Blue Light Filter" "Deep night mode (2500K)"
        ;;
    "Custom...")
        temp=$(rofi -dmenu -p "Temperature (K)" -theme-str 'window {width: 20%;}' -filter "" <<< "")
        if [[ "$temp" =~ ^[0-9]+$ ]] && [ "$temp" -ge 1000 ] && [ "$temp" -le 6500 ]; then
            set_temp "$temp"
            notify-send "Blue Light Filter" "Custom: ${temp}K"
        elif [ -n "$temp" ]; then
            notify-send "Blue Light Filter" "Invalid temperature (1000-6500K)"
        fi
        ;;
esac
