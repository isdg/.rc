" ============================================================
"                    BASIC SETTINGS
" ============================================================

" Leader key
let mapleader = " "

" Fix Node 25 localStorage incompatibility with CoC
let g:coc_node_args = ['--localstorage-file=/tmp/coc-localstorage']

" Enable syntax highlighting
syntax on

" Filetype detection, plugins and indent
filetype plugin indent on

" Enable termgui colors (required for colorscheme)
set termguicolors

" Light background for better colors
set background=light

set wrap
set linebreak
set showbreak=↳\

set breakindent
set breakindentopt=shift:2,min:20

" ----------------------------
"        TABS & INDENTS
" ----------------------------
set tabstop=4         " Number of spaces per tab
set softtabstop=4     " Number of spaces when editing tabs
set shiftwidth=4      " Spaces per auto-indent
set expandtab         " Use spaces instead of tabs

" ----------------------------
"        NAVIGATION & SEARCH
" ----------------------------
set number            " Show line numbers
set ruler             " Show cursor position
set incsearch         " Incremental search
set scrolloff=4       " Set space when scrolloff
set hidden            " Allow switching buffers without saving
" Vi-compatible default is empty: backspace stops dead at autoindent, a line
" break, or wherever insert mode began. nvim defaults to this value and
" .vimrc.core already sets it; plain vim was the one left with the 1976 rule.
set backspace=indent,eol,start


" ----------------------------
"        AUTO-INDENT
" ----------------------------
set smartindent
set autoindent
set copyindent
set cindent


" ----------------------------
"        UPDATE & TIMING
" ----------------------------
set updatetime=300    " Faster update for Coc and highlighting
set redrawtime=10000  " Allow more time for syntax highlighting before disabling (default: 2000)
set regexpengine=0    " Auto-select best regex engine (new engine is faster for syntax)
