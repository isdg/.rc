" Light (Visual Studio) color scheme for Neovim
" Ported from vim/.vim/colors/vs_light.vim

if exists("syntax_on")
  syntax reset
endif

set background=light
let g:colors_name = "vs_light"

" Terminal/ANSI palette = Ghostty 'Catppuccin Latte' (matches toggle_theme.sh).
" baleia.nvim reads these g:terminal_color_* at setup() so captured-pane ANSI
" colors render identically to the live terminal instead of baleia's generic
" defaults. Also fixes :terminal colors. Keep in sync with the Ghostty theme.
let g:terminal_color_0  = '#5c5f77'
let g:terminal_color_1  = '#d20f39'
let g:terminal_color_2  = '#40a02b'
let g:terminal_color_3  = '#df8e1d'
let g:terminal_color_4  = '#1e66f5'
let g:terminal_color_5  = '#ea76cb'
let g:terminal_color_6  = '#179299'
let g:terminal_color_7  = '#acb0be'
let g:terminal_color_8  = '#6c6f85'
let g:terminal_color_9  = '#de293e'
let g:terminal_color_10 = '#49af3d'
let g:terminal_color_11 = '#eea02d'
let g:terminal_color_12 = '#456eff'
let g:terminal_color_13 = '#fe85d8'
let g:terminal_color_14 = '#2d9fa8'
let g:terminal_color_15 = '#bcc0cc'

" =====================
" Basic UI colors
" =====================
hi Normal       guifg=#000000 guibg=#F2F2F2
hi Cursor       guifg=#FFFFFF guibg=#000000
hi Visual       guibg=#ADD6FF
hi LineNr       guifg=#c0c0c0 guibg=#F2F2F2
hi CursorLineNr guifg=#999999 guibg=#F2F2F2
hi StatusLine   guifg=#000000 guibg=#F2F2F2
hi StatusLineNC guifg=#AAAAAA guibg=#F2F2F2
hi VertSplit    guifg=#D4D4D4 guibg=#FFFFFF
hi Pmenu        guifg=#000000 guibg=#F3F3F3
hi PmenuSel     guifg=#FFFFFF guibg=#007ACC
hi Search       guifg=#000000 guibg=#90C2F9
hi IncSearch    guifg=#000000 guibg=#ADD6FF

" =====================
" Comments
" =====================
hi Comment      guifg=#999999 gui=italic

" =====================
" Constants / Numbers / Booleans
" =====================
hi Constant     guifg=#0000FF
hi Number       guifg=#098658
hi Boolean      guifg=#098658
hi String       guifg=#a31515
hi Character    guifg=#811f3f

" =====================
" Identifiers
" =====================
hi Identifier   guifg=#0000FF
hi Function     guifg=#0451a5
hi Statement    guifg=#0000FF
hi Conditional  guifg=#0000FF
hi Repeat       guifg=#0000FF
hi Label        guifg=#0000FF
hi Operator     guifg=#000000
hi Keyword      guifg=#0000FF
hi Exception    guifg=#0000FF
hi PreProc      guifg=#0000FF
hi Include      guifg=#0000FF
hi Define       guifg=#0000FF
hi Macro        guifg=#0000FF
hi Type         guifg=#0451a5
hi StorageClass guifg=#0000FF
hi Structure    guifg=#0000FF
hi Typedef      guifg=#0451a5
hi Special      guifg=#800000
hi SpecialChar  guifg=#811f3f
hi Tag          guifg=#800000
hi Delimiter    guifg=#000000
hi SpecialComment guifg=#008000
hi Debug        guifg=#FF0000

" =====================
" Markdown / UI highlights
" =====================
hi Title        guifg=#800000 gui=bold
hi Bold         guifg=#000080 gui=bold
hi Italic       guifg=#0000FF gui=italic
hi Underlined   guifg=#0451a5 gui=underline
hi Todo         guifg=#a31515 guibg=NONE gui=bold

" =====================
" Diff / Git
" =====================
hi DiffAdd      guifg=NONE    guibg=#E6FFEC
hi DiffChange   guifg=NONE    guibg=#E6FFEC
hi DiffDelete   guifg=NONE    guibg=#FFEBE9
hi DiffText     guifg=NONE    guibg=#ABF2BC gui=NONE

" =====================
" CursorLine and Search
" =====================
hi CursorLine   guibg=#E5EBF1

" =====================
" Window filler / zen-mode backdrop
" =====================
hi EndOfBuffer  guifg=#F2F2F2 guibg=#F2F2F2
hi WinSeparator guifg=#F2F2F2 guibg=#F2F2F2
hi NonText      guifg=#F2F2F2 guibg=#F2F2F2
hi ZenBg        guifg=#F2F2F2 guibg=#F2F2F2
hi SignColumn   guibg=#F2F2F2
hi FoldColumn   guibg=#F2F2F2

" =====================
" nvim-tree highlights
" =====================
hi Directory             guifg=#0451a5
hi NvimTreeFolderName    guifg=#0451a5
hi NvimTreeOpenedFolderName guifg=#0451a5
hi NvimTreeRootFolder    guifg=#800000 gui=bold

" =====================
" Diagnostics (native neovim)
" =====================
hi DiagnosticError          guifg=#FF0000
hi DiagnosticWarn           guifg=#BF8803
hi DiagnosticInfo           guifg=#0451a5
hi DiagnosticHint           guifg=#098658
hi DiagnosticUnderlineError gui=undercurl guisp=#FF0000
hi DiagnosticUnderlineWarn  gui=undercurl guisp=#BF8803
hi DiagnosticUnderlineInfo  gui=undercurl guisp=#0451a5
hi DiagnosticUnderlineHint  gui=undercurl guisp=#098658

" =====================
" Enums (match VSCode Visual Studio Light)
" =====================
hi Enum                 guifg=#267F99
hi @type.enum           guifg=#267F99
hi @lsp.type.enum       guifg=#267F99
hi @lsp.type.enumMember guifg=#267F99
