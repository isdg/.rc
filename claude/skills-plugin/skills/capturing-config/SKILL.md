---
name: capturing-config
description: Use after installing a tool or package, or changing machine or tool configuration outside the dotfiles repo (brew install, a ~/.config file, defaults write, a global npm/cargo/uv tool, a launch agent), to propose recording it in the dotfiles repo.
---

# Capturing config

A setup change made by hand lives only on this machine. Offer to record it
as a commit in the dotfiles repo (`~/.rc`, main checkout `~/.rc-main`), so
a future bootstrap reproduces it and `git log` explains it. The machine
already has the change: recording it is a commit, never a re-install.

- **Ask whether it belongs first.** Once the change works, ask in one or
  two lines whether the user wants it kept, and where you would put it.
  Their answer decides what goes in and where; a "no" ends it. Skip the
  offer for throwaway experiments, project-local setup (a repo's own venv
  or `node_modules`), and anything already tracked: `rg` the repo first.
- **Secrets and one-box facts stay out.** Keys, tokens, hostnames and paths
  only this machine has go in `~/.zshrc.local` or a `*.local` file the
  module leaves untracked; the repo may hold the template.
- **Fit the existing seams.** Read `README.txt` (LAYOUT) and the nearest
  sibling module, and copy its shape:
  - Homebrew formula or cask: `darwin/Brewfile`, in the lowest level block
    whose tools need it, with a short why-comment like its neighbours;
    Linux too where `.rcboot/packages/linux.sh` can install it.
  - A tool's config file: `<tool>/` at the repo root, put in place by
    `.rcboot/<tool>/module.sh` with `link`, or `seed` when the tool
    rewrites the file itself.
  - Shell, tmux, vim or nvim behaviour: a new `<tool>/rc.d/NN-name`
    fragment, enabled with `fragment` in the owning module; never append to
    an unrelated fragment.
  - An install that is not a package: `install_<x>` / `ensure_<x>` in
    `.rcboot/<x>/<x>.sh`, run by `step` in its module.
  - A new module: register it in `.rcboot/modules` at its level, and add a
    LAYOUT line to `README.txt` for a new top-level directory.
  - macOS defaults: `darwin/defaults.sh`.
- **Make --ensure see it.** Every install gets an ensure function, so
  `boot.sh --ensure` reports drift instead of passing silently.
- **Commit, don't run.** Commit as `feat(<tool>): ...` and land it per
  the `landing-on-main` skill. Don't run `boot.sh` or any module: nothing
  here needs installing again.
