
DOTFILES
========

A minimal, keyboard-driven dev environment for macOS and Linux.
Built for older hardware and large codebases (~1M lines) where heavy
IDEs feel sluggish.

Includes configs for:
  - Zsh (plain zsh, no framework + isg theme (forked from sobole) + fzf)
  - Vim and Neovim
  - Tmux (with TPM + tmux-resurrect)
  - Ghostty, Hyper, VSCode, Zed
  - Tig, JetBrains Mono + Computer Modern fonts
  - macOS defaults & key remapping

-------------------------------------------------------------------------------
QUICK START
-------------------------------------------------------------------------------

Clone into ~/.rc:

    > git clone <repo-url> "$HOME/.rc"
    > cd "$HOME/.rc"

Run the bootstrap for your OS:

    > ./bootstrap/darwin.sh        # macOS
    > ./bootstrap/linux.sh         # Linux

The bootstrap is modular (see bootstrap/components/) and handles:
Homebrew, packages, dotfile symlinks, vim-plug + plugins, fzf, fonts,
tig, vscode, hyper, key remapping, and macOS defaults.

Profiles (macOS). darwin.sh reads two component registries at the top of
the file — CORE and EXTRA — and --minimal runs only CORE with the smaller
darwin/Brewfile.minimal:

    > ./bootstrap/darwin.sh --minimal    # tmux + nvim + zsh core, ~0.8 GB
    > ./bootstrap/darwin.sh              # everything, ~14-15 GB

Minimal gets the editors, tmux, zsh, the fzf/rg/fd/bat picker stack, git
+ gh + tig + delta, Ghostty, dotfile symlinks and fonts. It leaves out
language toolchains (llvm, openjdk, zig, rust, node), media/graphics
libs, docker/minikube/mysql, VS Code with its extensions, and the
Rust-built side tools (plc, hr, omni, orchbus) — so there are no LSP
servers for mason to install.

Either profile can be verified without changing anything:

    > ./bootstrap/darwin.sh --ensure [--minimal]

Restart your terminal (or `exec zsh`) when it finishes.

-------------------------------------------------------------------------------
LAYOUT
-------------------------------------------------------------------------------

    bootstrap/      install scripts (darwin.sh, linux.sh + components/)
    zsh/            .zshrc, aliases, fzf integration, isg theme
    vim/            .vimrc, plugins, color schemes, coc extensions
    nvim/           init.lua + lazy.nvim setup
    tmux/           .tmux.conf
    ghostty/        terminal config
    hyper/          terminal config
    vscode/         settings + keybindings
    zed/            settings
    tig/            git TUI config
    fonts/          JetBrains Mono + Computer Modern
    darwin/         macOS system defaults + Brewfile
    prompt/         shell prompt definitions

-------------------------------------------------------------------------------
MANUAL SETUP (if you'd rather not run bootstrap)
-------------------------------------------------------------------------------

1. Link the core dotfiles:

    > ln -fs "$HOME/.rc/zsh/.zshrc"      "$HOME/.zshrc"
    > ln -fs "$HOME/.rc/vim/.vimrc"      "$HOME/.vimrc"
    > ln -fs "$HOME/.rc/tmux/.tmux.conf" "$HOME/.tmux.conf"
    > ln -fs "$HOME/.rc/nvim"            "$HOME/.config/nvim"

   There is no framework to install and no theme link to make — .zshrc is
   plain zsh and sources zsh/isg.zsh-theme from the repo directly.

2. Install vim-plug and plugins:

    > curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    > vim +PlugInstall +qall

3. Install TPM and tmux plugins:

    > git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

   Then inside tmux: prefix + I

4. Reload:

    > source ~/.zshrc

-------------------------------------------------------------------------------
NOTES
-------------------------------------------------------------------------------

  - tmux prefix bindings: see tmux/.tmux.conf (new windows open to the
    right of current; & kills window and moves focus left).
  - toggle_theme.sh switches macOS light/dark mode and adjacent terminal
    themes in one shot.
  - MANIFEST.txt lists the git worktrees used alongside main.
