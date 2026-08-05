
NEOVIM SETUP
============

Lua-based config equivalent to the Vim setup.
Same keybindings, colorschemes, and Russian layout support.

Plugins (neovim-native):
  nvim-lspconfig + mason + nvim-cmp   (replaces CoC)
  nvim-tree.lua                       (replaces NERDTree)
  telescope.nvim                      (replaces fzf.vim)
  Comment.nvim                        (replaces NERDCommenter)
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

Open Neovim — lazy.nvim will bootstrap itself and install all plugins
on the first launch:

    > nvim

Wait for the install to finish, then restart.

-------------------------------------------------------------------------------
3. LSP servers
---------------

Mason will auto-install configured language servers on first load:

    clangd          C/C++
    pyright         Python
    rust_analyzer   Rust
    gopls           Go
    ts_ls           TypeScript/JavaScript

To manage servers manually:

    :Mason

-------------------------------------------------------------------------------
4. Treesitter parsers
----------------------

Treesitter parsers are installed automatically for:

    c, cpp, python, rust, go, lua, javascript, typescript,
    markdown, json, bash

To add more:

    :TSInstall <language>

-------------------------------------------------------------------------------
5. Switch colorscheme
----------------------

Default is vs_light. To switch:

    :colorscheme vs_dark
    :colorscheme vs_light_def
    :colorscheme vs_dark_def

To make it permanent, change the last line in init.lua.

-------------------------------------------------------------------------------
DONE!
-------------------------------------------------------------------------------

Same keybindings as Vim — see vim/.vimrc header for the full hotkey reference.
