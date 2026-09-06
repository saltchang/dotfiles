-- Keybindings.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more

local vars = require("config.vars")

local mainMod = vars.mainMod
local cmd = vars.cmd
local hyper = vars.hyper

-- Ctrl+Q closes the active window, except for protected classes (steam_app_*,
-- steam, gamescope, ThreeKingdoms) so a mistouch cannot kill a running game.
-- See bin/close-window.
hl.bind(cmd .. " + Q", hl.dsp.exec_cmd("close-window"))

-- Apps
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(vars.terminal))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(vars.fileManager))
hl.bind(hyper .. " + SPACE", hl.dsp.exec_cmd(vars.menu))
-- Ctrl+Space: walker (apps + calc + translate — type a sentence to translate)
hl.bind(cmd .. " + SPACE", hl.dsp.exec_cmd(vars.menu))

-- Window state.
-- fullscreen_state defaults to action = "set", so without an explicit "toggle"
-- these only ever enter the state and never leave it again.
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen_state({ action = "toggle", internal = 1, client = 2 }))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.fullscreen_state({ action = "toggle", internal = 0, client = 2 }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen_state({ action = "toggle", internal = 2, client = 0 }))
hl.bind(mainMod .. " + G", hl.dsp.window.float())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + W", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + R", hl.dsp.layout("swapsplit")) -- dwindle

-- Color picker
hl.bind(hyper .. " + C", hl.dsp.exec_cmd([[hyprpicker -a -f hex && notify-send "Color Picked" "$(wl-paste)"]]))

-- clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(vars.terminal .. " --class clipse -o font_size=10 -e clipse"))

-- screenshots (satty edits + auto-save; Copy puts the file path on the clipboard)
hl.bind(cmd .. " + SHIFT + 4", hl.dsp.exec_cmd("screenshot region"))
hl.bind(cmd .. " + SHIFT + 3", hl.dsp.exec_cmd("screenshot output"))

-- Ctrl+Shift+2: OCR a region to the clipboard and open it in Dialect for
-- editable live translation to zh-TW (Google Translate-style UX)
hl.bind(cmd .. " + SHIFT + 2", hl.dsp.exec_cmd("translate"))

-- Esc closes the Dialect window (Dialect has no Esc binding of its own; a
-- non_consuming bind still passes the key through to the focused app, so Esc
-- behaves normally elsewhere). Done in-process rather than by shelling out to
-- hyprctl, which is both faster and immune to hyprctl's dispatch syntax.
hl.bind("Escape", function()
    local w = hl.get_active_window()
    if w and w.class == "app.drey.Dialect" then
        hl.dispatch(hl.dsp.window.close())
    end
end, { non_consuming = true })

-- Move focus with cmd + arrow keys
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

-- Scroll through existing workspaces with mainMod + scroll, or the mouse side buttons
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("mouse:277", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("mouse:278", hl.dsp.focus({ workspace = "m-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
local mediaKeys = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), mediaKeys)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), mediaKeys)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), mediaKeys)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), mediaKeys)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), mediaKeys)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), mediaKeys)

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
