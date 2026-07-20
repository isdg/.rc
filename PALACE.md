# palace — personal knowledge vault

A note-taking system spread across four places in this repo, tied together
by one vault directory (`$PALACE_DIR`, `~/palace/palace`) and one binary
(`plc`). Documented here as a single named module so the pieces don't get
rediscovered from scratch later — see `MODULARIZE.txt`.

## Pieces

1. **`plc` binary** — installed by `bootstrap/components/plc.sh` (clones
   `github.com/isaigordeev/plc`, `cargo install`s it). Creates/resolves note
   files and prints their path; it never opens an editor itself.

2. **`zsh/palace.zsh`** — thin wrappers around `plc` that open the path it
   prints in `$EDITOR`, cd'd into `$PALACE_DIR`. Sourced by
   `zsh/aliases.zsh`, which also exports `PALACE_DIR`.

   | Command | Does |
   |---|---|
   | `daily [DD MM YY\|YYYY]` | open/create a daily note (today by default) |
   | `weekly` | open/create this ISO week's note |
   | `shot` | timestamped daily snapshot note |
   | `tg [-l \| -n]` | manage murmur notes (`-l` = fzf-pick) |
   | `isg [-l \| NAME]` | enumerated isg notes (isg0, isg1, …; `-l` = fzf-pick) |
   | `dn [-n \| -l FILE \| -L]` | manage do-notes (week-based, last-pointer) |
   | `pst [args]` | daily-note activity calendar + stats (`plc stat`) |
   | `dl`, `wk` | short aliases for `daily`, `weekly` |

3. **`vim/palace-link.vim`** — `<leader>nl` in normal mode: fzf-picks any
   file under `$PALACE_DIR`, inserts a `[[wiki-link]]` at the cursor, and
   appends an automatic backlink to the target file. Sourced from both
   `vim/.vimrc` and `nvim/init.lua` (path-resolved so it works regardless of
   where the dotfiles repo is checked out).

4. **nvim datestamps** (`nvim/lua/keymaps/notes.lua`) — `<leader>nt` /
   `<leader>nT` insert an ISO datestamp (local tz / UTC) at the cursor.

## Why it's spread out

Each piece lives with its own kind (zsh commands in `zsh/`, a Vimscript
plugin in `vim/`, an installer in `bootstrap/`) rather than under one
`palace/` directory, so it follows the rest of the repo's per-concern
layout. This file is the map between them.
