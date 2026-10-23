#!/usr/bin/env bash
# Module: oui.

source "$RC_BOOT/oui/oui.sh"
step install_oui ensure_oui

link oui/ouirc "$HOME/.oui/config"
