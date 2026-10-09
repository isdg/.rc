#!/usr/bin/env bash
# Module: GUI apps via Homebrew cask (Darwin only).

[ "$RC_OS" = darwin ] || return 0

source "$RC_BOOT/apps/gui_apps.sh"
step install_gui_apps_darwin ensure_gui_apps_darwin
