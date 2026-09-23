-- Hyprland Lua configuration.

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

local terminal = "kitty"
local fileManager = "nautilus"
local menu = "rofi -show drun"
local volup = "wpctl set-volume @DEFAULT_SINK@ 5%+"
local voldown = "wpctl set-volume @DEFAULT_SINK@ 5%-"
local mute = "wpctl set-mute @DEFAULT_SINK@ toggle"
local reset = "hyprctl reload"
local screenshotEdit = [[grim -g "$(slurp)" -t ppm - | satty --filename - --fullscreen --copy-command "wl-copy" --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png]]
local screenshot = [[grim -g "$(slurp)" - | wl-copy]]

hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "capitaine-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

hl.config({
    input = {
        kb_layout = "us, latam",
        kb_variant = "",
        kb_model = "",
        kb_options = "grp:win_space_toggle",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0.2,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = true,
        },
    },

    general = {
        border_size = 1,
        gaps_in = 5,
        gaps_out = 8,
        col = {
            active_border = "rgba(696969aa)",
            inactive_border = "rgba(595959aa)",
        },
    },

    decoration = {
        rounding = 0,
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
        vrr = 0,
    },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "default" })

hl.window_rule({ match = { class = "^(rofi)$" }, float = true })
hl.window_rule({ match = { class = "^(gamescope)$" }, stay_focused = true })
hl.window_rule({ match = { class = "^(gamescope)$" }, min_size = { 1, 1 } })
hl.window_rule({ match = { class = "^(gamescope)$" }, immediate = true })
hl.window_rule({ match = { class = "^(gamescope)$" }, fullscreen = true })

local mainMod = "SUPER"
local shiftMod = "SUPER + SHIFT"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/window-switcher.rasi -show-icons"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("/home/cavelasco/.dotfiles/dots/hypr/rofi-music.sh"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + U", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(reset))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("missioncenter"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("pkill waybar || waybar &"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("/home/cavelasco/.dotfiles/dots/hypr/rofi-gammastep.sh"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("/home/cavelasco/.dotfiles/dots/hypr/rofi-buffer-size.sh"))

hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("PRINT", hl.dsp.exec_cmd(screenshotEdit))
hl.bind(shiftMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(shiftMod .. " + S", hl.dsp.exec_cmd(screenshot))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volup))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(voldown))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(mute))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"))
hl.bind(mainMod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"))
hl.bind(mainMod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"))
hl.bind(mainMod .. " + XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ toggle"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.config/eww/scripts/minimize.sh"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd([[~/.config/eww/scripts/get-minimized.sh | jq -r '.[] | "\(.address) \(.class): \(.title)"' | rofi -dmenu -theme ~/.config/rofi/window-switcher.rasi -p "Restore" | awk '{print $1}' | xargs -r ~/.config/eww/scripts/restore.sh]]))

hl.on("hyprland.start", function()
    hl.exec_cmd("eww daemon && eww open minimized_bar")
    hl.exec_cmd("bash ~/.config/hypr/start.sh")
end)
