#!/usr/bin/env bash
# Create a headless display for Sunshine streaming and write its name to sunshine.conf.
# Run once when Hyprland starts (config/autostart.lua).
#
# Why this script is needed:
#   `hyprctl output create headless <name>` returns ok without creating a display.
#   Hyprland assigns names in creation order: HEADLESS-1 after a cold boot,
#   then HEADLESS-2, -3, etc. for additional displays in the same session.
#   Discover the assigned name after creation and write it to Sunshine's config.

set -euo pipefail

# Resolution, position, and workspace bindings are defined in config/monitors.lua.
# The `monitor.added` handler applies them on creation without needing the name in advance.
# Avoid `hyprctl keyword` overrides here: reload discards them, and they duplicate the config.
# To change the resolution, edit config/monitors.lua.

CONF="$HOME/.config/sunshine/sunshine.conf"

log() { echo "[sunshine-display] $*"; }

# Reuse an existing headless display to avoid creating more numbered displays.
existing=$(hyprctl -j monitors all | python3 -c '
import json, sys
print(next((m["name"] for m in json.load(sys.stdin)
            if m["name"].startswith("HEADLESS")), ""))
')

if [[ -n "$existing" ]]; then
    name="$existing"
    log "沿用既有的 $name"
else
    hyprctl output create headless >/dev/null
    sleep 1
    name=$(hyprctl -j monitors all | python3 -c '
import json, sys
print(next((m["name"] for m in json.load(sys.stdin)
            if m["name"].startswith("HEADLESS")), ""))
')
    if [[ -z "$name" ]]; then
        log "錯誤：headless 螢幕建立失敗" >&2
        exit 1
    fi
    log "已建立 $name"
fi

# Verify that the monitor.added handler in config/monitors.lua applied the settings.
geom=$(hyprctl -j monitors all | python3 -c "
import json, sys
m = next(m for m in json.load(sys.stdin) if m['name'] == '$name')
print(f\"{m['width']}x{m['height']} scale={m['scale']}\")
")
log "$name: $geom"
if [[ "$geom" != *"scale=1.0"* ]]; then
    log "警告：$name 沒套到 config/monitors.lua 的 monitor.added 設定" >&2
fi

# Update output_name in sunshine.conf, or append it if missing.
mkdir -p "$(dirname "$CONF")"
touch "$CONF"
if grep -q '^output_name' "$CONF"; then
    sed -i "s|^output_name.*|output_name = $name|" "$CONF"
else
    echo "output_name = $name" >>"$CONF"
fi
log "sunshine.conf output_name = $name"
