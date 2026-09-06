-- https://wiki.hypr.land/Configuring/
--
-- Lua config format, required from Hyprland 0.57 (hyprlang .conf is dropped there).
-- API reference: /usr/share/hypr/stubs/hl.meta.lua
--
-- Modules live in config/ and are resolved relative to this file. Shared values
-- (programs, modifiers, monitor descriptions) live in config/vars.lua and are
-- required directly by whichever module needs them.
--
-- Load order matters: env has to be set before the display server initializes,
-- and window rules are applied top to bottom with the last match winning.

require("config.env")
require("config.monitors")
require("config.autostart")
require("config.look-and-feel")
require("config.input")
require("config.binds")
require("config.window-rules")
