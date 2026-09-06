-- Monitor layout and the workspace-to-monitor bindings that go with it.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

local vars = require("config.vars")

-- Original 10-bit + color managed config (uncomment to restore):
-- hl.monitor({ output = vars.monitorDell,    mode = "3840x2160@60", position = "0x0",    scale = 1.6, bitdepth = 10, cm = "dcip3" })
-- hl.monitor({ output = vars.monitorPhilips, mode = "3840x2160@60", position = "2400x0", scale = 1.6, bitdepth = 10, cm = "srgb" })

-- Plain 8-bit sRGB config for FH6/NVIDIA flicker workaround:
hl.monitor({ output = vars.monitorDell, mode = "3840x2160@60", position = "0x0", scale = 1.6 })
hl.monitor({ output = vars.monitorPhilips, mode = "3840x2160@60", position = "2400x0", scale = 1.6 })

-- "Smart gaps": no gaps when a workspace holds a single tiled or fullscreen window
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

-- Odd workspaces live on the Dell, even ones on the Philips.
for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = (i % 2 == 1) and vars.monitorDell or vars.monitorPhilips,
        default = i <= 2, -- 1 and 2 are the default workspace of their monitor
    })
end

hl.workspace_rule({ workspace = "special:fun" })
hl.workspace_rule({ workspace = "special:chat" })

-- Sunshine game streaming.
--
-- The headless output is created at runtime by ~/.local/bin/sunshine-display-setup.sh,
-- and Hyprland names headless outputs in creation order, so the name is not known
-- ahead of time: a cold boot gets HEADLESS-1, re-creating one later in the same
-- session gets the next free number. Static `HEADLESS-2`..`HEADLESS-5` rules used to
-- cover this by guessing, which missed HEADLESS-1 on every boot and left the output
-- at its 1920x1080 @ scale 2 default.
--
-- A workspace can only be bound to one monitor anyway (repeating the rule per output
-- just overwrites it), so bind both the mode and the workspace when the output shows up.
hl.on("monitor.added", function(monitor)
    if not monitor.name:match("^HEADLESS%-") then
        return
    end

    hl.monitor({ output = monitor.name, mode = "2560x1600@60", position = "7000x0", scale = 1 })
    hl.workspace_rule({
        workspace = vars.streamingWorkspace,
        monitor = monitor.name,
        gaps_out = 0,
        gaps_in = 0,
        no_border = true,
        decorate = false,
    })
    monitor:set_workspace(vars.streamingWorkspace)
end)
