
VIM SETUP
=========

1. Link Vim configuration
-------------------------

Create a symlink from the repo Vim configuration to your home directory:

    > ln -fs "$HOME/.rc/vim/.vimrc" \
          "$HOME/.vimrc"

For colors 

    > ln -fs "$HOME/.rc/vim/.vim/colors/vs_dark.vim" \
          "$HOME/.vim/vim/colors/vs_dark.vim"

-------------------------------------------------------------------------------
2. Check LSP/Treesitter config inside Vim
-----------------------------------------

Open Vim and run:

    :CocConfig

-------------------------------------------------------------------------------
3. Install Python LSP (pylance) inside Vim
-------------------------------------------

Open Vim and run:

    :CocInstall coc-pyright

-------------------------------------------------------------------------------
4. Install C/C++ clang LSP inside Vim
--------------------------------------

Open Vim and run:

    :CocInstall coc-clangd
