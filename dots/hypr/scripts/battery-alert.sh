#!/usr/bin/env bash

BATTERY_PATH=$(find /sys/class/power_supply -name 'BAT*' -maxdepth 1 -type d 2>/dev/null | head -n1)
if [ -z "$BATTERY_PATH" ]; then
  echo "No battery found, exiting."
  exit 0
fi

WARN_LEVEL=20
CRIT_LEVEL=10
EMERGENCY_LEVEL=5

ALERT_20_SENT=0
ALERT_10_SENT=0
ALERT_5_SENT=0

get_capacity() {
  cat "$BATTERY_PATH/capacity" 2>/dev/null || echo 100
}

is_charging() {
  local status
  status=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")
  case "$status" in
    Charging|Full) return 0 ;;
    *) return 1 ;;
  esac
}

reset_alerts() {
  ALERT_20_SENT=0
  ALERT_10_SENT=0
  ALERT_5_SENT=0
}

while true; do
  capacity=$(get_capacity)

  if is_charging; then
    reset_alerts
  else
    if [ "$capacity" -le "$EMERGENCY_LEVEL" ] && [ "$ALERT_5_SENT" -eq 0 ]; then
      notify-send -u critical -i battery-low \
        "Battery Critical" \
        "Battery is at ${capacity}%! Plug in your charger now."
      ALERT_5_SENT=1
    elif [ "$capacity" -le "$CRIT_LEVEL" ] && [ "$ALERT_10_SENT" -eq 0 ]; then
      notify-send -u critical -i battery-low \
        "Battery Low" \
        "Battery is at ${capacity}%. Consider plugging in your charger."
      ALERT_10_SENT=1
    elif [ "$capacity" -le "$WARN_LEVEL" ] && [ "$ALERT_20_SENT" -eq 0 ]; then
      notify-send -u normal -i battery-caution \
        "Battery Warning" \
        "Battery is at ${capacity}%."
      ALERT_20_SENT=1
    fi
  fi

  sleep 60
done
