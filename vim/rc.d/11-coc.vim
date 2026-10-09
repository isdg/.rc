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

" Format on demand, never on save — matches nvim's <leader>F
" (nvim/rc.d/07-keys-edit.lua).
" coc.preferences.formatOnSaveFiletypes was removed from coc-settings.json so a
" write only writes.
nnoremap <silent> <leader>F :call CocActionAsync('format')<CR>

" Diagnostics, same keys as nvim (nvim/rc.d/09-keys-lsp.lua):
"   <leader>dk message under the cursor  ]d / [d  next / previous
"   <leader>dl searchable list           <leader>D  hide/show them
" coc's own convention is [g/]g; these use nvim's [d/]d so the two editors
" agree. diagnostic.enableSign is false in coc-settings.json (matching nvim's
" vim.diagnostic.config({ signs = false })), so <leader>dk is how you read the
" text. Nothing is mapped to the bare <leader>d: as a prefix alone it answers
" immediately, whereas a mapping there would have to sit out 'timeoutlen' first.
"
" The Russian twins are spelled out because DuplicateLeaderRu
" (08-ru-leader.vim) walks the single-letter table and so never sees a
" two-key sequence.
nnoremap <silent> <leader>dl :CocList diagnostics<CR>
nnoremap <silent> <leader>вд :CocList diagnostics<CR>
nnoremap <silent> <leader>D :call CocAction('diagnosticToggle')<CR>
nmap <silent> <leader>dk <Plug>(coc-diagnostic-info)
nmap <silent> <leader>вл <Plug>(coc-diagnostic-info)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nmap <silent> [d <Plug>(coc-diagnostic-prev)
