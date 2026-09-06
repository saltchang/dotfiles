-- Values shared across the config modules. Required directly by each module
-- that needs them, so there is no implicit load-order dependency between them.

return {
    -- Programs
    terminal = "kitty",
    browser = "brave",
    musicPlayer = "spotify-launcher",
    musicPlayerClass = "Spotify",
    fileManager = "thunar",
    -- --width/--height: force a fixed size — walker otherwise re-fits the window to
    -- the result count on every keystroke, which makes the sidebar image zoom around
    menu = "walker --width 1100 --height 600",

    -- Modifiers
    mainMod = "SUPER", -- Sets "Windows" key as main modifier
    cmd = "CTRL",
    hyper = "SUPER + ALT",

    -- Monitors, by EDID description so they follow the physical panel rather
    -- than whichever DP-N the kernel happened to hand out this boot.
    monitorDell = "desc:Dell Inc. DELL U2723QE",
    monitorPhilips = "desc:Philips Consumer Electronics Company PHL 276E8V",

    -- Workspace the Sunshine streaming headless output is bound to.
    -- The output's own name is discovered at runtime; see config/monitors.lua.
    streamingWorkspace = "11",
}
