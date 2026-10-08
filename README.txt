
DOTFILES
========

A minimal, keyboard-driven only dev environment for Darwin and Linux.
Built for older hardware and large codebases (~1M lines) where heavy
IDEs feel sluggish.

Includes configs for:
  - zsh (plain zsh, no framework + isg theme (forked from sobole) + fzf)
  - vim and neovim
  - tmux (with tpm, tmux-resurrect, omni and orchbus)
  - ghostty
  - git (with delta as the pager), tig
  - fzf, bat
  - k9s (skins + log plugins)
  - ssh client and gpg-agent
  - hammerspoon (window slots, keyboard scrolling, translate popup)
  - claude code (settings, status line, skills plugin)
  - light/dark theme across the terminal tools, generated from one palette
  - jetbrains mono + computer modern fonts
  - darwin defaults & key remapping


My personal feeling is that I don't like the concept of an IDE as a whole.
Why should some piece of software lead your way of working, especially
given three "when" facts: when almost all technologies are modular enough,
when you know what to do, and when you can responsibly build your own way
of working? Also, here we use only the keyboard, because I feel the mouse is
only for learning how to use a computer first and for poor user-centric OS
context switch designs.


-------------------------------------------------------------------------------
QUICK START
-------------------------------------------------------------------------------

Clone into ~/.rc:

    > git clone https://github.com/isdg/.rc.git "$HOME/.rc"
    > cd "$HOME/.rc"

Run the bootstrap for your OS:

    > ./.rcboot/darwin.sh        # Darwin
    > ./.rcboot/linux.sh         # Linux

The bootstrap is modular (see .rcboot/) and handles:
Homebrew, packages, dotfile symlinks, vim-plug + plugins, fzf, fonts,
tig, key remapping, and Darwin defaults.

Profiles (Darwin). darwin.sh reads two component registries at the top of
the file — CORE and EXTRA — and --minimal runs only CORE with the smaller
darwin/Brewfile.minimal:

    > ./.rcboot/darwin.sh --minimal    # tmux + nvim + zsh core, ~0.8 GB
    > ./.rcboot/darwin.sh              # everything, ~14-15 GB

Minimal gets the editors, tmux, zsh, the fzf/rg/fd/bat picker stack, git
+ gh + tig + delta, Ghostty, dotfile symlinks and fonts. It leaves out
language toolchains (llvm, openjdk, zig, rust, node), media/graphics
libs, docker/minikube/mysql/qemu, and the Rust-built side tools (plc, hr,
omni, orchbus) — so there are no LSP servers for mason to install.

Either profile can be verified without changing anything:

    > ./.rcboot/darwin.sh --ensure [--minimal]

Restart your terminal (or `exec zsh`) when it finishes.

-------------------------------------------------------------------------------
LAYOUT
-------------------------------------------------------------------------------

    .rcboot/        install scripts (darwin.sh, linux.sh + one folder per tool)
    zsh/            .zshrc loader + rc.d/ fragments (NN-name.zsh), isg theme
    vim/            .vimrc, plugins, color schemes, coc extensions
    nvim/           init.lua + lazy.nvim setup
    tmux/           .tmux.conf
    ghostty/        terminal config
    git/            .gitconfig
    tig/            git TUI config
    fonts/          JetBrains Mono + Computer Modern
    darwin/         Darwin system defaults + Brewfile
    prompt/         shell prompt definitions
    plc/            palace notes system (README.md)
    sh/             standalone scripts (theme toggle, ghostty width)
    manuals/        command and tool reference sheets (*.txt)
    misc/           task log, worktree manifest, inventories

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

   Anything true of this machine rather than of the config — the ssh keys
   log_ssh loads into the agent, paths only this box has — goes in
   ~/.zshrc.local, which .zshrc sources when it is present:

    > cp "$HOME/.rc/zsh/zshrc.local.example" "$HOME/.zshrc.local"

   That file stays outside the repo on purpose. ~/.zshrc is a symlink into the
   working tree, so anything kept on a setup/<machine> branch follows HEAD and
   vanishes the moment you check out something else.

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
  - manuals/splits.txt is the split/pane reference: nvim's <C-w> layer and
    tmux's C-b C-b layer share one set of keys, and it says where they differ.
  - zsh/keys.txt is the command-line key reference: vi mode and the
    nvim-style <Space> leader.
  - sh/toggle_theme.sh switches Darwin light/dark mode and adjacent terminal
    themes in one shot.
  - misc/manifest.txt lists the git worktrees used alongside main.
