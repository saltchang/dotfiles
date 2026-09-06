-- Environment variables and the driver workarounds that have to be in place
-- before the display server initializes.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- -- NVIDIA Settings --
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- fcitx5 input method
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- Cursor
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

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
