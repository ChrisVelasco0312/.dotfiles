#!/usr/bin/env bash
export PATH="/run/current-system/sw/bin:/home/cavelasco/.nix-profile/bin:$PATH"

bar() {
    local pct=$1
    local len=10
    local filled=$(( pct * len / 100 ))
    [ "$filled" -gt "$len" ] && filled=$len
    local empty=$(( len - filled ))
    local b=""
    local i
    for ((i=0; i<filled; i++)); do b+="█"; done
    for ((i=0; i<empty; i++)); do b+="░"; done
    echo "$b"
}

VCPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | awk '{printf "%.0f", $1}')
VRAM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
VRAM_USED=$(free -m | awk '/^Mem:/ {print $3}')
VRAM_PCT=$(( VRAM_USED * 100 / VRAM_TOTAL ))
VGPU_PCT=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | tr -d ' ')
VGPU_MEM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | tr -d ' ')
VGPU_MEM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | tr -d ' ')
VGPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | tr -d ' ')
VDISK_TOTAL=$(df -BG / | awk 'NR==2 {gsub("G","",$2); print $2}')
VDISK_USED=$(df -BG / | awk 'NR==2 {gsub("G","",$3); print $3}')
VDISK_PCT=$(( VDISK_USED * 100 / VDISK_TOTAL ))

TOOLTIP=$(printf 'CPU    %s  %s%%\nRAM    %s  %sM/%sM\nGPU    %s  %s%% (%s/%sMiB @ %s°C)\nDisk   %s  %sG/%sG' \
    "$(bar $VCPU)" "$VCPU" \
    "$(bar $VRAM_PCT)" "$VRAM_USED" "$VRAM_TOTAL" \
    "$(bar $VGPU_PCT)" "$VGPU_PCT" "$VGPU_MEM_USED" "$VGPU_MEM_TOTAL" "$VGPU_TEMP" \
    "$(bar $VDISK_PCT)" "$VDISK_USED" "$VDISK_TOTAL")

jq -nc --arg text "󰍛" --arg tooltip "$TOOLTIP" '{text: $text, tooltip: $tooltip}'