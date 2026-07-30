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

" ------------------------------------------------------------
"  BLines with a preview  (<leader>C)
" ------------------------------------------------------------
" :BLines is one of the fzf.vim commands that ships with NO preview:
" fzf#vim#buffer_lines() builds its own --options list and never routes through
" fzf#vim#with_preview(), so g:fzf_vim.preview_window above never reaches it.
" This calls the same function with a bat preview bolted on, matching the
" `bat --style=numbers --highlight-line` previews in zsh/fzf.zsh.
"
" A function rather than a `command! BLines` override, so it can't lose a race
" with fzf.vim defining its own commands at plugin-load time.
function! FzfBLinesPreview() abort
    " BLines takes its lines from the BUFFER (getline), so preview the buffer,
    " not the file on disk — otherwise unsaved edits make every previewed line
    " off-by-however-many, and an unnamed buffer has nothing to preview at all.
    " Keep the extension so bat still picks the right syntax.
    let l:file = expand('%:p')
    if &modified || empty(l:file) || !filereadable(l:file)
        let l:ext = expand('%:e')
        let l:file = tempname() . (empty(l:ext) ? '' : '.' . l:ext)
        call writefile(getline(1, '$'), l:file)
    endif

    " Field 1 of a BLines entry is the line number, space-padded by fzf.vim's
    " ' %4d ' format — strip to digits before handing it to bat.
    " --decorations=always: bat hides the number gutter when stdout is a pipe.
    "
    " Centre the matched line in the pane rather than just showing it somewhere:
    " render exactly the window's worth of lines around it, using the
    " $FZF_PREVIEW_LINES fzf exports for every preview process. fzf's own
    " '+{1}-/2' scroll offset would be the obvious way, but it needs a field
    " that is "a numeric integer" and ours arrives padded, so do the arithmetic
    " here where it's certain. Clamps to the top of the file for early lines.
    let l:preview = 'n=$(printf "%s" {1} | tr -dc "[:digit:]"); '
                \ . 'h=${FZF_PREVIEW_LINES:-40}; '
                \ . 's=$(( n - (h - 1) / 2 )); [ "$s" -lt 1 ] && s=1; '
                \ . 'bat --color=always --style=numbers --decorations=always '
                \ . '--highlight-line "$n" '
                \ . '--line-range "$s:$(( s + h - 1 ))" '
                \ . shellescape(l:file)

    " Reuse the window/toggle-key from g:fzf_vim.preview_window above so this
    " stays in step with the rest of the fzf.vim commands.
    let l:pw = get(g:fzf_vim, 'preview_window', ['down,60%', 'ctrl-/'])
    let l:opts = ['--preview', l:preview, '--preview-window', l:pw[0]]
    if len(l:pw) > 1
        let l:opts += ['--bind', l:pw[1] . ':toggle-preview']
    endif

    call fzf#vim#buffer_lines('', { 'options': l:opts }, 0)
endfunction
