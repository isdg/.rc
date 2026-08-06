" ============================================================
"                   VIM CONFIGURATION
" ============================================================
"'  Features:
" - Modern LSP support with CoC
" - File explorer with NERDTree
" - Fuzzy search with fzf
" - Easy commenting with NERDCommenter
" - Custom CLion-like light color scheme
" - Russian keyboard layout remapped for Vim commands
" - Split management
" - Session saving and restoring

" ============================================================
"                      HOTKEYS
" ============================================================
" GENERAL
"   <leader>s        Save file
"   <leader>w        Quit file
"   <leader>W        Quit without saving
"   <leader>Q        Quit all
"   <leader>;        Command history (fzf)
"   <leader>/        Search history (fzf)
"   <leader>J        Jump list (fzf)
"   <leader>:        Ex commands (fzf)
"   <leader>y        Yank to system clipboard
"   <leader>v        Reselect last visual selection
"   <leader>F        Format buffer (on demand; nothing formats on save)
"   .                Redo last command 
"   u                Undo last command
"   U                Undo all changes on current line
"   :source          Load any session or config file

" SPLITS
"   <leader>e        Vertical split
"   <leader>r        Horizontal split
"   <leader>f        Keep only current split
"   <C-h/j/k/l>      Move between splits
"   <leader>+/-         Resize split vertically
"   <leader>< / >       Resize split horizontally
"   <leader>=           Equalize all split sizes
"   <C-w>H/J/K/L     Move split to left/bottom/top/right

" SESSIONS
"   <leader><Tab>    Save session
"   <leader><S-Tab>  Load session
"   :mksession!      Manual save session
"   :source ~/.vim/session.vim  Restore manually

" NERDTREE
"   <leader>t        Toggle NERDTree
"   <C-f>            Find current file in NERDTree
"   I                Show/hide hidden files
"   m                File management menu
"   o/i/s/t/go       Open file (normal/split/tab)
"   p/u/C/R          Parent, up, change root, refresh
"   za/zA/zo/zc      Folding commands

" FUZZY FIND
"   <leader>p        Search files
"   <C-b>            Search buffers
"   :History         Open file history
"   :BLines          Search inside current buffer

" GIT (fzf; same keys as nvim)
"   <leader>gm       All repo commits
"   <leader>gf       Commits for the current buffer
"   <leader>gl       Commits for the current line (or selection, in visual)
"   <leader>gd       Changed files (git status)

" COMMENTING  (same keys as nvim)
"   gcc                    Toggle comment on the line (3gcc = 3 lines)
"   gc                     Toggle comment on a visual selection
"   <C-_>                  Same toggle, on Ctrl-/

" COC (LSP)
"   <CR>             Confirm completion
"   <C-j>/<C-k>      Navigate completion menu
"   gd/gy/gi/gr      Go to definition/type/impl/references
"   K                Show documentation (hover)
"   :CocRestart      Restart LSP client
"   :CocList         Show Coc features (diagnostics, extensions)
"   <leader>d / D    Diagnostics: list / toggle visibility
"   ]d / [d          Next / previous diagnostic
"   gK               Diagnostic message under cursor

" ============================================================
"                      NAVIGATION EXTENDED
" ============================================================
" BASIC MOVEMENT
"   h / j / k / l     Move cursor left / down / up / right
"   Insert mode:      <C-h/j/k/l> → Move cursor left/down/up/right
"   w / W             Jump forward to start of next word / WORD
"   e / E             Jump forward to end of current word / WORD
"   b / B             Jump backward to start of previous word / WORD
"   ge / gE           Jump backward to end of previous word / WORD
"   0 / ^ / $         Move to line start / first non-blank / line end
"   gg / G            Go to top / bottom of file
"   { / }             Jump to previous / next paragraph
"   %                 Jump to matching bracket/brace/parenthesis

