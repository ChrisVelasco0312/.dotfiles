#!/usr/bin/env bash

# Rofi command palette.
# Lists every custom command / Hyprland keybind and runs the selected one.
# Bind: SUPER + SLASH (see hyprland.lua)

THEME_STR=(
  'window {width: 700px;}'
  'listview {lines: 18; scrollbar: true;}'
  'entry {placeholder: "Search commands...";}'
)

labels=()
commands=()

add() {
  if [ -n "$1" ]; then
    labels+=("$(printf '%-18s %s' "$1" "$2")")
  else
    labels+=("$2")
  fi
  commands+=("$3")
}

# --- Applications -----------------------------------------------------------
add "SUPER+Q"        "Terminal (kitty)"          "kitty"
add "SUPER+E"        "File Manager (nautilus)"   "nautilus"
add "SUPER+W"        "Browser (firefox)"         "firefox"
add "SUPER+S"        "App Launcher"              "rofi -show drun"
add "SUPER+O"        "System Monitor"            "missioncenter"
add "SUPER+M"        "Music (MPD / Tidal)"       "/home/cavelasco/.dotfiles/dots/hypr/rofi-music.sh"

# --- Window management ------------------------------------------------------
add "SUPER+C"        "Close Window"              "hyprctl dispatch killactive"
add "SUPER+V"        "Toggle Floating"           "hyprctl dispatch togglefloating"
add "SUPER+P"        "Toggle Pseudo"             "hyprctl dispatch pseudo"
add "SUPER+U"        "Toggle Split"              "hyprctl dispatch togglesplit"
add "SUPER+H"        "Focus Left"                "hyprctl dispatch movefocus l"
add "SUPER+L"        "Focus Right"               "hyprctl dispatch movefocus r"
add "SUPER+K"        "Focus Up"                  "hyprctl dispatch movefocus u"
add "SUPER+J"        "Focus Down"                "hyprctl dispatch movefocus d"
add "SUPER+D"        "Minimize Window"           "~/.config/eww/scripts/minimize.sh"
add "SUPER+SHIFT+D"  "Restore Minimized"         '~/.config/eww/scripts/get-minimized.sh | jq -r '"'"'.[] | "\(.address) \(.class): \(.title)"'"'"' | rofi -dmenu -theme ~/.config/rofi/window-switcher.rasi -p "Restore" | awk '"'"'{print $1}'"'"' | xargs -r ~/.config/eww/scripts/restore.sh'

# --- Workspaces -------------------------------------------------------------
for i in 1 2 3 4 5 6 7 8 9 10; do
  key=$([ "$i" -eq 10 ] && echo "0" || echo "$i")
  add "SUPER+$key"   "Workspace $i"              "hyprctl dispatch workspace $i"
done

# --- Screenshots ------------------------------------------------------------
add "PRINT"          "Screenshot & Annotate"     'grim -g "$(slurp)" -t ppm - | satty --filename - --fullscreen --copy-command "wl-copy" --output-filename ~/Pictures/Screenshots/satty-$(date +%Y%m%d-%H:%M:%S).png'
add "SUPER+PRINT"    "Screenshot Window"         "hyprshot -m window"
add "SUPER+SHIFT+PRINT" "Screenshot Region"      "hyprshot -m region"
add "SUPER+SHIFT+S"  "Screenshot to Clipboard"   'grim -g "$(slurp)" - | wl-copy'

# --- System / session -------------------------------------------------------
add "SUPER+R"        "Reload Hyprland"           "hyprctl reload"
add "SUPER+B"        "Restart Waybar"            "pkill waybar || waybar &"
add "SUPER+N"        "Night Light (gammastep)"   "/home/cavelasco/.dotfiles/dots/hypr/rofi-gammastep.sh"
add "SUPER+A"        "Audio Buffer Size"         "/home/cavelasco/.dotfiles/dots/hypr/rofi-buffer-size.sh"
add "SUPER+SHIFT+Y"  "Monitor Orientation"       "/home/cavelasco/.dotfiles/dots/hypr/rofi-monitor-orientation.sh"
add ""               "Power Menu"                "/home/cavelasco/.dotfiles/dots/waybar/scripts/power_menu.sh"
add ""               "Lock Screen"               "swaylock -f -c 000000"

# --- Audio / brightness -----------------------------------------------------
add ""               "Volume Up"                 "wpctl set-volume @DEFAULT_SINK@ 5%+"
add ""               "Volume Down"               "wpctl set-volume @DEFAULT_SINK@ 5%-"
add ""               "Mute"                      "wpctl set-mute @DEFAULT_SINK@ toggle"
add ""               "Brightness Up"             "brightnessctl set 10%+"
add ""               "Brightness Down"           "brightnessctl set 10%-"

theme_args=()
for s in "${THEME_STR[@]}"; do theme_args+=(-theme-str "$s"); done

chosen="$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -p "  Commands" "${theme_args[@]}")"

[ -z "$chosen" ] && exit 0

for i in "${!labels[@]}"; do
  if [ "${labels[$i]}" = "$chosen" ]; then
    setsid -f bash -c "${commands[$i]}" >/dev/null 2>&1
    break
  fi
done
