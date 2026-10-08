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

" Terminal cursor colour, in step with the colorscheme.
"
" Neovim gets this for free: 'guicursor' names the Cursor group and it emits the
" escape itself. Terminal Vim never does — `hi Cursor` reaches a GUI only — so
" the caret would keep the cursor-color Ghostty read at launch, which a theme
" toggle cannot change without reloading Ghostty. The colorschemes publish the
" hex as g:isg_cursor; write OSC 12 with it, and OSC 112 to hand the colour back
" to the terminal on exit.
"
" t_ti/t_te carry the startup and exit case: both are sent after this file is
" sourced, which is why appending here works — an autocmd on VimEnter does not,
" its output goes nowhere that early. The ColorScheme hook then covers a live
" :colorscheme, where echoraw() does reach the terminal.
if !has('gui_running') && exists('g:isg_cursor')
  let &t_ti .= "\<Esc>]12;" . g:isg_cursor . "\x07"
  let &t_te = "\<Esc>]112\x07" . &t_te
  if exists('*echoraw')
    augroup isg_cursor_color
      autocmd!
      autocmd ColorScheme * call echoraw("\<Esc>]12;" . g:isg_cursor . "\x07")
    augroup END
  endif
endif
