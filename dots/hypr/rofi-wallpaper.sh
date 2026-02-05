#!/usr/bin/env bash

# Wrapper for Rofi Script Mode
# Usage: rofi-wallpaper.sh [argument]

SCRIPT_DIR=$(dirname "$0")
PYTHON_SCRIPT="$SCRIPT_DIR/wallpaper-picker.py"
LOG_FILE="/tmp/rofi-debug.log"

# Ensure python script is executable
chmod +x "$PYTHON_SCRIPT"

# Log everything
echo "[$(date)] Arg1: '$1', ROFI_INFO: '$ROFI_INFO'" >> "$LOG_FILE"

if [ -z "$1" ]; then
    # No argument: Show Recent Albums (Initial View)
    "$PYTHON_SCRIPT" --recent
    
    # Rofi options
    echo -en "\0use-hot-keys\x1ftrue\n"
    echo -en "\0keep-selection\x1ffalse\n"
    echo -en "\0message\x1fType to search Tidal...\n"

elif [ -n "$ROFI_INFO" ]; then
    # User selected an entry with an attached INFO (URL)
    echo "[$(date)] ROFI_INFO found (URL), setting wallpaper: $ROFI_INFO" >> "$LOG_FILE"
    "$PYTHON_SCRIPT" --set "$ROFI_INFO" >> "$LOG_FILE" 2>&1

else
    # No INFO, so this must be user input (Search Query)
    SELECTION="$1"
    
    # Double check it's not a URL just in case
    if [[ "$SELECTION" == http* ]]; then
         echo "[$(date)] Argument is URL, setting wallpaper" >> "$LOG_FILE"
        "$PYTHON_SCRIPT" --set "$SELECTION" >> "$LOG_FILE" 2>&1
    else
        echo "[$(date)] Search query detected: $SELECTION" >> "$LOG_FILE"
        "$PYTHON_SCRIPT" --search "$SELECTION"
        echo -en "\0message\x1fSearch results for: $SELECTION\n"
    fi
fi
