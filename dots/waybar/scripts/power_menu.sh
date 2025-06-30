#!/usr/bin/env bash

# Power menu script for waybar

options="🔒 Lock\n🚪 Logout\n💤 Suspend\n🔄 Restart\n⏻ Shutdown"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" \
    -theme-str 'window {width: 340px; height: 250px;}' \
    -theme-str 'listview {lines: 5; columns: 1;}' \
    -theme-str 'element {padding: 2px; margin: 2px;}' \
    -theme-str 'element-text {horizontal-align: 0.0;}' \
    -theme-str 'prompt {enabled: false;}' \
    -theme-str 'inputbar {children: [prompt, entry]; margin: 0px 0px 10px 0px;}' \
    -theme-str 'entry {placeholder: "Power Menu";}')

case $chosen in
    "🔒 Lock")
        # Adjust lock command based on your lock screen setup
        swaylock -f -c 000000 || hyprctl dispatch dpms off
        ;;
    "🚪 Logout")
        hyprctl dispatch exit
        ;;
    "💤 Suspend")
        systemctl suspend
        ;;
    "🔄 Restart")
        systemctl reboot
        ;;
    "⏻ Shutdown")
        systemctl poweroff
        ;;
esac 