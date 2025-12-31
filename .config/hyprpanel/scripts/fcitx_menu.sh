#!/bin/bash

TXT_CN="注音"
TXT_EN="English"
TXT_DIVIDER="------------------"
TXT_CONFIG="> Config"
TXT_RELOAD="> Reload"
TXT_RESTART="> Restart"
TXT_EXIT="> Exit"

STATE=$(fcitx5-remote)

if [[ "$STATE" == "2" ]]; then
    OPTION_CN="[*] $TXT_CN"
    OPTION_EN="[ ] $TXT_EN"
else
    OPTION_CN="[ ] $TXT_CN"
    OPTION_EN="[*] $TXT_EN"
fi

OPTIONS="$OPTION_CN\n$OPTION_EN\n$TXT_DIVIDER\n$TXT_CONFIG\n$TXT_RELOAD\n$TXT_RESTART\n$TXT_EXIT"

SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Fcitx5" -theme-str 'window {width: 11em;} listview {lines: 7;}')

case "$SELECTED" in
"$OPTION_CN")
    if [[ "$STATE" == "1" ]]; then
        fcitx5-remote -t
    fi
    ;;
"$OPTION_EN")
    if [[ "$STATE" == "2" ]]; then
        fcitx5-remote -t
    fi
    ;;
"$TXT_CONFIG")
    fcitx5-configtool &
    ;;
"$TXT_RELOAD")
    fcitx5-remote -r
    ;;
"$TXT_RESTART")
    killall fcitx5
    sleep 0.5
    fcitx5 -d >/dev/null 2>&1 &
    ;;
"$TXT_EXIT")
    killall fcitx5
    ;;
"$TXT_DIVIDER")
    exit 0
    ;;
*)
    exit 0
    ;;
esac
