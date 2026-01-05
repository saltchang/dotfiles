#!/bin/bash

# ===> Colors ======================================================================================
GREEN="\033[32m"
ERROR="\033[31m"
NC="\033[0m"
# ==================================================================================================

# ===> Parse Arguments =============================================================================
for i in "$@"; do
    case $i in
    -n=* | --name=*)
        CONFIG_NAME="${i#*=}"
        shift
        ;;
    -d=* | --config-dir=*)
        CONFIG_DIR_NAME="${i#*=}"
        shift
        ;;
    --* | -*)
        printf '%s\n' "Error: Unknown option $i"
        exit 1
        ;;
    *) ;;
    esac
done
# ==================================================================================================

printf '\n'
printf '%s\n' "Setting up ${CONFIG_NAME}..."

SOURCE_CONFIG_DIR="$(pwd)/.config/${CONFIG_DIR_NAME}"

[ ! -e "$SOURCE_CONFIG_DIR" ] && printf '%b%s%b\n' "$ERROR" "Source config not found: \"$SOURCE_CONFIG_DIR\". You may be in the wrong directory >>> Exit 1" "$NC" && exit 1

TARGET_CONFIG_ROOT_DIR="$HOME/.config"

[ ! -d "$TARGET_CONFIG_ROOT_DIR" ] && mkdir -p "$TARGET_CONFIG_ROOT_DIR" && printf '%b%s%b\n' "$GREEN" "Created new directory: $TARGET_CONFIG_ROOT_DIR" "$NC"

TARGET_CONFIG_DIR="$TARGET_CONFIG_ROOT_DIR/${CONFIG_DIR_NAME}"

printf '%s\n' "Check and remove old files and directories..."
printf '\n'

if [ -e "$TARGET_CONFIG_DIR" ] || [ -L "$TARGET_CONFIG_DIR" ]; then
    rm -rf "$TARGET_CONFIG_DIR" 2>/dev/null && printf '%b%s%b\n' "$GREEN" "Removed old config files and directories" "$NC"
fi

printf '\n'
printf '%s\n' "Check and create new symbolic link..."
printf '\n'

ln -s "$SOURCE_CONFIG_DIR" "$TARGET_CONFIG_DIR" && printf '%b%s%b\n' "$GREEN" "Created a new symbolic link from $TARGET_CONFIG_DIR to $SOURCE_CONFIG_DIR" "$NC"

printf '\n'

printf '%s\n' "Successfully set up ${CONFIG_NAME}."
