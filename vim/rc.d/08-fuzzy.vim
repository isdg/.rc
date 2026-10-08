" ============================================================
"                      FUZZY FIND
" ============================================================

" Search files (file palette). Same key as nvim (keymaps/find.lua).
nnoremap <leader>f :Files<CR>

" Search buffers (buffer palette)
nnoremap <leader>b :Buffers<CR>

" File history (fzf v:oldfiles). H for history; B was just the uppercase of b.
nnoremap <leader>H :History<CR>

" Lowercase = this buffer, uppercase = wider scope, for both pairs (same as
" nvim, see nvim/lua/keymaps/find.lua):
"   e / E   symbols in this file / across the workspace   (coc)
"   l / L   lines in this buffer / across open buffers    (fzf)
nnoremap <leader>e :CocList outline<CR>
nnoremap <leader>E :CocList symbols<CR>

" Both get a bat preview from vim/fzf-layout.vim — fzf.vim ships :BLines and
" :Lines without one. l is this buffer, L is every open buffer.
nnoremap <leader>l :call FzfBLinesPreview()<CR>
nnoremap <leader>L :call FzfLinesPreview()<CR>

" Position lists, freed up by the move above. Changes spans every listed
" buffer, unlike g;/g, — Marks shows file and line so you pick, not recall.
nnoremap <leader>C :Changes<CR>
nnoremap <leader>M :Marks<CR>

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
" tree. Distinct from plain `gd` in 03-coc.vim, which is coc's go-to-definition.
nnoremap <leader>gd :GFiles?<CR>
