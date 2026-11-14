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

   Short alias on the left; each command opens its note, creating it
   first if it does not exist yet:

    dl  daily [DD MM YY|YYYY]   daily note, today by default

    wk  weekly                  this week's note

    st  shot [-i TEXT|-p DIR|-H]
                                timestamped snapshot, in the daily dir
                                unless -p; -i inline body, -H no header

    nt  note NAME               NAME in the notes dir that plc config
                                notes names (plc add)

        ptop                    TOP.md, the vault landing page (plc top)

    td  todo                    the last do-note
        todo -n                 new do-note for this week
        todo -L | -l FILE       list do-notes | mark FILE last (no
                                editor)

    mm  murmur                  new murmur note, prompts for its name
        murmur -l               fzf-pick a murmur note

    ii  isg                     the last isg note (isg0, isg1, ...)
        isg -c                  next isg note
        isg --continue [N]      continue N, or the latest: isg<N>a, ...
        isg --list | NAME       fzf-pick an isg note | open NAME

        pst [DD [MM [YY]]] [-f FORMAT]
                                bytes written (plc stat): a day lists its
                                notes, - for a whole field draws a month
                                (- MM YY) or a year (- - YY); -f grid,
                                rows, plot, list or tsv

   daily, shot, note, todo -n and isg pass plc's creation flags
   through: -x TEXT appends a filename postfix, -t TAG seeds a [[TAG]]
   link.

   plc cd [DIR] cds into the vault, or DIR inside it: a zsh function,
   since a process can't move its shell. Every other plc call reaches
   the binary, which prints paths and never opens an editor: plc top,
   plc ledger (lr), plc graph, orphans, doctor [--fix], config, init;
   plc help lists them all.

3. plc-lsp in nvim (nvim/lua/plugins/lsp.lua): attached to markdown
   buffers under the vault only. gd follows the [[link]] under the cursor
   (to a note, a #heading, or a ledger name's line in .plc/config), gr
   lists a link's uses or the note's backlinks, and typing [[ completes
   note and ledger names.

4. nvim palace layer (nvim/rc.d/10-keys-plugins.lua): <leader><leader>p,
   then t / T insert an "isg" timestamp / a bare one at the cursor, and
   a / A pick notes in fzf, newest first, and put [[links]] to them after
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
