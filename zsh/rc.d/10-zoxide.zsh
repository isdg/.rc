# zoxide — frecency directory jumping. `z foo` jumps to the best match, `zi foo`
# picks via fzf. Builtin `cd` is left intact (no surprise remap).
#
# Back in both Brewfiles since Sep 2026, after a month deprecated. The Linux
# bootstrap still does not install it, which the guard below covers: a box
# without the binary skips the line rather than erroring at every shell start.
_zsh_cached zoxide "$commands[zoxide]" -- zoxide init zsh && source $REPLY
