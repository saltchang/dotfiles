#!/bin/bash

BIN_PATH_DIR="$HOME/.local/bin"
mkdir -p "$BIN_PATH_DIR"
if curl -fsSL https://cht.sh/:cht.sh -o "$BIN_PATH_DIR/cht.sh" && [ -s "$BIN_PATH_DIR/cht.sh" ]; then
    chmod +x "$BIN_PATH_DIR/cht.sh"
else
    echo "Failed to download cht.sh"
    rm -f "$BIN_PATH_DIR/cht.sh"
fi
