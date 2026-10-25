#!/usr/bin/env bash
# The one place colours are defined.
#
# To change a colour: edit it here, run `bash theme/generate.sh`, review the
# diff. theme/generate.sh renders theme/templates/*.tpl into the per-tool files.
#
# Call `isg_palette dark` or `isg_palette light` to set the ISG_* variables.
# Nothing is `readonly` on purpose — generate.sh calls it once per mode in one
# process. Must stay bash-3.2 clean: /bin/bash on Darwin is 3.2.57.
#
# Each mode first names its colours once, as `local`s templates cannot reach;
# every slot then points at one. That list is the whole colour inventory, and
# generate.sh rejects a slot assigned a literal hex.
#
# Two kinds of slot:
#
#   ISG_ANSI_0..15  The terminal's 16-colour ramp. Ghostty publishes it to every
#                   process, so it is what tig, LS_COLORS, GREP_COLORS, git,
#                   delta, less, fzf and the zsh prompt resolve `blue` / `red` /
#                   `green` to — the only colour language every tool here speaks.
#   ISG_*           Truecolour roles, for tools that accept hex.
#
# A few slots hold an ANSI *name* rather than hex (ISG_TIG_*, ISG_FZF_PROMPT,
# and ISG_FZF_ON_SEL in dark mode). Not an oversight: tig accepts no hex at
# all, and fzf takes names for those fields. They resolve through the ramp above.
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
        # ── colours: each one this mode uses, named once ──
        # neutrals
        local grey_1e='#1e1e1e' grey_25='#252526' grey_2a='#2a2a2a'
        local grey_2f='#2f2f2f' grey_3a='#3a3d41' grey_44='#444444'
        local grey_55='#555555' grey_6b='#6b6b6b' grey_77='#777777'
        local grey_80='#808080' grey_88='#888888' grey_a6='#a6a6a6'
        local grey_c0='#c0c0c0' grey_d4='#d4d4d4' grey_e6='#e6e6e6'
        local white='#ffffff'
        # terminal ramp: Catppuccin Mocha, brights from Ghostty
        local surface1='#45475a' surface2='#585b70' subtext0='#a6adc8'
        local subtext1='#bac2de' red='#f38ba8' red_hi='#f37799' green='#a6e3a1'
        local green_hi='#89d88b' yellow='#f9e2af' yellow_hi='#ebd391'
        local blue='#89b4fa' blue_hi='#74a8fc' pink='#f5c2e7' pink_hi='#f2aede'
        local teal='#94e2d5' teal_hi='#6bd7ca'
        # Visual Studio Dark+
        local vs_blue='#569cd6' vs_navy='#264f78' vs_azure='#007acc'
        local vs_sky='#87cfff' vs_ice='#9cdcfe' vs_teal='#4ec9b0'
        local vs_cyan='#61afc0' vs_orange='#ce9178' vs_sage='#b5cea8'
        local vs_salmon='#d16969' vs_red='#f44747' vs_gold='#cca700'
        # GitHub diff foregrounds
        local gh_green='#3fb950' gh_red='#f85149' gh_amber='#d29922'
        # delta's diff tints
        local tint_add='#2f4032' tint_add_emph='#2e5c37' tint_del='#4d3433'
        local tint_del_emph='#7f3d39'

        # ── ANSI ramp ──
        ISG_ANSI_0=$surface1;  ISG_ANSI_8=$surface2
        ISG_ANSI_1=$red;       ISG_ANSI_9=$red_hi
        ISG_ANSI_2=$green;     ISG_ANSI_10=$green_hi
        ISG_ANSI_3=$yellow;    ISG_ANSI_11=$yellow_hi
        ISG_ANSI_4=$blue;      ISG_ANSI_12=$blue_hi
        ISG_ANSI_5=$pink;      ISG_ANSI_13=$pink_hi
        ISG_ANSI_6=$teal;      ISG_ANSI_14=$teal_hi
        ISG_ANSI_7=$subtext0;  ISG_ANSI_15=$subtext1

        # ── surfaces ── match nvim colors/vs_dark.vim `hi Normal`
        ISG_BG=$grey_2f
        ISG_FG=$grey_d4
        # The cursor wherever it is drawn: Ghostty's cursor-color at the prompt,
        # `hi Cursor` in nvim and vim (they paint it themselves, see
        # nvim/rc.d/00-options.lua), bat's caret. One slot on purpose — split
        # them and the difference shows as a colour jump on entering the editor,
        # in the one glyph nothing else repaints.
        #
        # Body text, not white. A block cursor fills the whole cell, so #ffffff
        # made it the brightest thing on a #2f2f2f screen by a wide margin and it
        # pulled the eye while you were reading somewhere else. A filled cell
        # already reads as a cursor without the extra brightness, so matching the
        # text keeps it findable and lets the rest settle. Light mode softens its
        # cursor the same way — #444444 against #000000 text. cursor-text stays
        # ISG_BG, so the glyph underneath still punches through as a hole.
        ISG_CURSOR=$grey_d4

        # ── selection ── nvim colors/vs_dark.vim `hi Search`, so a picker's
        # selected row matches the buffer underneath it
        ISG_SEL_BG=$vs_navy
        ISG_SEL_FG=$grey_d4

        # ── tmux status bar / pane borders ──
        ISG_UI_FG=$grey_c0
        ISG_UI_FG_DIM=$grey_a6
        ISG_UI_FG_STRONG=$white
        ISG_UI_MSG=$grey_e6
        ISG_BORDER=$grey_44
        ISG_BORDER_ACTIVE=$grey_77

        # ── UI chrome (k9s) ──
        # The two k9s skins were hand-tuned independently and are not symmetric,
        # so several of these pairs are genuinely different roles rather than one
        # role in two shades — see the light branch for the contrast.
        ISG_FG_DIM=$grey_88             # info labels, completed, yaml colons
        ISG_BG_ALT=$grey_25             # dialogs, panels raised off the body
        ISG_ON_ACCENT=$white            # on filled accents: buttons, cursor
        ISG_CRUMB_FG="$ISG_BG"          # crumbs invert: body colour on accent
        # These blues look mergeable here, but nvim, vim and bat paint syntax
        # with them too, and light mode keeps them apart: keywords ISG_ACCENT,
        # types and functions ISG_ACCENT_DEEP. Merging slots would fuse those.
        # logo, labels, menu keys, focus, headers
        ISG_ACCENT=$vs_blue
        ISG_ACCENT_DEEP=$vs_blue        # suggestions, crumbs, xray graphics
        ISG_ACCENT_BRIGHT=$vs_sky
        ISG_BUTTON_BG=$vs_azure
        ISG_BUTTON_FOCUS_BG=$vs_azure
        ISG_TABLE_CURSOR_BG=$vs_navy
        ISG_XRAY_CURSOR=$vs_navy
        ISG_TITLE_HL=$vs_sky
        # Syntax-ish roles, from nvim colors/vs_dark.vim
        ISG_STRING=$vs_orange
        ISG_NUMBER=$vs_sage
        ISG_TYPE=$vs_teal
        ISG_ENUM=$vs_cyan               # nvim only; bat keeps ISG_TYPE
        ISG_ERROR=$vs_red
        ISG_WARN=$yellow

        # ── name-only tokens ──
        ISG_FZF_PROMPT='blue'
        ISG_FZF_ON_SEL='blue'           # hl+ and pointer, on the selected row
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
        ISG_COMMENT=$grey_88
        ISG_PUNCTUATION=$grey_88
        ISG_STRING_ESCAPE=$vs_salmon
        ISG_TAG=$vs_blue
        ISG_TAG_ATTR=$vs_ice
        ISG_LINE_HL=$grey_2a
        ISG_VISUAL_BG=$grey_3a          # the editor's own selection, not SEL_BG
        ISG_GUTTER_FG=$grey_55          # also invisibles

        # ── editor chrome (nvim) ──
        ISG_BG_DEEP=$grey_1e            # floats, :terminal, Error bg — below BG
        ISG_FG_FAINT=$grey_6b           # inactive statusline, unused symbols
        ISG_GUTTER_FG_CUR=$grey_88      # the cursor line's number
        ISG_SEARCH_BG=$vs_navy          # nvim `hi Search`; MatchParen too
        # NOT ISG_WARN: that is k9s's amber and was already retuned once for light
        # contrast (#26). nvim's diagnostics are their own yellow, and on dark this
        # single value covers Warn, Info and Hint plus all three undercurls.
        ISG_DIAG_WARN=$vs_gold

        # ── vim only ──
        # Vim's statusline is a filled colour bar; Neovim's is seamless (bg=BG).
        # That divergence is deliberate for now — unifying it would change what
        # vim looks like — so it gets its own two slots rather than pretending
        # the two editors agree.
        ISG_VIM_STATUS_BG=$vs_azure
        ISG_VIM_STATUS_NC_FG=$grey_c0

        # ── diff tints (delta) ── GitHub's dark tints (15% / 40% alpha) blended
        # onto ISG_BG by hand: retune ISG_BG and these must be re-blended.
        ISG_DIFF_DEL_BG=$tint_del
        ISG_DIFF_DEL_EMPH_BG=$tint_del_emph
        ISG_DIFF_ADD_BG=$tint_add
        ISG_DIFF_ADD_EMPH_BG=$tint_add_emph

        # Patch text and gitsigns (nvim): GitHub's foreground diff palette
        ISG_DIFF_ADD_FG=$gh_green
        ISG_DIFF_DEL_FG=$gh_red
        ISG_DIFF_CHANGE_FG=$gh_amber
        ISG_DIFF_META_FG=$grey_80       # index lines
        ISG_DIFF_HUNK_FG=$vs_ice        # @@ hunk headers
        ;;
    light)
        ISG_MODE='light'
        # ── colours: each one this mode uses, named once ──
        # neutrals
        local black='#000000' grey_33='#333333' grey_44='#444444'
        local grey_55='#555555' grey_77='#777777' grey_88='#888888'
        local grey_91='#919191' grey_99='#999999' grey_aa='#aaaaaa'
        local grey_c0='#c0c0c0' grey_cc='#cccccc' grey_f3='#f3f3f3'
        local grey_fa='#fafafa' white='#ffffff'
        # terminal ramp: Catppuccin Latte, brights from Ghostty
        local subtext1='#5c5f77' subtext0='#6c6f85' surface2='#acb0be'
        local surface1='#bcc0cc' red='#d20f39' red_hi='#de293e' green='#40a02b'
        local green_hi='#49af3d' yellow='#df8e1d' yellow_hi='#eea02d'
        local blue='#1e66f5' blue_hi='#456eff' pink='#ea76cb' pink_hi='#fe85d8'
        local teal='#179299' teal_hi='#2d9fa8'
        # Visual Studio Light
        local vs_blue='#0000ff' vs_navy='#000080' vs_azure='#007acc'
        local vs_deep='#0451a5' vs_sky='#90c2f9' vs_ice='#add6ff'
        local vs_mist='#e5ebf1' vs_green='#008000'
        local vs_jade='#098658' vs_pine='#16825d' vs_teal='#267f99'
        local vs_maroon='#800000' vs_wine='#811f3f' vs_brick='#a31515'
        local vs_red='#e50000' vs_scarlet='#ff0000' vs_amber='#a67102'
        local vs_ochre='#bf8803'
        # GitHub diff foregrounds
        local gh_blue='#0969da' gh_green='#1a7f37' gh_slate='#57606a'
        local gh_amber='#9a6700' gh_red='#cf222e'
        # delta's diff tints
        local tint_add='#e6ffec' tint_add_emph='#abf2bc' tint_del='#ffebe9'
        local tint_del_emph='#ffc1c0'

        # ── ANSI ramp ──
        ISG_ANSI_0=$subtext1;  ISG_ANSI_8=$subtext0
        ISG_ANSI_1=$red;       ISG_ANSI_9=$red_hi
        ISG_ANSI_2=$green;     ISG_ANSI_10=$green_hi
        ISG_ANSI_3=$yellow;    ISG_ANSI_11=$yellow_hi
        ISG_ANSI_4=$blue;      ISG_ANSI_12=$blue_hi
        ISG_ANSI_5=$pink;      ISG_ANSI_13=$pink_hi
        ISG_ANSI_6=$teal;      ISG_ANSI_14=$teal_hi
        ISG_ANSI_7=$surface2;  ISG_ANSI_15=$surface1

        # ── surfaces ── match nvim colors/vs_light.vim `hi Normal`
        ISG_BG=$grey_fa
        ISG_FG=$black
        ISG_CURSOR=$grey_44

        # ── selection ── nvim colors/vs_light.vim `hi Search`
        ISG_SEL_BG=$vs_sky
        ISG_SEL_FG=$black

        # ── tmux status bar / pane borders ──
        ISG_UI_FG=$grey_55
        ISG_UI_FG_DIM=$grey_77
        ISG_UI_FG_STRONG=$black
        ISG_UI_MSG=$grey_33
        ISG_BORDER=$grey_cc
        ISG_BORDER_ACTIVE=$grey_88

        # ── UI chrome (k9s) ── see the dark branch for the naming
        # 4.29:1 on this background. #999999 was 2.73:1, where dark's #888888
        # gets 3.78:1 — a light-only regression from the move to #FAFAFA. This is
        # also ISG_UI_FG_DIM's light value: the same grey tmux already uses for
        # secondary text, which is where the two tools should have agreed anyway.
        ISG_FG_DIM=$grey_77
        ISG_BG_ALT=$grey_f3
        ISG_ON_ACCENT=$white
        ISG_CRUMB_FG=$white             # light crumbs do NOT invert to the body
        # Here the four blues really are four different colours, where dark reuses
        # ISG_ACCENT for two of them.
        ISG_ACCENT=$vs_blue
        ISG_ACCENT_DEEP=$vs_deep
        ISG_ACCENT_BRIGHT=$vs_azure
        ISG_BUTTON_BG=$vs_azure
        ISG_BUTTON_FOCUS_BG=$vs_deep
        ISG_TABLE_CURSOR_BG=$vs_azure   # not SEL_BG: a filled bar, not a tint
        ISG_XRAY_CURSOR=$vs_ice
        ISG_TITLE_HL=$vs_maroon         # tag/special; dark uses a pale blue
        # Syntax-ish roles, from nvim colors/vs_light.vim
        ISG_STRING=$vs_brick
        ISG_NUMBER=$vs_jade
        ISG_TYPE=$vs_teal
        ISG_ENUM=$vs_teal
        ISG_ERROR=$vs_scarlet
        # 4.04:1, same amber hue. #BF8803 was 2.99:1 against dark's 10.54:1.
        ISG_WARN=$vs_amber

        # ── name-only tokens ──
        ISG_FZF_PROMPT='black'
        # ANSI blue is 2.6:1 on ISG_SEL_BG here; this is 4.1:1
        ISG_FZF_ON_SEL=$vs_deep
        # ANSI blue is a strong #1e66f5 here, so white bold on it reads at
        # 4.91:1 and needs no 256-index stand-in.
        ISG_TIG_SEL_FG='white'
        ISG_TIG_SEL_BG='blue'

        # ── syntax highlighting (bat) ── from vim/.vim/colors/vs_light.vim
        # See the dark branch on why ISG_COMMENT is not ISG_FG_DIM.
        ISG_COMMENT=$grey_99
        ISG_PUNCTUATION=$black
        ISG_STRING_ESCAPE=$vs_wine
        ISG_TAG=$vs_maroon
        ISG_TAG_ATTR=$vs_red
        ISG_LINE_HL=$vs_mist
        ISG_VISUAL_BG=$vs_ice
        ISG_GUTTER_FG=$grey_c0
        # Light-only scopes: the light theme distinguishes doc comments and gives
        # markdown bold a colour, where the dark theme leaves both to inherit.
        # Unreferenced by bat-dark.tpl, so they are not defined above.
        ISG_DOC_COMMENT=$vs_green
        ISG_MD_BOLD=$vs_navy

        # ── editor chrome (nvim) ── see the dark branch
        ISG_BG_DEEP=$white              # only VertSplit's bg here, unlike dark
        ISG_FG_FAINT=$grey_aa
        ISG_GUTTER_FG_CUR=$grey_99
        ISG_SEARCH_BG=$vs_sky
        ISG_DIAG_WARN=$vs_ochre

        # ── vim only ── see the dark branch. Note this is a *green* bar, where
        # dark's is blue: the two vim statuslines never matched each other either.
        ISG_VIM_STATUS_BG=$vs_pine
        ISG_VIM_STATUS_NC_FG=$grey_91

        # ── diff tints (delta) ── GitHub's light tints, verbatim
        ISG_DIFF_DEL_BG=$tint_del
        ISG_DIFF_DEL_EMPH_BG=$tint_del_emph
        ISG_DIFF_ADD_BG=$tint_add
        ISG_DIFF_ADD_EMPH_BG=$tint_add_emph

        # Patch text and gitsigns (nvim): GitHub's foreground diff palette
        ISG_DIFF_ADD_FG=$gh_green
        ISG_DIFF_DEL_FG=$gh_red
        ISG_DIFF_CHANGE_FG=$gh_amber
        ISG_DIFF_META_FG=$gh_slate      # index lines
        ISG_DIFF_HUNK_FG=$gh_blue       # @@ hunk headers
        ;;
    *)
        printf 'palette: unknown mode %s (want dark|light)\n' "$1" >&2
        return 1
        ;;
    esac
}