" SCREEN & SCROLL MOVEMENT
"   H / M / L         Move cursor to top / middle / bottom of screen
"   zz / zt / zb      Center / top / bottom current line on screen
"   <C-u> / <C-d>     Scroll half-page up / down
"   <C-b> / <C-f>     Scroll full-page up / down
"   <C-e> / <C-y>     Scroll screen down / up (without moving cursor)
"   gg=G              Re-indent whole file

" FOLDING & CODE STRUCTURE
"   <space>           Toggle fold under cursor
"   za / zc / zo      Toggle / close / open current fold
"   zM / zR           Close / open all folds
"   zj / zk           Jump to next / previous fold

" JUMP & CHANGE HISTORY
"   <C-o> / <C-i>     Jump backward / forward in jump list
"   g; / g,           Jump backward / forward in change history
"   `.                Jump to last change in file
"   '' / ``           Jump to previous cursor position (line / exact)

" SPLITS (related)
"   <C-h/j/k/l>       Move between splits
"   <leader>H/J/K/L   Move split window to left/bottom/top/right
"   <leader>+/-/< />  Resize splits (height/width)
"   <leader>=         Equalize all split sizes

" NOTES

"  GENERAL MOVEMENT MODEL
"   - Vim navigation is modal: movement works differently in Normal, Visual, and Insert modes.
"   - Most motions (h/j/k/l, w/b, { }, gg/G, etc.) move the cursor within a buffer.
"   - Jumps (searches, tags, definitions) are recorded in a jump list, allowing easy back/forward travel.

"  VS CODE ANALOGS
"   Vim '' / ``       ≈ VS Code Ctrl+-  (jump back to last location)
"   Vim <C-i>         ≈ VS Code Ctrl+Shift+-  (jump forward again)
"   Vim <C-o>         ≈ VS Code full navigation history back
"   Vim g; / g,       ≈ "Go to previous/next change" (not built-in in VS Code)
"   Vim marks         ≈ No direct equivalent — similar to setting manual bookmarks

"  TIPS
"   - '' and `` toggle between last two cursor locations — ideal after searches or jumps.
"   - <C-o> and <C-i> navigate through a *stack* of jump points across buffers.
"   - Combine folds, marks, and search to move like a “mini IDE” inside Vim.
"   - For LSP-based jumps (definitions, references), use Coc bindings (gd, gy, gr).
"   - Pair ':set scrolloff=3' to keep cursor centered while scrolling.

" ============================================================
"                        SEARCH EXTENDED
" ============================================================
" BASIC SEARCH
"   /pattern          Search forward for pattern in file
"   ?pattern          Search backward for pattern in file
"   n / N             Repeat search (same / opposite direction)
"   * / #             Search forward / backward for current word (exact match)
"   g* / g#           Search forward / backward for partial word match
"   <leader>/         Search history (fzf)
"   :nohlsearch       Clear highlights after search

" LINE & CHAR SEARCH
"   f<char>           Find next occurrence of <char> on current line
"   F<char>           Find previous occurrence of <char> on current line
"   t<char>           Jump until *before* next <char> on line
"   T<char>           Jump until *before* previous <char> on line
"   ; / ,             Repeat last f/F/t/T forward / backward

" FUZZY & SYMBOL SEARCH (via plugins)
"   <leader>p         Fuzzy find files (:Files)
"   <leader>e / E     LSP symbols: this file / workspace
"   <leader>c / C     Lines: this buffer / all open buffers
"   <C-b>             Fuzzy find buffers (:Buffers)
"   <C-e>             Fuzzy search inside current buffer
"   :Rg <text>        Ripgrep search across project (requires ripgrep)

" NOTES
"   - '/' and '?' maintain last search pattern
"   - '*' and '#' auto-fill last used word
"   - ';' and ',' repeat within current line search
"   - Use ':set incsearch hlsearch' for live highlighting
"   - ':set ignorecase smartcase' for smart case-sensitive search

" ============================================================
"                 VISUAL NAVIGATION EXTENDED
" ============================================================
" BASIC SELECTION
"   v                Start visual mode (characterwise)
"   V                Line visual mode
"   <C-v>            Block visual mode
"   o                Jump to other end of current selection
"   gv               Reselect last visual selection
"   <leader>v        Reselect last visual selection (custom)

