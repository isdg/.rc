" Dark (Visual Studio) color scheme — 16-color terminal fallback
" Ported from vim/.vim/colors/vs_dark_def.vim

if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'vs_dark_def'
set background=dark
set notermguicolors

" Editor colors - using basic 16 colors for maximum compatibility
hi Normal       ctermfg=7   ctermbg=NONE
hi CursorLine   ctermbg=0   cterm=NONE
hi Visual       ctermbg=8
hi LineNr       ctermfg=8   ctermbg=NONE
hi CursorLineNr ctermfg=15  ctermbg=NONE
hi StatusLine   ctermfg=0   ctermbg=12   cterm=bold
hi StatusLineNC ctermfg=7   ctermbg=8    cterm=NONE
hi VertSplit    ctermfg=8   ctermbg=NONE
hi Pmenu        ctermfg=7   ctermbg=8
hi PmenuSel     ctermfg=0   ctermbg=12
hi PmenuSbar    ctermbg=8
hi PmenuThumb   ctermbg=12

" Comments
hi Comment      ctermfg=8

" Constants
hi Constant     ctermfg=12
hi Number       ctermfg=10
hi Boolean      ctermfg=12
hi String       ctermfg=1
hi Character    ctermfg=1
hi Float        ctermfg=10
hi SpecialChar  ctermfg=9

" Keywords
hi Keyword      ctermfg=12
hi Conditional  ctermfg=12
hi Repeat       ctermfg=12
hi Exception    ctermfg=12
hi Operator     ctermfg=7
hi PreProc      ctermfg=12
hi Include      ctermfg=12
hi Define       ctermfg=12
hi Macro        ctermfg=12
hi Type         ctermfg=12
hi StorageClass ctermfg=12
hi Structure    ctermfg=12
hi Typedef      ctermfg=12

" Functions
hi Function     ctermfg=14
hi Identifier   ctermfg=14
hi Method       ctermfg=14
hi Statement    ctermfg=12

" Tags and markup
hi Tag          ctermfg=12
hi Label        ctermfg=12
hi Special      ctermfg=12
hi Delimiter    ctermfg=7
hi Title        ctermfg=12 cterm=bold
hi Bold         cterm=bold
hi Italic       cterm=italic
hi Underlined   cterm=underline
hi Error        ctermfg=1  ctermbg=NONE cterm=bold
hi Todo         ctermfg=11 ctermbg=NONE cterm=bold

" Diff
hi DiffAdd      ctermfg=10 ctermbg=NONE
hi DiffChange   ctermfg=12 ctermbg=NONE
hi DiffDelete   ctermfg=9  ctermbg=NONE
hi DiffText     ctermfg=14 ctermbg=NONE cterm=bold

" Match parentheses
hi MatchParen   ctermfg=15 ctermbg=8 cterm=bold

" Search
hi Search       ctermfg=0  ctermbg=11
hi IncSearch    ctermfg=0  ctermbg=14

" Terminal colors
hi Terminal     ctermfg=7  ctermbg=NONE

" Popup and floating windows
hi FloatBorder  ctermfg=8
hi NormalFloat  ctermfg=7  ctermbg=8

" nvim-tree
hi NvimTreeFolderName ctermfg=12 cterm=bold
hi NvimTreeOpenedFolderName ctermfg=12 cterm=bold
