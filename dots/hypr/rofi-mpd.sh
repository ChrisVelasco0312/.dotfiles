#!/usr/bin/env bash

# Rofi MPD Control Script
# Depends on: mpc, rofi

LOG_FILE="/tmp/rofi-mpd.log"
# Enable logging for debugging
echo "[$(date)] Arg: '$1' Info: '$ROFI_INFO'" >> "$LOG_FILE"

# Function to display the main menu
show_main_menu() {
    # Get current song
    current_song=$(mpc current -f "%artist% - %title%" 2>/dev/null)
    if [ -z "$current_song" ]; then
        current_song="Not Playing"
    fi
    
    # Send Rofi commands
    echo -en "\0prompt\x1fMPD\n"
    echo -en "\0message\x1fNow Playing: $current_song\n"
    
    # Determine Play/Pause state
    status=$(mpc status 2>/dev/null | grep -o "\[.*\]" | head -n1)
    if [[ "$status" == *"[playing]"* ]]; then
        echo " Pause"
    else
        echo " Play"
    fi
    
    echo " Next"
    echo " Prev"
    echo " Shuffle"
    echo " Playlist"
    # echo " Search Library" # Disabled as listall is not supported by current server config
}

# Handle arguments
if [ -z "$1" ]; then
    show_main_menu

elif [ -n "$ROFI_INFO" ]; then
    # Action based on selection with info
    echo "[$(date)] Processing selection: $ROFI_INFO" >> "$LOG_FILE"
    
    if [[ "$ROFI_INFO" == "POS:"* ]]; then
        # It's a playlist position
        pos=${ROFI_INFO#POS:}
        mpc play "$pos" >/dev/null 2>&1
        notify-send "MPD" "Playing selection (Pos: $pos)" &
    fi
    
    # Return to main menu
    show_main_menu

else
    # Command Handling
    case "$1" in
        *"Pause")
            mpc pause >/dev/null 2>&1
            show_main_menu
            ;;
        *"Play")
            mpc play >/dev/null 2>&1
            show_main_menu
            ;;
        *"Next")
            mpc next >/dev/null 2>&1
            show_main_menu
            ;;
        *"Prev")
            mpc prev >/dev/null 2>&1
            show_main_menu
            ;;
        *"Shuffle")
            mpc shuffle >/dev/null 2>&1
            notify-send "MPD" "Shuffled Playlist" &
            show_main_menu
            ;;
        *"Playlist")
            echo "[$(date)] Listing playlist..." >> "$LOG_FILE"
            echo -en "\0prompt\x1fPlaylist\n"
            echo -en "\0message\x1fSelect song to Jump to\n"
            echo "Back"
            # Use mpc playlist (standard output) and use line number (NR) as position
            # Escape " to \" for printf safety
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
