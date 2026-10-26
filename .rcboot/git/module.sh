#!/usr/bin/env bash
# Module: git — .gitconfig, then commit signing, which writes into the
# ~/.gitconfig.local it includes.

link git/.gitconfig "$HOME/.gitconfig"
link git/commit-title.sh "$HOME/.config/git/commit-title.sh"

source "$RC_BOOT/git/signing.sh"
step configure_git_signing ensure_git_signing