" CHARACTER MOTION SELECTION
"   vf<char>         Visual select forward *to* next occurrence of <char>
"   vF<char>         Visual select backward *to* previous occurrence of <char>
"   vt<char>         Visual select forward *until before* <char>
"   vT<char>         Visual select backward *until before* <char>

" SEARCH & REPEAT IN VISUAL MODE
"   ;                Repeat last f/F/t/T *in same direction*
"   ,                Repeat last f/F/t/T *in opposite direction*
"   /pattern         Extend selection forward by search (e.g. v/pattern)
"   ?pattern         Extend selection backward by search
"   n / N            Continue search forward / backward while keeping selection

" COMBINED MOVES (examples)
"   vfA              Select forward until first 'A'
"   ;                Extend to next 'A'
"   ,                Move selection to previous 'A'
"   vt)              Select forward until before closing parenthesis
"   o                Flip selection start/end for precise editing

" NOTES
"   - 'f'/'F' include the target character in selection
"   - 't'/'T' stop one character before the target
"   - ';' and ',' work for all of them
"   - 'o' is extremely useful to jump between start/end of selection
" ============================================================
"                    ADVANCED (POWER) HOTKEYS (NOT IMPLEMENTED YET) #TODO
" ============================================================
"   <leader>R        Reload vimrc (source ~/.vimrc)
"   <leader>x        Close current buffer (:bd)
"   <leader>X        Force close buffer (:bd!)
"   <leader>o        Close all other buffers
"   <leader>n        Open new empty buffer
"   <leader><leader> Switch between last two buffers
"   <leader>cp       Copy full file path to clipboard
"   <leader>cf       Copy file name to clipboard

" ============================================================


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


" ============================================================
"             VSCODE STUDIO LIGHT-LIKE COLOR SCHEME
" ============================================================

" Theme mode (dark|light) from the single source of truth (~/.config/isg/theme,
" written by toggle_theme.sh). Read at startup so new vim instances always match
" the current theme — no sed of this file. Falls back to light.
let s:isg_theme_file = (empty($XDG_CONFIG_HOME) ? expand('~/.config') : $XDG_CONFIG_HOME) . '/isg/theme'
let s:isg_mode = filereadable(s:isg_theme_file) ? trim(readfile(s:isg_theme_file)[0]) : 'light'
if s:isg_mode !=# 'dark' && s:isg_mode !=# 'light' | let s:isg_mode = 'light' | endif
execute 'colorscheme vs_' . s:isg_mode


" ============================================================
"               INSERT MODE NAVIGATION
" ============================================================
" inoremap <C-h> <Left>
" inoremap <C-l> <Right>
" inoremap <C-j> <Down>
" inoremap <C-k> <Up>


" ============================================================
"                        PLUGINS
" ============================================================
call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'} " LSP
Plug 'preservim/nerdtree'                       " File tree
Plug 'junegunn/fzf', { 'do': './install --all' }" Fuzzy finder
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


" ============================================================
"                    COC KEYBINDINGS
" ============================================================
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
inoremap <silent><expr> <C-j> coc#pum#visible() ? coc#pum#next(1) : "\<C-j>"
inoremap <silent><expr> <C-k> coc#pum#visible() ? coc#pum#prev(1) : "\<C-k>"
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> K :call CocActionAsync('doHover')<CR>

" Format on demand, never on save — matches nvim's <leader>F (keymaps/edit.lua).
" coc.preferences.formatOnSaveFiletypes was removed from coc-settings.json so a
" write only writes.
nnoremap <silent> <leader>F :call CocActionAsync('format')<CR>

