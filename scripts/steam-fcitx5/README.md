# Steam + fcitx5 (Rime) on Hyprland

Getting CJK input to work in the Steam client UI. Arch Linux, Hyprland, fcitx5 + Rime, Steam installed from the `steam` package.

## How the pieces fit

1. **Steam is launched through `bin/steam-ime`.** Both the Hyprland autostart (`.config/hypr/config/autostart.lua`) and `~/.local/share/applications/steam.desktop` launch it. `setup-arch.sh` generates the desktop file. The wrapper runs `build.sh --check`. If the check fails, it rebuilds the module and checks again. If the module is good, it launches Steam with `GTK_IM_MODULE=fcitx GTK_IM_MODULE_FILE=~/.local/share/steam-fcitx5/immodules.cache`. If it still fails, it launches plain Steam and shows a notification.
2. **`build.sh` makes the host `im-fcitx5.so` loadable inside the Steam runtime.** `steamwebhelper` runs in the steamrt3c pressure-vessel container, which ships glib 2.66 and no fcitx GTK module. The script:
   - copies the host `im-fcitx5.so` and `libFcitx5GClient.so.2` into `~/.local/share/steam-fcitx5/`
   - adds `glib-shim.c` (newer glib symbols reimplemented on top of 2.66 ones) via patchelf
   - renames `g_module_check_init` so GModule skips its glib version check
   - checks that every undefined symbol exists in the libraries the container will actually load

   A build that fails the check is discarded, and the previous build is kept.
3. **The Hyprland hook in `.config/hypr/config/window-rules.lua` pins the fcitx candidate window.** For XWayland apps, Hyprland treats the candidate window as a managed float. It moves the window to the monitor's regular workspace on every move or resize, so Steam, which lives in `special:fun`, covers it after the first key. A pinned window stays on top. A window rule with `pin = true` did not apply, which is why this is an event hook.

## Approaches that do not work

- `GTK_IM_MODULE=fcitx` on its own: the container has no fcitx module, so GTK falls back to its built-in input.
- `GTK_IM_MODULE=xim`: Chromium/CEF over XIM lets the second key of a composition bypass the IME. Typing `5j/ jp6` gives "j正文". Setting fcitx `UseOnTheSpot` does not help.
- Setting `GTK_IM_MODULE` globally: fcitx recommends against it on Wayland. Keep it Steam-only.

## Troubleshooting

- Run `scripts/steam-fcitx5/build.sh --check`. The error lists any missing symbols. For a new glib function, add a wrapper to `glib-shim.c` and run `build.sh` again.
- To confirm the module loaded, find the `steamwebhelper -nocrashdialog` process and run `grep steam-fcitx5 /proc/<pid>/maps`.
- To test inside the container: `nsenter -t <pid> -U -m --preserve-credentials -- /usr/lib/x86_64-linux-gnu/libgtk-3-0/gtk-query-immodules-3.0 ~/.local/share/steam-fcitx5/im-fcitx5.so`
- To reproduce without Steam, open `GDK_BACKEND=x11 GTK_IM_MODULE=fcitx zenity --entry`, send keys with `hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "", key = "5" })'`, and take a screenshot with `grim`.
- Restarting fcitx5 while Steam is running crashes `steamwebhelper`. Restart Steam after restarting fcitx5.
- If Steam segfaults in `vgui2_s.so` right after an NVIDIA upgrade, the cause is a driver/library mismatch (`nvidia-smi` reports it). Reboot.
- Games running inside gamescope are a separate problem: gamescope runs a nested X server that fcitx cannot reach.
