#!/usr/bin/env bash
# Module: hr.

source "$RC_BOOT/hr/hr.sh"
step install_hr ensure_hr

seed hr/config.toml "$HOME/.hr/config.toml"
