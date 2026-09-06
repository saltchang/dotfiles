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

    -- Virtual outputs created for Sunshine game streaming
    headlessMonitors = { "HEADLESS-2", "HEADLESS-3", "HEADLESS-4", "HEADLESS-5" },
    streamingWorkspace = "11",
}
