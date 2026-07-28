#!/usr/bin/env bash

# Rofi menu for PipeWire buffer size (quantum) control

meta=$(pw-metadata -n settings 2>&1)

force=$(echo "$meta" | grep "clock.force-quantum" | sed -n "s/.*value:'\\([0-9]*\\)'.*/\\1/p")
default=$(echo "$meta" | grep "clock.quantum" | grep -v force | sed -n "s/.*value:'\\([0-9]*\\)'.*/\\1/p")

force=${force:-0}
current=$([ "$force" -gt 0 ] 2>/dev/null && echo "$force" || echo "${default:-128}")

ACTIVE_128=""; ACTIVE_256=""; ACTIVE_512=""
case "$current" in
  256) ACTIVE_256=" ✓" ;;
  512) ACTIVE_512=" ✓" ;;
  *)   ACTIVE_128=" ✓" ;;
esac

OPTIONS="128 (default)${ACTIVE_128}
256${ACTIVE_256}
512${ACTIVE_512}"

selected=$(echo "$OPTIONS" | rofi -dmenu -p "  Buffer Size: ${current} samples")

val=$(echo "$selected" | grep -oP "^\d+")

case "$val" in
  128) pw-metadata -n settings 0 clock.force-quantum 128 ;;
  256) pw-metadata -n settings 0 clock.force-quantum 256 ;;
  512) pw-metadata -n settings 0 clock.force-quantum 512 ;;
esac

[ -n "$val" ] && notify-send "PipeWire Buffer" "${val} samples"
