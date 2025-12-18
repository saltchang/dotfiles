#!/bin/bash

BIN_PATH_DIR="$HOME/.local/bin"
mkdir -p "$BIN_PATH_DIR"
curl -s https://cht.sh/:cht.sh >"$BIN_PATH_DIR/cht.sh"
chmod +x "$BIN_PATH_DIR/cht.sh"
