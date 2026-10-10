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
"   <leader>w        Save file
"   <leader>x        Quit file
"   <leader>X        Quit without saving
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
"   <leader>f        Search files
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
"   <leader>dk       Diagnostic message under cursor
"   <leader>dl       Searchable list of diagnostics

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
"   <C-w>H/J/K/L      Move split window to left/bottom/top/right
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
"   <leader>f         Fuzzy find files (:Files)
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
"   <leader>o        Close all other buffers
"   <leader>n        Open new empty buffer
"   <leader><leader> Switch between last two buffers
"   <leader>cp       Copy full file path to clipboard
"   <leader>cf       Copy file name to clipboard

" ============================================================

" Everything else lives in rc.d/, sourced in prefix order from ~/.config/rc/vim,
" where .rcboot links the enabled ones. A checkout never bootstrapped
" loads all of rc.d/, found through this file's own symlink.
let s:rc_d = expand('~/.config/rc/vim')
if !isdirectory(s:rc_d)
  let s:rc_d = fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/rc.d'
endif
for s:frag in sort(glob(s:rc_d . '/[0-9][0-9]-*.vim', 0, 1))
  execute 'source' fnameescape(s:frag)
endfor
unlet s:rc_d s:frag
