-- Processes started once per Hyprland session (the old `exec-once`).
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local vars = require("config.vars")

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

    hl.exec_cmd(vars.musicPlayer, { workspace = "special:fun silent" })
    hl.exec_cmd("env GDK_SCALE=2 steam", { workspace = "special:fun silent" })
    hl.exec_cmd(vars.browser, { workspace = "2 silent" })
    hl.exec_cmd(vars.terminal, { workspace = "4 silent" })

    -- fix monitor loading bugs
    hl.exec_cmd("sleep 2 && hyprctl reload")

    -- for streaming
    hl.exec_cmd(
        "sleep 5 && ~/.local/bin/sunshine-display-setup.sh && systemctl --user start app-dev.lizardbyte.app.Sunshine.service"
    )

    -- for sharing screenshots to waydroid
    hl.exec_cmd("~/.config/hypr/scripts/waydroid-http-share.sh")

    -- wallpaper slideshow
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper_slideshow.sh")
end)
