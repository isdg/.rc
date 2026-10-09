#!/usr/bin/env bash
# Module: argocd CLI (Linux only — Darwin takes it from the Brewfile).

[ "$RC_OS" = linux ] || return 0

source "$RC_BOOT/argocd/argocd_linux.sh"
step install_argocd_linux ensure_argocd_linux
