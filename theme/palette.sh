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

        # ── UI chrome (k9s) ──
        # The two k9s skins were hand-tuned independently and are not symmetric,
        # so several of these pairs are genuinely different roles rather than one
        # role in two shades — see the light branch for the contrast.
        ISG_FG_DIM='#888888'            # info labels, completed, yaml colons
        ISG_BG_ALT='#252526'            # dialogs, panels raised off the body
        ISG_BORDER_UI='#454545'
        ISG_ON_ACCENT='#ffffff'         # text on a filled accent (buttons, cursor)
        ISG_CRUMB_FG="$ISG_BG"          # crumbs invert: body colour on accent
        # Four near-identical blues, kept apart because that is what the skins do
        # today. Collapsing them is the obvious next simplification, but it moves
        # pixels, so it is not part of this refactor.
        ISG_ACCENT='#569cd6'            # logo, labels, menu keys, focus, headers
        ISG_ACCENT_DEEP='#569cd6'       # suggestions, crumbs, xray graphics
        ISG_ACCENT_BRIGHT='#87cfff'
        ISG_BUTTON_BG='#0078d4'
        ISG_BUTTON_FOCUS_BG='#007acc'
        ISG_TABLE_CURSOR_BG='#264f78'
        ISG_XRAY_CURSOR='#264f78'
        ISG_TITLE_HL='#87cfff'
        # Syntax-ish roles, from nvim colors/vs_dark.vim
        ISG_STRING='#ce9178'
        ISG_NUMBER='#b5cea8'
        ISG_TYPE='#4ec9b0'
        ISG_ERROR='#f44747'
        ISG_WARN='#f9e2af'

        # ── name-only tokens ──
        ISG_FZF_PROMPT='blue'
        # color24 (#005f87) is nearest256(ISG_SEL_BG) — a 256-palette stand-in,
        # because tig takes no hex. Indices 16-255 keep their xterm values (we
        # remap only 0-15), so 24 is stable. ANSI blue is a pale #89b4fa here:
        # white on it is 2.11:1, while `default` on color24 is 4.74:1.
        ISG_TIG_SEL_FG='default'
        ISG_TIG_SEL_BG='color24'

        # ── syntax highlighting (bat) ── from vim/.vim/colors/vs_dark.vim
        # ISG_COMMENT is deliberately NOT ISG_FG_DIM even though both are #888888
        # here: FG_DIM is k9s chrome and has already been retuned once for light
        # contrast. Sharing them would drag bat's comments along with it.
        ISG_COMMENT='#888888'
        ISG_PUNCTUATION='#888888'
        ISG_STRING_ESCAPE='#d16969'
        ISG_TAG='#569cd6'
        ISG_TAG_ATTR='#9cdcfe'
        ISG_LINE_HL='#2a2a2a'
        ISG_VISUAL_BG='#3a3d41'         # the editor's own selection, not SEL_BG
        ISG_GUTTER_FG='#555555'         # also invisibles
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

        # ── UI chrome (k9s) ── see the dark branch for the naming
        # 4.29:1 on this background. #999999 was 2.73:1, where dark's #888888
        # gets 3.78:1 — a light-only regression from the move to #FAFAFA. This is
        # also ISG_UI_FG_DIM's light value: the same grey tmux already uses for
        # secondary text, which is where the two tools should have agreed anyway.
        ISG_FG_DIM='#777777'
        ISG_BG_ALT='#f3f3f3'
        ISG_BORDER_UI='#d4d4d4'
        ISG_ON_ACCENT='#ffffff'
        ISG_CRUMB_FG='#ffffff'          # light crumbs do NOT invert to the body
        # Here the four blues really are four different colours, where dark reuses
        # ISG_ACCENT for two of them.
        ISG_ACCENT='#0000ff'
        ISG_ACCENT_DEEP='#0451a5'
        ISG_ACCENT_BRIGHT='#007acc'
        ISG_BUTTON_BG='#007acc'
        ISG_BUTTON_FOCUS_BG='#0451a5'
        ISG_TABLE_CURSOR_BG='#007acc'   # not ISG_SEL_BG: a filled bar, not a tint
        ISG_XRAY_CURSOR='#add6ff'
        ISG_TITLE_HL='#800000'          # tag/special, where dark uses a pale blue
        # Syntax-ish roles, from nvim colors/vs_light.vim
        ISG_STRING='#a31515'
        ISG_NUMBER='#098658'
        ISG_TYPE='#267f99'
        ISG_ERROR='#ff0000'
        # 4.04:1, same amber hue. #BF8803 was 2.99:1 against dark's 10.54:1.
        ISG_WARN='#a67102'

        # ── name-only tokens ──
        ISG_FZF_PROMPT='black'
        # ANSI blue is a strong #1e66f5 here, so white bold on it reads at
        # 4.91:1 and needs no 256-index stand-in.
        ISG_TIG_SEL_FG='white'
        ISG_TIG_SEL_BG='blue'

        # ── syntax highlighting (bat) ── from vim/.vim/colors/vs_light.vim
        # See the dark branch on why ISG_COMMENT is not ISG_FG_DIM.
        ISG_COMMENT='#999999'
        ISG_PUNCTUATION='#000000'
        ISG_STRING_ESCAPE='#811f3f'
        ISG_TAG='#800000'
        ISG_TAG_ATTR='#e50000'
        ISG_LINE_HL='#e5ebf1'
        ISG_VISUAL_BG='#add6ff'
        ISG_GUTTER_FG='#c0c0c0'
        # Light-only scopes: the light theme distinguishes doc comments and gives
        # markdown bold a colour, where the dark theme leaves both to inherit.
        # Unreferenced by bat-dark.tpl, so they are not defined above.
        ISG_DOC_COMMENT='#008000'
        ISG_MD_BOLD='#000080'
        ;;
    *)
        printf 'palette: unknown mode %s (want dark|light)\n' "$1" >&2
        return 1
        ;;
    esac
}
