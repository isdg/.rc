" ============================================================
"  fzf-layout.vim — shared fzf.vim window/preview layout
" ============================================================
" Full-screen popup with the preview pane stacked vertically below
" the file list, for every fzf.vim command (:Files, :Rg, :Buffers, :History,
" :Commits, …) — they inherit these via fzf#wrap(), which falls back to
" g:fzf_layout/g:fzf_vim whenever a call doesn't set its own options.
"
" Sourced from both vim/.vimrc and nvim/init.lua.
" 1.0 is the whole screen: fzf.vim floors height at &lines - 1, so the popup
" takes everything but the command line. Matches omni's and orchbus's tmux
" popups, which run -w 100% -h 100%.
let g:fzf_layout = { 'window': { 'width': 1.0, 'height': 1.0 } }
let g:fzf_vim = get(g:, 'fzf_vim', {})
let g:fzf_vim.preview_window = ['down,60%', 'ctrl-/']

" ------------------------------------------------------------
"  Query history  (<leader>a live ripgrep especially)
" ------------------------------------------------------------
" One file per command (fzf#run names it after the command), so :RG's queries
" never mix with :Files'. The live-ripgrep query IS the search, so retyping a
" long pattern was the real cost. fzf creates the directory itself.
let g:fzf_history_dir = empty($XDG_DATA_HOME)
    \ ? '~/.local/share/fzf-history'
    \ : $XDG_DATA_HOME . '/fzf-history'

" --history makes fzf remap ctrl-n/ctrl-p to history, spending the pair that
" moves the cursor; put history on ctrl-j/ctrl-k and hand n/p back. Via
" $FZF_DEFAULT_OPTS (g:fzf_layout refuses `options`) and so only inside vim.
if $FZF_DEFAULT_OPTS !~# 'prev-history'
    let $FZF_DEFAULT_OPTS = $FZF_DEFAULT_OPTS
        \ . ' --bind=ctrl-j:next-history,ctrl-k:prev-history,ctrl-n:down,ctrl-p:up'
endif

" ------------------------------------------------------------
"  BLines with a preview  (<leader>l)
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
    " fzf.vim forces --layout=reverse-list on :BLines/:Lines unless
    " $FZF_DEFAULT_OPTS names `reverse`, and ours live in $FZF_DEFAULT_OPTS_FILE,
    " which it never reads. Restate the default so these read like every picker.
    let l:pw = get(g:fzf_vim, 'preview_window', ['down,60%', 'ctrl-/'])
    let l:opts = ['--layout=default',
                \ '--preview', l:preview, '--preview-window', l:pw[0]]
    if len(l:pw) > 1
        let l:opts += ['--bind', l:pw[1] . ':toggle-preview']
    endif

    call fzf#vim#buffer_lines('', { 'options': l:opts }, 0)
endfunction

" ------------------------------------------------------------
"  Lines with a preview  (<leader>L)
" ------------------------------------------------------------
" :Lines has the same gap as :BLines — fzf#vim#lines() assembles its own
" --options and never routes through fzf#vim#with_preview() either.
"
" Harder than the BLines case: the entries span every listed buffer, so the
" preview has to work out WHICH file each one came from. Build a
" bufnr -> path manifest up front and let the preview look the path up by the
" buffer number carried in the entry.
function! FzfLinesPreview() abort
    " Same reasoning as FzfBLinesPreview — preview the BUFFER, not the file on
    " disk, wherever the two can disagree, or unsaved edits shift every
    " previewed line. Unmodified buffers point straight at their own file, so
    " the common case writes nothing and this stays cheap.
    let l:manifest = tempname()
    let l:rows = []
    for l:b in filter(range(1, bufnr('$')), 'buflisted(v:val)')
        let l:path = fnamemodify(bufname(l:b), ':p')
        if getbufvar(l:b, '&modified') || empty(l:path) || !filereadable(l:path)
            let l:ext = fnamemodify(bufname(l:b), ':e')
            let l:path = tempname() . (empty(l:ext) ? '' : '.' . l:ext)
            call writefile(getbufline(l:b, 1, '$'), l:path)
        endif
        call add(l:rows, l:b . "\t" . l:path)
    endfor
    call writefile(l:rows, l:manifest)

    " fzf#vim#_lines() formats an entry as
    "     <bufnr> \t <bufname> \t <lnum> \t <text>
    " but only fills the bufname in when &columns > 120, and fzf's default
    " delimiter splits on runs of whitespace — so on a narrow window every
    " field after the first shifts left by one. Pin --delimiter to the tab and
    " the positions hold at any width, which is how fzf.vim's own sink reads
    " these entries back (split(line, "\t")). --nth then has to be restated in
    " the same terms: 3.. is lnum + text, matching what fzf.vim searches.
    "
    " Both numbers arrive space-padded from the "%2d" / "%4d " formats, so
    " strip them to digits before use, exactly as FzfBLinesPreview does.
    " Centring maths and the --decorations=always note are the same as there.
    let l:preview = 'b=$(printf "%s" {1} | tr -dc "[:digit:]"); '
                \ . 'n=$(printf "%s" {3} | tr -dc "[:digit:]"); '
                \ . 'f=$(awk -F"\t" -v b="$b" ''$1 == b { print $2; exit }'' '
                \ . shellescape(l:manifest) . '); '
                \ . '[ -n "$f" ] || exit 0; '
                \ . 'h=${FZF_PREVIEW_LINES:-40}; '
                \ . 's=$(( n - (h - 1) / 2 )); [ "$s" -lt 1 ] && s=1; '
                \ . 'bat --color=always --style=numbers --decorations=always '
                \ . '--highlight-line "$n" '
                \ . '--line-range "$s:$(( s + h - 1 ))" '
                \ . '"$f"'

    " --layout=default for the same reason as FzfBLinesPreview.
    let l:pw = get(g:fzf_vim, 'preview_window', ['down,60%', 'ctrl-/'])
    let l:opts = ['--layout=default', '--delimiter', '\t', '--nth', '3..',
                \ '--preview', l:preview, '--preview-window', l:pw[0]]
    if len(l:pw) > 1
        let l:opts += ['--bind', l:pw[1] . ':toggle-preview']
    endif

    call fzf#vim#lines('', { 'options': l:opts })
endfunction
