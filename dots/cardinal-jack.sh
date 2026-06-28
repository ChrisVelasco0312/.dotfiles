#!/usr/bin/env bash
SCARLETT="alsa_output.usb-Focusrite_Scarlett_2i2_4th_Gen_S2HA9TA5734C20-00.HiFi__Line1__sink"

connect_cardinal() {
  for i in $(seq 1 20); do
    if pw-link -o 2>/dev/null | grep -q "Cardinal:audio_out_1"; then
      pw-link Cardinal:audio_out_1 "${SCARLETT}:playback_FL" 2>/dev/null
      pw-link Cardinal:audio_out_2 "${SCARLETT}:playback_FR" 2>/dev/null
      break
    fi
    sleep 0.25
  done
}

pw-jack Cardinal "$@" &
connect_cardinal
wait
