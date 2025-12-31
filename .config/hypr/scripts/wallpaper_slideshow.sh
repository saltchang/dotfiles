#!/bin/bash

DIR="$HOME/.config/hypr/wallpapers/"

INTERVAL=30

while true; do
    RANDOM_IMG=$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

    # --transition-type: simple, grow, wave, outer, any
    awww img "$RANDOM_IMG" --transition-type any --transition-step 120 --transition-fps 60

    sleep $INTERVAL
done
