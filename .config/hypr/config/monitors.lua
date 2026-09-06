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

-- for streaming
for _, output in ipairs(vars.headlessMonitors) do
    hl.monitor({ output = output, mode = "2560x1600@60", position = "7000x0", scale = 1 })
    hl.workspace_rule({
        workspace = vars.streamingWorkspace,
        monitor = output,
        gaps_out = 0,
        gaps_in = 0,
        no_border = true,
        decorate = false,
    })
end
