-- https://wiki.hypr.land/Configuring/
--
-- Lua config format, required from Hyprland 0.57 (hyprlang .conf is dropped there).
-- API reference: /usr/share/hypr/stubs/hl.meta.lua
--
-- You can split this configuration into multiple files like this:
-- require("myColors")

-- -- NVIDIA Settings --
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.config({
    -- Cursor Fix
    cursor = {
        no_hardware_cursors = true,
    },

    -- Fix HiDPI issues
    xwayland = {
        force_zero_scaling = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Original 10-bit + color managed config (uncomment to restore):
-- hl.monitor({ output = "desc:Dell Inc. DELL U2723QE", mode = "3840x2160@60", position = "0x0", scale = 1.6, bitdepth = 10, cm = "dcip3" })
-- hl.monitor({ output = "desc:Philips Consumer Electronics Company PHL 276E8V", mode = "3840x2160@60", position = "2400x0", scale = 1.6, bitdepth = 10, cm = "srgb" })

-- Plain 8-bit sRGB config for FH6/NVIDIA flicker workaround:
hl.monitor({ output = "desc:Dell Inc. DELL U2723QE", mode = "3840x2160@60", position = "0x0", scale = 1.6 })
hl.monitor({ output = "desc:Philips Consumer Electronics Company PHL 276E8V", mode = "3840x2160@60", position = "2400x0", scale = 1.6 })

local monitorDell = "desc:Dell Inc. DELL U2723QE"
local monitorPhilips = "desc:Philips Consumer Electronics Company PHL 276E8V"

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.workspace_rule({ workspace = "1", monitor = monitorDell, default = true })
hl.workspace_rule({ workspace = "2", monitor = monitorPhilips, default = true })
hl.workspace_rule({ workspace = "3", monitor = monitorDell })
hl.workspace_rule({ workspace = "4", monitor = monitorPhilips })
hl.workspace_rule({ workspace = "5", monitor = monitorDell })
hl.workspace_rule({ workspace = "6", monitor = monitorPhilips })
hl.workspace_rule({ workspace = "7", monitor = monitorDell })
hl.workspace_rule({ workspace = "8", monitor = monitorPhilips })
hl.workspace_rule({ workspace = "9", monitor = monitorDell })
hl.workspace_rule({ workspace = "10", monitor = monitorPhilips })
hl.workspace_rule({ workspace = "special:fun" })
hl.workspace_rule({ workspace = "special:chat" })

-- for streaming
hl.monitor({ output = "HEADLESS-2", mode = "2560x1600@60", position = "7000x0", scale = 1 })
hl.monitor({ output = "HEADLESS-3", mode = "2560x1600@60", position = "7000x0", scale = 1 })
hl.monitor({ output = "HEADLESS-4", mode = "2560x1600@60", position = "7000x0", scale = 1 })
hl.monitor({ output = "HEADLESS-5", mode = "2560x1600@60", position = "7000x0", scale = 1 })

for _, headless in ipairs({ "HEADLESS-2", "HEADLESS-3", "HEADLESS-4", "HEADLESS-5" }) do
    hl.workspace_rule({
        workspace = "11",
        monitor = headless,
        gaps_out = 0,
        gaps_in = 0,
        no_border = true,
        decorate = false,
    })
end

hl.window_rule({
    name = "steam-big-picture-to-streaming-workspace",
    match = { class = "^(steam)$", title = "^(Steam Big Picture Mode)$" },
    workspace = "11",
})

-- See https://wiki.hypr.land/Configuring/Keywords/
local terminal = "kitty"
local browser = "brave"
local musicPlayerClass = "Spotify"
local musicPlayer = "spotify-launcher"
local fileManager = "thunar"
-- --width/--height: force a fixed size — walker otherwise re-fits the window to
-- the result count on every keystroke, which makes the sidebar image zoom around
local menu = "walker --width 1100 --height 600"

-- Auto Start
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/kdeconnectd")
    hl.exec_cmd("kdeconnect-indicator")
    hl.exec_cmd("PATH=/usr/bin:$PATH hyprpanel")
    hl.exec_cmd("ly")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("thunar --daemon")
    hl.exec_cmd("fcitx5 -d --replace")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("clipse -listen")

    -- elephant: backend service for the walker launcher (apps + calc + menus providers)
    hl.exec_cmd("elephant")

    -- walker service: keeps GTK warm so opening the menu is instant instead of ~1s cold start
    hl.exec_cmd("walker --gapplication-service")

    hl.exec_cmd(musicPlayer, { workspace = "special:fun silent" })
    hl.exec_cmd("env GDK_SCALE=2 steam", { workspace = "special:fun silent" })
    hl.exec_cmd(browser, { workspace = "2 silent" })
    hl.exec_cmd(terminal, { workspace = "4 silent" })

    -- fix monitor loading bugs
    hl.exec_cmd("sleep 2 && hyprctl reload")

    -- for streaming
    hl.exec_cmd("sleep 5 && ~/.local/bin/sunshine-display-setup.sh && systemctl --user start app-dev.lizardbyte.app.Sunshine.service")

    -- for sharing screenshots to waydroid
    hl.exec_cmd("~/.config/hypr/scripts/waydroid-http-share.sh")

    -- wallpaper slideshow
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper_slideshow.sh")
end)

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,

        border_size = 1,

        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(1a139eff)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 3,

            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.config({
    -- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
    dwindle = {
        force_split = 2,

        preserve_split = true, -- You probably want this
    },

    -- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
    master = {
        new_status = "master",
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/
    misc = {
        force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Basics/Binds/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name = "elecom-co.--ltd.-elecom-opticalmouse",
    sensitivity = -0.7,
})

-- See https://wiki.hypr.land/Configuring/Keywords/
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local cmd = "CTRL"
local hyper = "SUPER + ALT"

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
-- Ctrl+Q closes the active window, except for protected classes (steam_app_*,
-- steam, gamescope, ThreeKingdoms) so a mistouch cannot kill a running game.
-- See bin/close-window.
hl.bind(cmd .. " + Q", hl.dsp.exec_cmd("close-window"))

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen_state({ internal = 1, client = 2 }))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + G", hl.dsp.window.float())
hl.bind(hyper .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + W", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + R", hl.dsp.layout("swapsplit")) -- dwindle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0 }))
hl.bind(hyper .. " + C", hl.dsp.exec_cmd([[hyprpicker -a -f hex && notify-send "Color Picked" "$(wl-paste)"]]))

-- clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(terminal .. " --class clipse -o font_size=10 -e clipse"))

-- screenshots (satty edits + auto-save; Copy puts the file path on the clipboard)
hl.bind(cmd .. " + SHIFT + 4", hl.dsp.exec_cmd("screenshot region"))
hl.bind(cmd .. " + SHIFT + 3", hl.dsp.exec_cmd("screenshot output"))

-- Ctrl+Shift+2: OCR a region to the clipboard and open it in Dialect for
-- editable live translation to zh-TW (Google Translate-style UX)
hl.bind(cmd .. " + SHIFT + 2", hl.dsp.exec_cmd("translate"))

-- Ctrl+Space: walker (apps + calc + translate — type a sentence to translate)
hl.bind(cmd .. " + SPACE", hl.dsp.exec_cmd(menu))

-- Esc closes the Dialect window (Dialect has no Esc binding of its own; a
-- non_consuming bind still passes the key through to the focused app, so Esc
-- behaves normally elsewhere)
hl.bind(
    "Escape",
    hl.dsp.exec_cmd([[hyprctl activewindow | grep -q 'class: app.drey.Dialect' && hyprctl dispatch killactive]]),
    { non_consuming = true }
)

-- Move focus with mainMod + arrow keys
hl.bind(cmd .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(cmd .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(cmd .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(cmd .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace - Fun
hl.bind(mainMod .. " + Q", hl.dsp.workspace.toggle_special("fun"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.move({ workspace = "special:fun" }))

-- Special workspace - Chat
hl.bind(mainMod .. " + C", hl.dsp.workspace.toggle_special("chat"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.move({ workspace = "special:chat" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m-1" }))

hl.bind("mouse:277", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("mouse:278", hl.dsp.focus({ workspace = "m-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- Keep the cursor inside Total War: THREE KINGDOMS while it is focused.
hl.window_rule({
    name = "confine-pointer-three-kingdoms",
    match = { class = "^(ThreeKingdoms)$" },
    confine_pointer = true,
})

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Spotify & Steam always open in special workspace (use regex anchors for exact match)
hl.window_rule({
    name = "music-player-to-fun",
    match = { class = "^(" .. musicPlayerClass .. ")$" },
    workspace = "special:fun silent",
})
hl.window_rule({
    name = "steam-to-fun",
    match = { class = "^(steam)$" },
    workspace = "special:fun silent",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- No border when only one window in workspace
hl.window_rule({
    name = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding = 0,
})
hl.window_rule({
    name = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding = 0,
})

-- --- Waydroid & Line ---
hl.window_rule({
    name = "waydroid",
    match = { class = "^(Waydroid.*|waydroid.*)$" },
    float = true,
    size = { 600, 1200 },
    center = true,
})
hl.window_rule({
    name = "waydroid-line-to-chat",
    match = { class = "^(waydroid.jp.naver.line.android)$" },
    workspace = "special:chat silent",
})

-- clipboard
hl.window_rule({
    name = "clipse",
    match = { class = "clipse" },
    float = true,
    size = { 900, 650 },
    center = true,
})

-- screenshot editor
hl.window_rule({
    name = "satty",
    match = { class = "^(com.gabm.satty)$" },
    float = true,
    center = true,
})

-- translation window (Dialect); width stays above the 680px compact-layout breakpoint
hl.window_rule({
    name = "dialect",
    match = { class = "^(app.drey.Dialect)$" },
    float = true,
    size = { 700, 350 },
    center = true,
})
