#!/usr/bin/env bash
# Module: plc.

source "$RC_BOOT/plc/plc.sh"
step install_plc ensure_plc

seed plc/plcrc "$HOME/.plcrc"
