VIM SETUP
=========

Plain Vim with vim-plug and CoC for language servers. .rcboot's vim and
vimplug modules do all of this; the steps below are the manual path.


-------------------------------------------------------------------------------
LINK
-------------------------------------------------------------------------------

Create a symlink from the repo Vim configuration to your home directory:

    > ln -fs "$HOME/.rc/vim/.vimrc" "$HOME/.vimrc"

For colors:

    > mkdir -p "$HOME/.vim/colors"
    > ln -fs "$HOME/.rc/vim/.vim/colors/vs_dark.vim" \
        "$HOME/.vim/colors/vs_dark.vim"

-------------------------------------------------------------------------------
LSP CONFIG
-------------------------------------------------------------------------------

Open Vim and run:

    :CocConfig

-------------------------------------------------------------------------------
PYTHON LSP
-------------------------------------------------------------------------------

Install the Python LSP (coc-pyright). Open Vim and run:

    :CocInstall coc-pyright

-------------------------------------------------------------------------------
C/C++ LSP
-------------------------------------------------------------------------------

Install the clangd client. Open Vim and run:

    :CocInstall coc-clangd
