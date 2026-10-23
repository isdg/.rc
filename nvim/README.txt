
NEOVIM SETUP
============

Lua-based config equivalent to the Vim setup.
Same core keybindings, colorschemes, and Russian layout support; nvim
adds keys of its own (git hunks, harpoon, flash, the <leader><leader>
plugins layer).

Plugins (neovim-native):
  vim.lsp + mason + blink.cmp         (replaces CoC)
  nvim-tree.lua                       (replaces NERDTree)
  fzf-lua                             (replaces CocList)
  builtin gc                          (replaces NERDCommenter)
  zen-mode.nvim                       (replaces goyo.vim)
  rainbow-delimiters.nvim             (replaces rainbow)
  nvim-treesitter                     (new)

-------------------------------------------------------------------------------
1. Link Neovim configuration
-----------------------------

Create a symlink from the repo to the Neovim config directory:

    > ln -sf "$HOME/.rc/nvim" "$HOME/.config/nvim"

-------------------------------------------------------------------------------
2. Install plugins
-------------------

.rcboot's nvim module installs lazy.nvim, the plugins and the Treesitter
parsers; the config only loads them. To sync plugins by hand:

    > nvim --headless "+Lazy! sync" +qa

-------------------------------------------------------------------------------
3. LSP servers
---------------

Mason will auto-install configured language servers on first load:

    clangd          C/C++
    rust_analyzer   Rust
    gopls           Go
    ts_ls           TypeScript/JavaScript
    zls             Zig

Python uses ty, found on $PATH rather than installed by mason.
A server whose binary is missing is skipped, not an error.

To manage servers manually:

    :Mason

rust-analyzer runs once per Cargo workspace (its root comes from cargo
metadata); std and dependency files reached with gd join that server.

To test gd/gr/gi/gy, the picker and this setup headless on a pinned
tokio (needs git, cargo and rust-analyzer):

    > nvim/tests/lsp/run.sh --quick     # focused checks, about a minute
    > nvim/tests/lsp/run.sh             # and the full suite, ~10 minutes

-------------------------------------------------------------------------------
4. Treesitter parsers
----------------------

.rcboot's nvim module installs the parsers in lua/ts_parsers.lua (built
with the tree-sitter CLI, so it and a C compiler must be present):

    c, cpp, python, rust, go, lua, zig, javascript, typescript,
    markdown, json, bash

To add one for good, list it there; for this machine only:

    :TSInstall <language>

-------------------------------------------------------------------------------
5. Switch colorscheme
----------------------

Default is vs_light. To switch:

    :colorscheme vs_dark
    :colorscheme vs_light_def
    :colorscheme vs_dark_def

To make it permanent, change the last line in rc.d/11-colors.lua.

-------------------------------------------------------------------------------
DONE!
-------------------------------------------------------------------------------

Shared keys are listed in the vim/.vimrc header; nvim-only keys are
described where they are mapped, in rc.d/ and lua/plugins/.
