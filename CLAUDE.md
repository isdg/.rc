# .rc

Dotfiles for Darwin and Linux. `README.txt` holds the layout and the
bootstrap; this file holds the rules for changing them.

## Principles

- **Keyboard only.** Every feature has a key path; nothing depends on the
  mouse.
- **Optimized.** Startup time and per-keystroke cost are budgets, defended
  for slow machines and million-line codebases. `time zsh -i -c exit`
  stays under 80 ms: measure it before and after touching a startup file,
  and nothing heavy goes in one.
- **Preferably no framework.** Plain zsh, small composed tools, an `rc.d`
  fragment before a plugin; tpm and lazy.nvim are the exception, at level 3.
- **Screen-centric, zen.** One centred text column (`ghostty` padding, set
  by `ww`), hidden titlebar, quiet status lines. New UI adds no chrome,
  borders or colour that competes with the text.
- **Darwin first, Linux where it can.** Modules branch on `$RC_OS`; a
  Darwin-only tool says so instead of failing on Linux.

## Delivery

- No PRs: land on `main` and push, per the `landing-on-main` skill. Work in
  your own worktree on a `<type>/<scope>/<slug>` branch.
- `~/.rc-main` is shared by several sessions. Never switch branches or merge
  there, except `git merge --ff-only` on `main` after checking the branch.
- `~/.rc` is the live checkout on `setup/<machine>`. Skill and rule changes
  take effect once `main` is merged there ("Merge main into
  setup/<machine>").
- Commit scope is the tool's directory: `feat(tmux)`, `fix(nvim)`,
  `feat(darwin)`.

## Layout

- One tool per top-level directory, installed by `.rcboot/<tool>/module.sh`
  (`link`, or `seed` when the tool rewrites its file) and registered in
  `.rcboot/modules` at the lowest level it fits: 1 downloads nothing, 2 adds
  static binaries, 3 adds runtimes, plugins and GUI apps.
- Shell, tmux, vim and nvim behaviour goes in a numbered `rc.d/NN-name`
  fragment, enabled with `fragment` in its module.
- Packages go in `darwin/Brewfile` under their level with a why-comment, and
  in `.rcboot/packages/linux.sh` where Linux has them.
- Every install has an ensure function, so `boot.sh --ensure` reports drift.
- Machine-only facts go in `~/.zshrc.local` or a `*.local` file; per-machine
  state (`*-active.*`) stays gitignored.

## Theme

- Colours come from `theme/palette.sh` and `theme/templates/`. Don't edit
  generated theme files: run `bash theme/generate.sh` and commit its output.
- Never call the generator from a startup file.

## Tests

- Tests are `*_test.sh` beside their subject. Run the matching one after a
  change, and add one for new logic.

## Tool rules

- tmux: no `unbind` for keys an older config bound; clear those by hand on
  the live server. Unbinding tmux's own defaults is fine.
- zsh banner: the log lines stay in the default foreground on purpose. zsh
  has no `grey` name, so a real grey needs a number.
- Comments: no emoji or key glyphs; spell keys out (Globe, Ctrl+Shift).
