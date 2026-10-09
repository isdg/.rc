" fzf.vim window/preview layout (nearly full-screen, vertical preview) — file
" in vim/, shared with nvim/rc.d/02-fzf-layout.lua, resolved through symlinks
let s:vim_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
execute 'source ' . s:vim_dir . '/fzf-layout.vim'
