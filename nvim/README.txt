NEOVIM SETUP
============

Lua-based config equivalent to the Vim setup. Same core keybindings,
colorschemes, and Russian layout support; nvim adds keys of its own (git
hunks, harpoon, flash, the <leader><leader> plugins layer).

Plugins (neovim-native):

    vim.lsp + mason + blink.cmp         (replaces CoC)
    nvim-tree.lua                       (replaces NERDTree)
    fzf-lua                             (replaces CocList)
    builtin gc                          (replaces NERDCommenter)
    zen-mode.nvim                       (replaces goyo.vim)
    rainbow-delimiters.nvim             (replaces rainbow)
    nvim-treesitter                     (new)


-------------------------------------------------------------------------------
LINK
-------------------------------------------------------------------------------

Create a symlink from the repo to the Neovim config directory:

    > ln -sf "$HOME/.rc/nvim" "$HOME/.config/nvim"

-------------------------------------------------------------------------------
PLUGINS
-------------------------------------------------------------------------------

.rcboot's nvim module installs lazy.nvim, the plugins and the Treesitter
parsers; the config only loads them. To sync plugins by hand:

    > nvim --headless "+Lazy! sync" +qa

-------------------------------------------------------------------------------
LSP SERVERS
-------------------------------------------------------------------------------

Mason will auto-install configured language servers on first load:

    clangd          C/C++
    rust_analyzer   Rust
    gopls           Go
    ts_ls           TypeScript/JavaScript
    zls             Zig

Python uses ty, found on $PATH rather than installed by mason. A server
whose binary is missing is skipped, not an error.

To manage servers manually:

    :Mason

rust-analyzer runs once per Cargo workspace (its root comes from cargo
metadata); std and dependency files reached with gd join that server.

To test gd/gr/gi/gy, the picker and this setup headless on a pinned tokio
(needs git, cargo and rust-analyzer):

    > nvim/tests/lsp/run.sh --quick     # focused checks, about a minute
    > nvim/tests/lsp/run.sh             # and the full suite, ~10 minutes

In insert mode <C-n>/<C-p> walk the completion menu while one is up, and
otherwise move a line down/up, as in emacs. Its test runs the installed
plugins under this checkout's config:

    > nvim --clean --headless -l nvim/tests/completion_keys.lua

-------------------------------------------------------------------------------
EDITING HELPERS
-------------------------------------------------------------------------------

<leader>p and <leader>P paste the clipboard after and before the cursor;
over a selection both replace it and keep the unnamed register. Their test:

    > nvim --clean --headless -l nvim/tests/clipboard_keys.lua

<leader>rn falls back to a text rename where no server can rename, and
<leader>rN renames by text across the repo (lua/text_rename.lua). Its test
needs only rg:

    > nvim --clean --headless -l nvim/tests/text_rename.lua

<leader>Y copies the line, [count] lines or the visual selection for an
agent: repo-relative path:range, the enclosing symbol (lua/structure.lua),
an [unsaved] mark, the code fenced, and diagnostics on those lines
(lua/agentic_yank.lua). Its test:

    > nvim --clean --headless -l nvim/tests/agentic_yank.lua

lean.nvim draws its UI with Unicode glyphs; lua/lean_ascii.lua swaps them
for ASCII as its modules load, keeping Lean notation. Its test fails when
an update brings a glyph the swap doesn't know:

    > nvim --clean --headless -l nvim/tests/lean_ascii.lua

:Commits and :BCommits (<leader>gm/gf/gl) preview the diff at any width;
fzf.vim alone hides it at 120 columns or fewer (vim/fzf-layout.vim). Its
test needs git:

    > nvim --clean --headless -l nvim/tests/commits_preview.lua

fzf-lua pickers (links, the graph, LSP lists) keep the opts file's keys:
M-u/M-d/M-g/M-G/M-j on the list, M-J/M-K/M-U/M-D on the preview. Its test
fails when an nvim map in lua/plugins/nav.lua shadows one:

    > nvim --clean --headless -l nvim/tests/fzf_lua_keys.lua

-------------------------------------------------------------------------------
TREESITTER PARSERS
-------------------------------------------------------------------------------

.rcboot's nvim module installs the parsers in lua/ts_parsers.lua (built
with the tree-sitter CLI, so it and a C compiler must be present):

    c, cpp, python, rust, go, lua, zig, javascript, typescript,
    markdown, json, bash

To add one for good, list it there; for this machine only:

    :TSInstall <language>

-------------------------------------------------------------------------------
COLORSCHEME
-------------------------------------------------------------------------------

Default is vs_light. To switch:

    :colorscheme vs_dark
    :colorscheme vs_light_def
    :colorscheme vs_dark_def

To make it permanent, change the last line in rc.d/11-colors.lua.

-------------------------------------------------------------------------------
NOTES
-------------------------------------------------------------------------------

  - Shared keys are listed in the vim/.vimrc header; nvim-only keys are
    described where they are mapped, in rc.d/ and lua/plugins/.
