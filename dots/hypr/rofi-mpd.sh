#!/usr/bin/env bash

# Rofi MPD Control Script
# Depends on: mpc, rofi

LOG_FILE="/tmp/rofi-mpd.log"
echo "[$(date)] Arg: '$1' Info: '$ROFI_INFO'" >> "$LOG_FILE"

# Function to generate a progress bar
get_progress_bar() {
    status_line=$(mpc status 2>/dev/null | grep -o "([0-9]*%)")
    percent=${status_line//[^0-9]/}
    
    if [ -z "$percent" ]; then
        percent=0
    fi
    
    filled=$((percent / 5))
    empty=$((20 - filled))
    
    bar="["
    for ((i=0; i<filled; i++)); do bar+="="; done
    for ((i=0; i<empty; i++)); do bar+="-"; done
    bar+="] $percent%"
    
    echo "$bar"
}

# Function to display the main menu
show_main_menu() {
    title=$(mpc current -f %title% 2>/dev/null)
    artist=$(mpc current -f %artist% 2>/dev/null)
    album=$(mpc current -f %album% 2>/dev/null)
    
    if [ -z "$title" ] && [ -z "$artist" ]; then
        msg="Not Playing"
    else
        title=${title:-Unknown Title}
        artist=${artist:-Unknown Artist}
        album=${album:-Unknown Album}
        msg="$title - $artist ($album)"
    fi
    
    echo "[$(date)] Message: $msg" >> "$LOG_FILE"
    
    echo -en "\0prompt\x1fMPD\n"
    printf "\0message\x1f%s\n" "$msg"
    
    status=$(mpc status 2>/dev/null | grep -o "\[.*\]" | head -n1)
    if [[ "$status" == *"[playing]"* ]]; then
        echo " Pause"
    else
        echo " Play"
    fi
    
    shuffle_status=$(mpc status 2>/dev/null | grep -o "random: .*" | cut -d' ' -f2)
    if [[ "$shuffle_status" == "on" ]]; then
        echo " Shuffle Off"
    else
        echo " Shuffle On"
    fi
    
    echo " Next"
    echo " Prev"
    echo " Playlist"
}

# Handle arguments
if [ -z "$1" ]; then
    show_main_menu

elif [ -n "$ROFI_INFO" ]; then
    echo "[$(date)] Processing selection: $ROFI_INFO" >> "$LOG_FILE"
    
    if [[ "$ROFI_INFO" == "POS:"* ]]; then
        pos=${ROFI_INFO#POS:}
        mpc play "$pos" >/dev/null 2>&1
        notify-send "MPD" "Playing selection (Pos: $pos)" &
    fi
    
    show_main_menu

else
    echo "[$(date)] Processing command: '$1'" >> "$LOG_FILE"
    case "$1" in
        " Pause"|*"Pause")
            mpc pause >/dev/null 2>&1
            show_main_menu
            ;;
        " Play"|*"Play")
            mpc play >/dev/null 2>&1
            show_main_menu
            ;;
        " Next"|*"Next")
            mpc next >/dev/null 2>&1
            show_main_menu
            ;;
        " Prev"|*"Prev"|*"Previous")
            mpc prev >/dev/null 2>&1
            show_main_menu
            ;;
        " Shuffle On"|*"Shuffle On")
            mpc random on >/dev/null 2>&1
            notify-send "MPD" "Shuffle Enabled" &
            show_main_menu
            ;;
        " Shuffle Off"|*"Shuffle Off")
            mpc random off >/dev/null 2>&1
            notify-send "MPD" "Shuffle Disabled" &
            show_main_menu
            ;;
        " Playlist"|*"Playlist")
            echo "[$(date)] Listing playlist..." >> "$LOG_FILE"
            echo -en "\0prompt\x1fPlaylist\n"
            echo -en "\0message\x1fSelect song to Jump to\n"
            echo "Back"
            mpc playlist 2>/dev/null | \
            awk '{gsub(/"/, "\\\"", $0); printf "%s\0icon\x1faudio-x-generic\x1finfo\x1fPOS:%d\n", $0, NR}'
            ;;
        "Back")
            show_main_menu
            ;;
        *)
            echo "[$(date)] Unknown command: '$1', returning to main menu" >> "$LOG_FILE"
            show_main_menu
            ;;
    esac
fi