" Diagnostics, same keys as nvim (nvim/lua/keymaps/lsp.lua):
"   <leader>d  searchable list      ]d / [d  next / previous
"   <leader>D  hide/show them       gK       message for the line under cursor
" coc's own convention is [g/]g; these use nvim's [d/]d so the two editors
" agree. diagnostic.enableSign is false in coc-settings.json (matching nvim's
" vim.diagnostic.config({ signs = false })), so `gK` is how you read the text.
" gK rather than ge: ge is the built-in "end of previous word" motion.
nnoremap <silent> <leader>d :CocList diagnostics<CR>
nnoremap <silent> <leader>D :call CocAction('diagnosticToggle')<CR>
nmap <silent> gK <Plug>(coc-diagnostic-info)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nmap <silent> [d <Plug>(coc-diagnostic-prev)


" ============================================================
"             RUSSIAN LAYOUT REMAPPING
" ============================================================
" Allows Vim commands on Russian keyboard layout
" (maps Cyrillic keys to Vim commands)

"noremap й q | noremap ц w | noremap у e | noremap к r | noremap е t
"noremap н y | noremap г u | noremap ш i | noremap щ o | noremap з p
"noremap х [ | noremap ъ ] | noremap ф a | noremap ы s | noremap в d
"noremap а f | noremap п g | noremap р h | noremap о j | noremap л k
"noremap д l | noremap ж ; | noremap э ' | noremap ё \
"noremap я z | noremap ч x | noremap с c | noremap м v
"noremap и b | noremap т n | noremap ь m | noremap б , | noremap ю .

"" Uppercase
"noremap Й Q | noremap Ц W | noremap У E | noremap К R | noremap Е T
"noremap Н Y | noremap Г U | noremap Ш I | noremap Щ O | noremap З P
"noremap Х { | noremap Ъ } | noremap Ф A | noremap Ы S | noremap В D
"noremap А F | noremap П G | noremap Р H | noremap О J | noremap Л K
"noremap Д L | noremap Ж : | noremap Э " | noremap Я Z
"noremap Ч X | noremap С C | noremap М V | noremap И B | noremap Т N
"noremap Ь M | noremap Б < | noremap Ю >

" =========================================
" Russian keyboard → English key remap
" =========================================

let ru_eng = {
\ 'й':'q', 'ц':'w', 'у':'e', 'к':'r', 'е':'t', 'н':'y', 'г':'u', 'ш':'i', 'щ':'o', 'з':'p', 'х':'[', 'ъ':']',
\ 'ф':'a', 'ы':'s', 'в':'d', 'а':'f', 'п':'g', 'р':'h', 'о':'j', 'л':'k', 'д':'l', 'ж':';', 'э':"'",
\ 'я':'z', 'ч':'x', 'с':'c', 'м':'v', 'и':'b', 'т':'n', 'ь':'m', 'б':',', 'ю':'.', 'ё':'`'
\ }

let ru_eng_upper = {
\ 'Й':'Q', 'Ц':'W', 'У':'E', 'К':'R', 'Е':'T', 'Н':'Y', 'Г':'U', 'Ш':'I', 'Щ':'O', 'З':'P', 'Х':'{', 'Ъ':'}',
\ 'Ф':'A', 'Ы':'S', 'В':'D', 'А':'F', 'П':'G', 'Р':'H', 'О':'J', 'Л':'K', 'Д':'L', 'Ж':':', 'Э':'"',
\ 'Я':'Z', 'Ч':'X', 'С':'C', 'М':'V', 'И':'B', 'Т':'N', 'Ь':'M', 'Б':'<', 'Ю':'>', 'Ё':'~'
\ }

let ru_eng_final = extend(copy(ru_eng), ru_eng_upper)

for [ru, en] in items(ru_eng_final)
    execute 'noremap' ru en
    execute 'vnoremap' ru en
    execute 'onoremap' ru en
endfor
" ============================================================
"                       NERD TREE
" ============================================================
" Tree on <leader>t, freed by dropping the (unused, long commented-out) tab
" mappings. Same key in nvim, see nvim/lua/keymaps/tree.lua.
" Comments go above the mapping, never after it: :map has no trailing-comment
" syntax, so `" Toggle NERDTree` used to be part of the mapped keys.
nnoremap <leader>t :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
let NERDTreeShowHidden=1
let g:NERDTreeWinSize=40
" Close the tree once a file is opened — the explorer is for picking a file, not
" for living next to the buffer. Matches nvim-tree's actions.open_file.quit_on_open
" (nvim/lua/plugins/nav.lua). Reopen with <leader>t.
let NERDTreeQuitOnOpen=1
autocmd FileType nerdtree setlocal number

" ============================================================
"                  HR (READING LIST)
" ============================================================
" isdg/hr.vim — sidebar over the `hr` CLI; same <leader>r as nvim.
" (Russian layout works via the к->r remap above.)
nnoremap <silent> <leader>r :HrToggle<CR>

" fzf.vim window/preview layout (nearly full-screen, vertical preview) —
" sibling file, shared with nvim/init.lua, resolved through symlinks
let s:script_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'source ' . s:script_dir . '/fzf-layout.vim'

" ============================================================
"                      FUZZY FIND
" ============================================================

" Search files (file palette)
nnoremap <leader>p :Files<CR>   

" Search buffers (buffer palette)
nnoremap <leader>b :Buffers<CR>

" Recent files (fzf v:oldfiles)
nnoremap <leader>B :History<CR>

" Lowercase = this buffer, uppercase = wider scope, for both pairs (same as
" nvim, see nvim/lua/keymaps/find.lua):
"   e / E   symbols in this file / across the workspace   (coc)
"   c / C   lines in this buffer / across open buffers    (fzf)
nnoremap <leader>e :CocList outline<CR>
nnoremap <leader>E :CocList symbols<CR>

" c gets a bat preview via FzfBLinesPreview — fzf.vim's own :BLines has none;
" see vim/fzf-layout.vim. C is fzf.vim's :Lines, every open buffer.
nnoremap <leader>c :call FzfBLinesPreview()<CR>
nnoremap <leader>C :Lines<CR>

" Search symbols accross project
nnoremap <leader>a :RG<CR>

" Search symbols accross project without order
nnoremap <leader>A :Rg<CR>

" Git commits (fzf) — include author in log so fzf can filter by it
let g:fzf_commits_log_options = '--color=always --format="%C(auto)%h%d %s %C(blue)[%an]%C(reset) %C(black)%C(bold)%cr"'
" Same keys as nvim (nvim/lua/keymaps/git.lua): gm repo log, gf this buffer's
" history, gl line history. A range on :BCommits becomes `git log -L a,b:file`,
" which is how gl works — `.` for the cursor line, '<,'> for a selection.
nnoremap <leader>gm :Commits<CR>
nnoremap <leader>gf :BCommits<CR>
nnoremap <leader>gl :.BCommits<CR>
xnoremap <leader>gl :BCommits<CR>
" Changed files (git status), the two-column prefix tells staged vs working
" tree. Distinct from plain `gd` above, which is coc's go-to-definition.
nnoremap <leader>gd :GFiles?<CR>

" ============================================================
"                      COMMENTING
" ============================================================
" Comment style, to match nvim's Comment.nvim: a space after the delimiter
" ("-- x", not "--x") and comments aligned at the left margin rather than at the
" line's indent-stripped start. Without NERDSpaceDelims the two editors produce
" different text for the same key.
let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
" Also toggle based on all selected lines, so a partly-commented block
" comments the rest instead of uncommenting — Comment.nvim's behaviour.
let g:NERDToggleCheckAllLines = 1

" Toggle comment on <C-_> (what Ctrl-/ sends), normal and visual — the same key
" nvim uses (nvim/lua/keymaps/edit.lua maps it onto Comment.nvim's gcc/gc).
" nmap/vmap rather than the noremap forms: <Plug>NERDCommenterToggle is itself a
" mapping, so the recursive form is the documented way to invoke it. Note :map
" has no trailing-comment syntax — a `" text` suffix lands inside the RHS.
nmap <C-_> <Plug>NERDCommenterToggle
vmap <C-_> <Plug>NERDCommenterToggle

" nvim's keys too (Comment.nvim): gcc toggles the current line — with a count,
" that many lines — and gc toggles a visual selection.
" `gc{motion}` (gcap, gc3j) is NOT provided: NERDCommenter works on lines and
" selections, not as an operator. tpope/vim-commentary is the drop-in that adds
" motions, if that turns out to matter.
nmap gcc <Plug>NERDCommenterToggle
xmap gc  <Plug>NERDCommenterToggle


" ============================================================
"                   FILE MANAGEMENT
" ============================================================
nnoremap <leader>s :w<CR>    " Save file
nnoremap <leader>w :q<CR>    " Quit file
nnoremap <leader>W :q!<CR>   " Quit without saving
nnoremap <leader>Q :qa<CR>   " Quit all



" ============================================================
"                   SPLIT MANAGEMENT
" ============================================================
" nnoremap <leader>e :vsplit<CR>        " Vertical split
" nnoremap <leader>r :split<CR>         " Horizontal split
" nnoremap <leader>f :only<CR>          " Keep only current split

" Move between splits
" Ctrl rather than <leader> (same as nvim, keymaps/editor.lua): one keystroke
" shorter for a constant motion, and Ctrl+letter is keyed off the physical key,
" so it needs no Russian-layout twin the way <leader>hjkl did.
" <C-l> gives up vim's redraw-screen default; :redraw! covers it.
" <C-h> is distinct from <BS> here (Ghostty sends 0x7f for Backspace) — checked
" with separate mappings: 0x08 fires <C-h>, 0x7f fires <BS>.
" Insert mode is untouched: <C-j>/<C-k> there stay coc's popup navigation.
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits
nnoremap <leader>+ :resize +5<CR>     " Increase height
nnoremap <leader>- :resize -5<CR>     " Decrease height
nnoremap <leader>< :vertical resize -5<CR>  " Decrease width
nnoremap <leader>> :vertical resize +5<CR>  " Increase width
nnoremap <leader>= <C-w>=             " Equalize all split sizes

" ============================================================
"                HISTORY & CLIPBOARD
" ============================================================
" Fuzzy history and pickers on the same keys as nvim (keymaps/editor.lua):
" ";" command history, "/" search history, "J" the jumplist, ":" every ex
" command. All four come from fzf.vim, which vim already loads — the plugin
" ships Jumps/Commands/History just like the copy nvim uses.
"
" q: and q/ are still there by typing them directly, for when the editable
" cmdline window is what's wanted.
"
" (These two lines used to read `nnoremap <leader>; q:    " Command history`.
"  :map has no trailing-comment syntax, so that text was part of the RHS and
"  got typed into the cmdline window on every press.)
nnoremap <leader>; :History:<CR>
nnoremap <leader>/ :History/<CR>
nnoremap <leader>J :Jumps<CR>
nnoremap <leader>: :Commands<CR>

" Swap jump list navigation (Ctrl+I = back, Ctrl+O = forward)
nnoremap <C-i> <C-o>
nnoremap <C-o> <C-i>

vnoremap <leader>y "+y   " Yank to system clipboard

nnoremap <leader>v gv    " Reselect last visual selection


" ============================================================
"                        SESSIONS
" ============================================================
let g:session_file = expand('~/.vim/session.vim')

" Save session
nnoremap <leader><Tab> :mksession! ~/.vim/session.vim<CR>:echo "Session saved!"<CR>

" Load session
nnoremap <leader><S-Tab> :source ~/.vim/session.vim<CR>:echo "Session loaded!"<CR>


" ============================================================
"                           GOYO
" ============================================================
" Make Goyo fill the entire screen vertically and horizontally (no margins)
let g:goyo_height = '100%'  " Full vertical height

" Disable horizontal resizing by Goyo
let g:goyo_linenr = 1


" Map toggle to <leader>z
nnoremap <leader>z :Goyo<CR>

" Goyo shift left: <leader><number>z (e.g., <leader>5z → Goyo-5)
nnoremap <leader>1z :Goyo-1<CR>
nnoremap <leader>2z :Goyo-2<CR>
nnoremap <leader>3z :Goyo-3<CR>
nnoremap <leader>4z :Goyo-4<CR>
nnoremap <leader>5z :Goyo-5<CR>
nnoremap <leader>6z :Goyo-6<CR>
nnoremap <leader>7z :Goyo-7<CR>
nnoremap <leader>8z :Goyo-8<CR>
nnoremap <leader>9z :Goyo-9<CR>

" Goyo shift right: <leader><shift+number>z (e.g., <leader>%z → Goyo+5)
nnoremap <leader>!z :Goyo+1<CR>
nnoremap <leader>@z :Goyo+2<CR>
nnoremap <leader>#z :Goyo+3<CR>
nnoremap <leader>$z :Goyo+4<CR>
nnoremap <leader>%z :Goyo+5<CR>
nnoremap <leader>^z :Goyo+6<CR>
nnoremap <leader>&z :Goyo+7<CR>
nnoremap <leader>*z :Goyo+8<CR>
nnoremap <leader>(z :Goyo+9<CR>

" ============================================================
"                        RUSSIAN VIM
" ============================================================
"
"
" Insert current date in format: Mon 18 Mar 2024 at 16:58:58
command! InsertDate execute "normal! a" . strftime("%a %d %b %Y at %H:%M:%S")

nnoremap <Leader>nt :InsertDate<CR>

" Insert timestamp in format: 2022-08-22 13:54
nnoremap <Leader>nT :execute "normal! a" . strftime("%Y-%m-%d %H:%M")<CR>

" English → Russian key mapping (for leader duplication)
let g:eng_to_ru_for_leader = {
\ 'q':'й', 'w':'ц', 'e':'у', 'r':'к', 't':'е', 'y':'н', 'u':'г', 'i':'ш', 'o':'щ', 'p':'з',
\ 'a':'ф', 's':'ы', 'd':'в', 'f':'а', 'g':'п', 'h':'р', 'j':'о', 'k':'л', 'l':'д',
\ 'z':'я', 'x':'ч', 'c':'с', 'v':'м', 'b':'и', 'n':'т', 'm':'ь'
\ }

" English → Russian key mapping (for leader duplication)
let g:eng_to_ru_upper_for_leader = {
\ 'Q':'Й', 'W':'Ц', 'E':'У', 'R':'К', 'T':'Е', 'Y':'Н', 'U':'Г', 'I':'Ш', 'O':'Щ', 'P':'З',
\ 'A':'Ф', 'S':'Ы', 'D':'В', 'F':'А', 'G':'П', 'H':'Р', 'J':'О', 'K':'Л', 'L':'Д',
\ 'Z':'Я', 'X':'Ч', 'C':'С', 'V':'М', 'B':'И', 'N':'Т', 'M':'Ь'
\ }


let ru_jumps = {
\ 'вв':'dd', 'фф':'yy', 'сс':'cc','пп':'gg', 'яя': 'zz'
\ }

for [ru, en] in items(ru_jumps)
    execute 'nnoremap ' . ru . ' ' . en
    execute 'vnoremap ' . ru . ' ' . en
    execute 'vnoremap ' . ru . ' ' . en
endfor

let eng_to_ru_final_for_leader = extend(copy(eng_to_ru_for_leader), eng_to_ru_upper_for_leader)

" Duplicate leader mappings for Russian layout
function! DuplicateLeaderRu(maps)
    for [eng, ru] in items(a:maps)
        " Normal mode
        let map_n = maparg('<leader>'.eng, 'n')
        if !empty(map_n)
            execute 'nnoremap <leader>'.ru.' '.map_n
        endif

        " Visual mode
        let map_v = maparg('<leader>'.eng, 'v')
        if !empty(map_v)
            execute 'vnoremap <leader>'.ru.' '.map_v
        endif

        " Operator-pending mode
        let map_o = maparg('<leader>'.eng, 'o')
        if !empty(map_o)
            execute 'onoremap <leader>'.ru.' '.map_o
        endif
    endfor
endfunction

call DuplicateLeaderRu(eng_to_ru_final_for_leader)

