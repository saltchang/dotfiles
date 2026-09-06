-- Window rules.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- Order matters: rules are processed top to bottom and the LAST match wins.
-- The order here is the same as in the pre-Lua hyprland.conf.

local vars = require("config.vars")

-- Steam Big Picture goes to the streaming workspace on the headless outputs
hl.window_rule({
    name = "steam-big-picture-to-streaming-workspace",
    match = { class = "^(steam)$", title = "^(Steam Big Picture Mode)$" },
    workspace = vars.streamingWorkspace,
})

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
    match = { class = "^(" .. vars.musicPlayerClass .. ")$" },
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
