" Light (Visual Studio) color scheme — 16-color terminal fallback
" Ported from vim/.vim/colors/vs_light_def.vim

if exists("syntax_on")
  syntax reset
endif

set background=light
set notermguicolors
let g:colors_name = "vs_light_def"

" =====================
" Basic UI colors - using basic 16 colors for maximum compatibility
" =====================
hi Normal       ctermfg=0   ctermbg=NONE
hi Cursor       ctermfg=15  ctermbg=0
hi Visual       ctermbg=12
hi LineNr       ctermfg=8   ctermbg=NONE
hi StatusLine   ctermfg=15  ctermbg=2    cterm=bold
hi StatusLineNC ctermfg=8   ctermbg=7    cterm=NONE
hi VertSplit    ctermfg=7   ctermbg=NONE
hi Pmenu        ctermfg=0   ctermbg=7
hi PmenuSel     ctermfg=15  ctermbg=12
hi Search       ctermfg=0   ctermbg=14
hi IncSearch    ctermfg=0   ctermbg=11

" =====================
" Comments
" =====================
hi Comment      ctermfg=8

" =====================
" Constants / Numbers / Booleans
" =====================
hi Constant     ctermfg=4
hi Number       ctermfg=2
hi Boolean      ctermfg=2
hi String       ctermfg=1
hi Character    ctermfg=1

" =====================
" Identifiers
" =====================
hi Identifier   ctermfg=4
hi Function     ctermfg=4
hi Statement    ctermfg=4
hi Conditional  ctermfg=4
hi Repeat       ctermfg=4
hi Label        ctermfg=4
hi Operator     ctermfg=0
hi Keyword      ctermfg=4
hi Exception    ctermfg=4
hi PreProc      ctermfg=4
hi Include      ctermfg=4
hi Define       ctermfg=4
hi Macro        ctermfg=4
hi Type         ctermfg=4
hi StorageClass ctermfg=4
hi Structure    ctermfg=4
hi Typedef      ctermfg=4
hi Special      ctermfg=1
hi SpecialChar  ctermfg=1
hi Tag          ctermfg=1
hi Delimiter    ctermfg=0
hi SpecialComment ctermfg=2
hi Debug        ctermfg=9

" =====================
" Markdown / UI highlights
" =====================
hi Title        ctermfg=1 cterm=bold
hi Bold         ctermfg=4 cterm=bold
hi Italic       ctermfg=4 cterm=italic
hi Underlined   ctermfg=4 cterm=underline
hi Todo         ctermfg=1 cterm=bold

" =====================
" Diff / Git
" =====================
hi DiffAdd      ctermfg=2  ctermbg=10
hi DiffChange   ctermfg=4  ctermbg=14
hi DiffDelete   ctermfg=1  ctermbg=9
hi DiffText     ctermfg=0  ctermbg=11

" =====================
" CursorLine and Search
" =====================
hi CursorLine   ctermbg=7 cterm=NONE
hi Search       ctermbg=14 ctermfg=0
hi Visual       ctermbg=14

" =====================
" nvim-tree
" =====================
hi NvimTreeFolderName ctermfg=4 cterm=bold
hi NvimTreeOpenedFolderName ctermfg=4 cterm=bold
