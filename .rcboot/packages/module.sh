#!/usr/bin/env bash
# Module: the package set — darwin/Brewfile, or the distro package manager.

source "$RC_BOOT/packages/$RC_OS.sh"
step "install_packages_$RC_OS" "ensure_packages_$RC_OS"
