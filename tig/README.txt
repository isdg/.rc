TIG SETUP
=========

Config for tig, the text-mode interface for git: key bindings, and a theme
that follows the light/dark toggle with the rest of the terminal tools.


-------------------------------------------------------------------------------
LINK
-------------------------------------------------------------------------------

Create a symlink from the repo tig configuration to your home directory:

    > ln -sf "$HOME/.rc/tig/.tigrc" "$HOME/.tigrc"

-------------------------------------------------------------------------------
KEY BINDINGS
-------------------------------------------------------------------------------

See keys.txt in this folder: every binding from .tigrc, the built-in keys
they sit next to, which defaults they shadow, and what is still free.

The live answer always comes from tig itself: press h for the help view,
then <Enter> on a collapsed "[+] ... bindings" line to expand that keymap.

-------------------------------------------------------------------------------
THEME
-------------------------------------------------------------------------------

.tigrc sources tig/theme-active.tigrc, a gitignored symlink to
theme-{dark,light}.tigrc that toggle_theme.sh flips alongside Ghostty, k9s
and tmux. What differs between the two modes is the two blue areas: the
cursor line and the focused view's title bar. ANSI blue is a pale #89b4fa
under the dark palette, where the light theme's white-on-blue sits at
2.11:1 on the cursor and 1.06:1 on the title bar, both unreadable. Dark
uses color24 (#005f87) for both, one selection blue for the whole UI.

tig reads its configuration at startup only, so an already-open tig keeps
the colours it started with. The source is -q: with no symlink yet, tig
stays quiet and .tigrc's own fallback cursor applies.
