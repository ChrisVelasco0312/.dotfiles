#!/usr/bin/env bash
export PATH="/run/current-system/sw/bin:/home/cavelasco/.nix-profile/bin:$PATH"

bar() {
    local pct=$1
    local len=${2:-30}
    local filled=$(( pct * len / 100 ))
    [ "$filled" -gt "$len" ] && filled=$len
    local empty=$(( len - filled ))
    local b=""
    local i
    for ((i=0; i<filled; i++)); do b+="█"; done
    for ((i=0; i<empty; i++)); do b+="▁"; done
    echo "$b"
}

VOLUME=$(wpctl get-volume @DEFAULT_SINK@ | grep -oP '\d+\.\d+' | awk '{printf "%.0f", $1 * 100}')
MUTED=$(wpctl get-volume @DEFAULT_SINK@ | grep -oP -q 'MUTED' && echo "yes" || echo "no")

if [ "$MUTED" = "yes" ]; then
    TEXT="󰖁 Muted"
    TOOLTIP="$(bar 0 30)  0%  (Muted)"
    CLASS="muted"
else
    TEXT="󰕾 ${VOLUME}%"
    TOOLTIP="$(bar $VOLUME 30)  ${VOLUME}%"
    CLASS="on"
fi

jq -nc --arg text "$TEXT" --arg tooltip "$TOOLTIP" --arg class "$CLASS" '{text: $text, tooltip: $tooltip, class: $class}'