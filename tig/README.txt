
TIG SETUP
=========

1. Link tig configuration
--------------------------

Create a symlink from the repo tig configuration to your home directory:

    > ln -sf "$HOME/.dotfiles/tig/.tigrc" \
          "$HOME/.tigrc"

-------------------------------------------------------------------------------
2. Key bindings
---------------

main view:

    O   — checkout the selected commit
              git checkout %(commit)


-------------------------------------------------------------------------------
3. Theme
--------

.tigrc sources tig/theme-active.tigrc, a gitignored symlink to
theme-{dark,light}.tigrc that toggle_theme.sh flips alongside Ghostty, k9s
and tmux. Only the cursor line differs between the two: ANSI blue is a pale
#89b4fa under the dark palette, so the light theme's white-on-blue bar sits
at 2.11:1 contrast there and is unreadable.

tig reads its configuration at startup only, so an already-open tig keeps the
colours it started with. The source is -q: with no symlink yet, tig stays
quiet and .tigrc's own fallback cursor applies.
