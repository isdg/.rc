#!/usr/bin/env bash
# The one place colours are defined.
#
# To change a colour: edit it here, run `bash theme/generate.sh`, review the
# diff. theme/generate.sh renders theme/templates/*.tpl into the per-tool files.
#
# Call `isg_palette dark` or `isg_palette light` to set the ISG_* variables.
# Nothing is `readonly` on purpose — generate.sh calls it once per mode in one
# process. Must stay bash-3.2 clean: /bin/bash on macOS is 3.2.57.
#
# Two kinds of slot:
#
#   ISG_ANSI_0..15  The terminal's 16-colour ramp. Ghostty publishes it to every
#                   process, so it is what tig, LS_COLORS, GREP_COLORS, git,
#                   delta, less, fzf and the zsh prompt resolve `blue` / `red` /
#                   `green` to — the only colour language every tool here speaks.
#   ISG_*           Truecolour roles, for tools that accept hex.
#
# A few slots hold an ANSI *name* rather than hex (ISG_TIG_*, ISG_FZF_PROMPT, and
# ISG_SEL_FG in light mode). Not an oversight: tig accepts no hex at all, and fzf
# takes names for those fields. They resolve through the ramp above.
#
# The ANSI values began as Ghostty's bundled "Catppuccin Mocha" / "Catppuccin
# Latte" and are byte-for-byte unchanged, but those themes are no longer
# referenced. They set only these 16 slots plus background, foreground,
# cursor-color, cursor-text and selection-{background,foreground} — all six of
# which we already overrode — so the dependency bought 16 numbers we could
# neither see nor tune. Retuning one is a one-line edit now, but it is a
# *visible* change: it moves ls, git, tig, fzf and the prompt at once.

isg_palette() {
    case "$1" in
    dark)
        ISG_MODE='dark'
        # ── ANSI ramp ──
        ISG_ANSI_0='#45475a';  ISG_ANSI_8='#585b70'
        ISG_ANSI_1='#f38ba8';  ISG_ANSI_9='#f37799'
        ISG_ANSI_2='#a6e3a1';  ISG_ANSI_10='#89d88b'
        ISG_ANSI_3='#f9e2af';  ISG_ANSI_11='#ebd391'
        ISG_ANSI_4='#89b4fa';  ISG_ANSI_12='#74a8fc'
        ISG_ANSI_5='#f5c2e7';  ISG_ANSI_13='#f2aede'
        ISG_ANSI_6='#94e2d5';  ISG_ANSI_14='#6bd7ca'
        ISG_ANSI_7='#a6adc8';  ISG_ANSI_15='#bac2de'

        # ── surfaces ── match nvim colors/vs_dark.vim `hi Normal`
        ISG_BG='#2f2f2f'
        ISG_FG='#d4d4d4'
        ISG_CURSOR='#cccccc'

        # ── selection ── nvim colors/vs_dark.vim `hi Search`, so a picker's
        # selected row matches the buffer underneath it
        ISG_SEL_BG='#264f78'
        ISG_SEL_FG='#d4d4d4'

        # ── tmux status bar / pane borders ──
        ISG_UI_FG='#c0c0c0'
        ISG_UI_FG_DIM='#a6a6a6'
        ISG_UI_FG_STRONG='#ffffff'
        ISG_UI_MSG='#e6e6e6'
        ISG_BORDER='#444444'
        ISG_BORDER_ACTIVE='#777777'

        # ── name-only tokens ──
        ISG_FZF_PROMPT='blue'
        # color24 (#005f87) is nearest256(ISG_SEL_BG) — a 256-palette stand-in,
        # because tig takes no hex. Indices 16-255 keep their xterm values (we
        # remap only 0-15), so 24 is stable. ANSI blue is a pale #89b4fa here:
        # white on it is 2.11:1, while `default` on color24 is 4.74:1.
        ISG_TIG_SEL_FG='default'
        ISG_TIG_SEL_BG='color24'
        ;;
    light)
        ISG_MODE='light'
        # ── ANSI ramp ──
        ISG_ANSI_0='#5c5f77';  ISG_ANSI_8='#6c6f85'
        ISG_ANSI_1='#d20f39';  ISG_ANSI_9='#de293e'
        ISG_ANSI_2='#40a02b';  ISG_ANSI_10='#49af3d'
        ISG_ANSI_3='#df8e1d';  ISG_ANSI_11='#eea02d'
        ISG_ANSI_4='#1e66f5';  ISG_ANSI_12='#456eff'
        ISG_ANSI_5='#ea76cb';  ISG_ANSI_13='#fe85d8'
        ISG_ANSI_6='#179299';  ISG_ANSI_14='#2d9fa8'
        ISG_ANSI_7='#acb0be';  ISG_ANSI_15='#bcc0cc'

        # ── surfaces ── match nvim colors/vs_light.vim `hi Normal`
        ISG_BG='#fafafa'
        ISG_FG='#000000'
        ISG_CURSOR='#444444'

        # ── selection ── nvim colors/vs_light.vim `hi Search`
        ISG_SEL_BG='#dce7f2'
        # A name, not hex: on this pale selection the terminal's bright-black is
        # the readable choice, and it tracks the ramp if that is ever retuned.
        ISG_SEL_FG='bright-black'

        # ── tmux status bar / pane borders ──
        ISG_UI_FG='#555555'
        ISG_UI_FG_DIM='#777777'
        ISG_UI_FG_STRONG='#000000'
        ISG_UI_MSG='#333333'
        ISG_BORDER='#cccccc'
        ISG_BORDER_ACTIVE='#888888'

        # ── name-only tokens ──
        ISG_FZF_PROMPT='black'
        # ANSI blue is a strong #1e66f5 here, so white bold on it reads at
        # 4.91:1 and needs no 256-index stand-in.
        ISG_TIG_SEL_FG='white'
        ISG_TIG_SEL_BG='blue'
        ;;
    *)
        printf 'palette: unknown mode %s (want dark|light)\n' "$1" >&2
        return 1
        ;;
    esac
}
