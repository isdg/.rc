#!/usr/bin/env bash
# Module: colima — the template new profiles are created from.

[ "$RC_OS" = darwin ] || return 0

# Colima rewrites its yaml on start, so seed rather than link. A profile that
# already exists keeps its own colima.yaml; edit that one, then restart.
seed colima/default.yaml "$HOME/.colima/_templates/default.yaml"
