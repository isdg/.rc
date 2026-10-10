" ============================================================
"                        PLUGINS
" ============================================================
" Fix Node 25 localStorage incompatibility with CoC
let g:coc_node_args = ['--localstorage-file=/tmp/coc-localstorage']

call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'} " LSP
Plug 'preservim/nerdtree'                       " File tree
Plug 'junegunn/fzf', { 'do': './install --bin' }" Fuzzy finder
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdcommenter'                  " Commenting
Plug 'junegunn/goyo.vim' " centered
Plug 'luochen1990/rainbow'
Plug 'isdg/hr.vim'                               " hr reading-list sidebar

let g:rainbow_active = 1

" No NERDCommenter default mappings. It otherwise creates a dozen <leader>c*
" maps (cc, ci, cu, cs, c$, …), none of which are used — commenting is on gcc /
" gc / <C-_> — and each one makes <leader>c ambiguous, so that key would sit
" waiting out 'timeoutlen' before firing. Must be set before plug#end(), which
" is when the plugin file is sourced and reads this.
let g:NERDCreateDefaultMappings = 0

"
call plug#end()
