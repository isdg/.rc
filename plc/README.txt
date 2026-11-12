PALACE
======

A personal knowledge vault: a note-taking system spread across four places
in this repo, tied together by one vault directory (~/palace) and one
binary (plc). The vault is the vault line of plc/plcrc, linked to
~/.plc/.plcrc; $PALACE_DIR overrides it for one process. plc only reads
the file. ~/.plc/<vault>/ holds this machine's state for each vault.

Documented here as a single named module so the pieces don't get
rediscovered from scratch later (see misc/modularize.txt).


-------------------------------------------------------------------------------
PIECES
-------------------------------------------------------------------------------

1. The plc and plc-lsp binaries, installed by .rcboot/plc/plc.sh (clones
   github.com/isdg/plc, cargo installs both). plc creates/resolves note
   files and prints their path; it never opens an editor itself.

2. zsh/palace.zsh: thin wrappers around plc that open the path it prints
   in $EDITOR, cd'd into the vault `plc config` names. Sourced by
   zsh/rc.d/15-aliases.zsh. Change the vault in plc/plcrc, or for one
   command with PALACE_DIR=PATH.

    daily [DD MM YY|YYYY]       open/create a daily note (today by default)
    weekly                      open/create this ISO week's note
    shot                        timestamped daily snapshot note
    tg [-l | -n]                manage murmur notes (-l = fzf-pick)
    isg [-l | NAME]             enumerated isg notes (isg0, isg1, ...;
                                -l = fzf-pick)
    dn [-n | -l FILE | -L]      manage do-notes (week-based, last-pointer)
    pst [args]                  daily-note activity calendar + stats
                                (plc stat)
    plc cd [DIR]                cd into the vault, or DIR inside it (a zsh
                                function: every other plc call reaches
                                the binary)
    dl, wk                      short aliases for daily, weekly

3. plc-lsp in nvim (nvim/lua/plugins/lsp.lua): attached to markdown
   buffers under the vault only. gd follows the [[link]] under the cursor
   (to a note, a #heading, or a ledger name's line in .plc/config), gr
   lists a link's uses or the note's backlinks, and typing [[ completes
   note and ledger names.

4. nvim palace layer (nvim/rc.d/10-keys-plugins.lua): <leader><leader>p,
   then t / T insert an "isg" timestamp / a bare one at the cursor, and
   l / L pick notes in fzf, newest first, and put [[links]] to them after
   / before the cursor, as p and P paste (nvim/lua/palace.lua). Its test
   needs plc, rg and fzf-lua:

    > nvim --clean --headless -l nvim/tests/palace_link.lua

   g opens `plc graph` in its own tab, the vault drawn like git log
   --graph, on the note you were in (nvim/lua/palace_graph.lua). j / k
   step between notes, p / c go to the parent / newest child (P / C pick
   one in fzf), <C-i> retraces those jumps, u hides notes without links,
   <CR> opens the note in the tab you came from, ? lists the keys. Its
   test needs plc and fzf-lua:

    > nvim --clean --headless -l nvim/tests/palace_graph.lua

-------------------------------------------------------------------------------
WHY IT'S SPREAD OUT
-------------------------------------------------------------------------------

Each piece lives with its own kind (zsh commands in zsh/, a Vimscript
plugin in vim/, an installer in .rcboot/) rather than under one palace/
directory, so it follows the rest of the repo's per-concern layout. This
file is the map between them.
