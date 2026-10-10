" ============================================================
"                     NVIM'S DEFAULTS
" ============================================================
" Options nvim turns on out of the box and plain vim does not, so the two
" editors behave alike (nvim/rc.d/00-options.lua leaves all of these alone).
set showcmd laststatus=2 display=lastline
set hlsearch
set ttimeout ttimeoutlen=50
set wildmenu
if exists('+belloff') | set belloff=all | endif
