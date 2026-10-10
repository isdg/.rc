#!/usr/bin/env bash
# Module: local — ~/.zshrc and the fragment that sources ~/.zshrc.local, this
# machine's own settings. Level 0, so every level keeps them.

link zsh/.zshrc "$HOME/.zshrc"
fragment zsh/rc.d/22-local.zsh
