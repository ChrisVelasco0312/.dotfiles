#!/usr/bin/env bash
SCARLETT="alsa_output.usb-Focusrite_Scarlett_2i2_4th_Gen_S2HA9TA5734C20-00.HiFi__Line1__sink"

connect_pd() {
  for i in $(seq 1 20); do
    if pw-link -o 2>/dev/null | grep -q "pure_data:output_1"; then
      pw-link pure_data:output_1 "${SCARLETT}:playback_FL" 2>/dev/null
      pw-link pure_data:output_2 "${SCARLETT}:playback_FR" 2>/dev/null
      break
    fi
    sleep 0.25
  done
}

connect_plugdata() {
  for i in $(seq 1 20); do
    if pw-link -o 2>/dev/null | grep -q "PlugData:output_1"; then
      pw-link PlugData:output_1 "${SCARLETT}:playback_FL" 2>/dev/null
      pw-link PlugData:output_2 "${SCARLETT}:playback_FR" 2>/dev/null
      break
    fi
    sleep 0.25
  done
}

case "$(basename "$0")" in
  pd-jack.sh)
    pw-jack pd -jack -inchannels 4 -outchannels 2 "$@" &
    connect_pd
    wait
    ;;
  plugdata-jack.sh)
    pw-jack plugdata "$@" &
    connect_plugdata
    wait
    ;;
esac