#!/usr/bin/env bash
# 建立給 Sunshine 串流用的 headless 虛擬螢幕，並把螢幕名稱寫進 sunshine.conf。
# 在 Hyprland 啟動時跑一次（config/autostart.lua）。
#
# 為什麼需要這支腳本：
#   `hyprctl output create headless <name>` 指定名稱無效（會回 ok 但不建立），
#   螢幕名稱由 Hyprland 依建立順序決定（冷開機是 HEADLESS-1，同一個 session 內
#   再建一個才會是 HEADLESS-2、-3…），所以只能建完再回頭抓名字，
#   動態寫進 Sunshine 設定。

set -euo pipefail

# 注意：解析度、位置、workspace 綁定都在 config/monitors.lua 裡，
# 由 `monitor.added` 事件在螢幕建立當下套用（不必事先知道名稱）。
# 不要在這裡用 hyprctl keyword 重設 —— 那會被 hyprctl reload 洗掉，
# 而且會變成兩個真相來源。改解析度請改 config/monitors.lua。

CONF="$HOME/.config/sunshine/sunshine.conf"

log() { echo "[sunshine-display] $*"; }

# 已經有 headless 就沿用，避免重複建立讓編號一直長
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

# 確認 config/monitors.lua 的 monitor.added handler 有套用到
geom=$(hyprctl -j monitors all | python3 -c "
import json, sys
m = next(m for m in json.load(sys.stdin) if m['name'] == '$name')
print(f\"{m['width']}x{m['height']} scale={m['scale']}\")
")
log "$name: $geom"
if [[ "$geom" != *"scale=1.0"* ]]; then
    log "警告：$name 沒套到 config/monitors.lua 的 monitor.added 設定" >&2
fi

# 把螢幕名稱寫進 sunshine.conf（有就換掉，沒有就補上）
mkdir -p "$(dirname "$CONF")"
touch "$CONF"
if grep -q '^output_name' "$CONF"; then
    sed -i "s|^output_name.*|output_name = $name|" "$CONF"
else
    echo "output_name = $name" >>"$CONF"
fi
log "sunshine.conf output_name = $name"
