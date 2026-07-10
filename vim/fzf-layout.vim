" ============================================================
"  fzf-layout.vim — shared fzf.vim window/preview layout
" ============================================================
" Nearly full-screen popup with the preview pane stacked vertically below
" the file list, for every fzf.vim command (:Files, :Rg, :Buffers, :History,
" :Commits, …) — they inherit these via fzf#wrap(), which falls back to
" g:fzf_layout/g:fzf_vim whenever a call doesn't set its own options.
"
" Sourced from both vim/.vimrc and nvim/init.lua.
let g:fzf_layout = { 'window': { 'width': 0.95, 'height': 0.95 } }
let g:fzf_vim = get(g:, 'fzf_vim', {})
let g:fzf_vim.preview_window = ['down,60%', 'ctrl-/']
