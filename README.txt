
DOTFILES
========

A minimal, keyboard-driven dev environment for macOS and Linux.
Built for older hardware and large codebases (~1M lines) where heavy
IDEs feel sluggish.

Includes configs for:
  - Zsh (plain zsh, no framework + isg theme (forked from sobole) + fzf)
  - Vim and Neovim
  - Tmux (with TPM + tmux-resurrect)
  - Ghostty, VSCode, Zed
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
tig, vscode, key remapping, and macOS defaults.

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
BOOTSTRAP MESSAGES
-------------------------------------------------------------------------------

A bootstrap run is destructive in two ways worth noticing before the fact: it
moves an existing real file out of the way to a fixed `.backup` name (which
overwrites any earlier backup of the same file), and it silently repoints a
symlink that pointed somewhere else. So a run that would do either opens
$EDITOR on a git-commit-style buffer listing exactly those files:

    # Bootstrap: darwin · full profile · isg-darwin
    # Dotfiles: 3cf3548 main *
    #
    # Write a message describing this bootstrap. Lines starting with '#' are
    # ignored, and an empty message aborts the run without changing anything.
    #
    # Modifications to be made:
    #   overwrite  ~/.tmux.conf     -> tmux/.tmux.conf
    #              saved as ~/.tmux.conf.backup
    #   relink     ~/.config/nvim   -> nvim
    #              was -> ~/old-nvim
    #
    # 2 to modify · 12 already in place · 9 new

Same contract as `git commit`: write a message and the run proceeds, save an
empty one and it aborts having changed nothing. Links that are already correct
and brand-new ones are counted but not listed — nothing is at stake there — so
a settled machine re-running bootstrap gets no prompt at all.

Accepted messages are appended to:

    ${XDG_STATE_HOME:-~/.local/state}/isg/bootstrap.log

with the timestamp, host, profile, and the branch/commit/dirty state of the
checkout it was run from. That file lives outside the repo on purpose, so a
bootstrap run never dirties the tree.

    > ./bootstrap/darwin.sh --plan          # list what a run would modify, then stop
    > ./bootstrap/darwin.sh -m 'message'    # describe it without opening an editor
    > ./bootstrap/darwin.sh --no-journal    # skip the prompt and the journal

A run with no terminal (CI, a pipe) skips the prompt and proceeds rather than
blocking. `--ensure` never prompts; it changes nothing to describe.

-------------------------------------------------------------------------------
LAYOUT
-------------------------------------------------------------------------------

    bootstrap/      install scripts (darwin.sh, linux.sh + components/)
    zsh/            .zshrc, aliases, fzf integration, isg theme
    vim/            .vimrc, plugins, color schemes, coc extensions
    nvim/           init.lua + lazy.nvim setup
    tmux/           .tmux.conf
    ghostty/        terminal config
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
  - toggle_theme.sh switches macOS light/dark mode and adjacent terminal
    themes in one shot.
  - manifest.txt lists the git worktrees used alongside main.
