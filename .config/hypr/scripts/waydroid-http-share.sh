#!/bin/bash

if ! command -v waydroid &>/dev/null; then
    exit 0
fi

WATCH_DIR="$HOME/Pictures/Screenshots"
# waydroid0 bridge gateway — the host address as seen from inside the container.
# This is waydroid's default; override if you changed its network config.
HOST_IP="192.168.240.1"
PORT="8000"

if ! pgrep -f "python -m http.server $PORT" >/dev/null; then
    echo "Starting server..."
    cd "$WATCH_DIR" && python -m http.server "$PORT" &
fi

echo "Start monitoring screenshots..."

LAST_FILE=""
LAST_TIME=0

# paru -S inotify-tools
inotifywait -m -e close_write --format "%f" "$WATCH_DIR" | while read FILENAME; do
    CUR_TIME=$(date +%s)

    TIME_DIFF=$((CUR_TIME - LAST_TIME))

    if [ "$FILENAME" == "$LAST_FILE" ] && [ "$TIME_DIFF" -lt 2 ]; then
        continue
    fi

    echo "[New screenshots found] $FILENAME"

    LAST_FILE="$FILENAME"
    LAST_TIME="$CUR_TIME"

    URL_FILE=$(echo "$FILENAME" | sed 's/ /%20/g')
    TARGET_URL="http://$HOST_IP:$PORT/$URL_FILE"

    echo "Commanding Waydroid to open the file: $TARGET_URL"

    sudo waydroid shell -- am start --user 0 -a android.intent.action.VIEW -d "$TARGET_URL"
done
