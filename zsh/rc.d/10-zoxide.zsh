# zoxide — frecency directory jumping. `z foo` jumps to the best match, `zi foo`
# picks via fzf. Builtin `cd` is left intact (no surprise remap).
#
# Back in the Brewfile since Sep 2026, after a month deprecated. Linux gets it
# from the distro where packaged (not yum), and the guard below covers a box
# without the binary: it skips the line rather than erroring at every start.
_zsh_cached zoxide "$commands[zoxide]" -- zoxide init zsh && source $REPLY
