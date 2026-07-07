#!/bin/bash

# Zed editor configuration setup script
# Creates symlinks from ~/.config/zed/ to this repo's zed/ (any dir name)

DOTFILES_ZED="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ZED="$HOME/.config/zed"

echo "Setting up Zed configuration..."

# Create ~/.config/zed if it doesn't exist
mkdir -p "$CONFIG_ZED"

# Backup and symlink settings.json
if [ -f "$CONFIG_ZED/settings.json" ] && [ ! -L "$CONFIG_ZED/settings.json" ]; then
    mv "$CONFIG_ZED/settings.json" "$CONFIG_ZED/settings.json.backup"
    echo "Backed up existing settings.json"
fi
ln -sf "$DOTFILES_ZED/settings.json" "$CONFIG_ZED/settings.json"
echo "Linked settings.json"

# Backup and symlink keymap.json
if [ -f "$CONFIG_ZED/keymap.json" ] && [ ! -L "$CONFIG_ZED/keymap.json" ]; then
    mv "$CONFIG_ZED/keymap.json" "$CONFIG_ZED/keymap.json.backup"
    echo "Backed up existing keymap.json"
fi
ln -sf "$DOTFILES_ZED/keymap.json" "$CONFIG_ZED/keymap.json"
echo "Linked keymap.json"

# Backup and symlink themes directory
if [ -d "$CONFIG_ZED/themes" ] && [ ! -L "$CONFIG_ZED/themes" ]; then
    mv "$CONFIG_ZED/themes" "$CONFIG_ZED/themes.backup"
    echo "Backed up existing themes directory"
fi
ln -sf "$DOTFILES_ZED/themes" "$CONFIG_ZED/themes"
echo "Linked themes/"

echo ""
echo "Done! Zed configuration linked:"
ls -la "$CONFIG_ZED" | grep -E "(settings|keymap|themes)"
