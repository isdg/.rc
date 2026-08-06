" Light (Visual Studio) Vim color scheme
" Author: Converted from VS Code theme
" Usage: place this file in ~/.vim/colors/ and use :colorscheme light

if exists("syntax_on")
  syntax reset
endif

set background=light
let g:colors_name = "vs_light"

" =====================
" Basic UI colors
" =====================
hi Normal       guifg=#000000 guibg=#FAFAFA
hi Cursor       guifg=#FFFFFF guibg=#000000
hi Visual       guibg=#ADD6FF
hi LineNr       guifg=#c0c0c0 guibg=#FAFAFA
hi CursorLineNr guifg=#999999 guibg=#FAFAFA
hi StatusLine   guifg=#FFFFFF guibg=#16825D
hi StatusLineNC guifg=#919191 guibg=#F3F3F3
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
hi DiffAdd      guifg=#098658 guibg=#E8F8F5
hi DiffChange   guifg=#0451a5 guibg=#F0F0FF
hi DiffDelete   guifg=#a31515 guibg=#FFECEC
hi DiffText     guifg=#000000 guibg=#FFD700

" =====================
" CursorLine and Search
" =====================
hi CursorLine   guibg=#E5EBF1
hi Search       guibg=#90C2F9 guifg=#000000
hi Visual       guibg=#ADD6FF

" =====================
" Enums (match VSCode Visual Studio Light)
" =====================
hi Enum             guifg=#267F99
hi CocSemEnum       guifg=#267F99
hi CocSemEnumMember guifg=#267F99

" =====================
" End
" =====================
