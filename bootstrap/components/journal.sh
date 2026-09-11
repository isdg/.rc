#!/usr/bin/env bash
# Component: bootstrap journal — a git-commit prompt for dotfile modifications
# Requires: DOTFILES_DIR, and helpers.sh + dotfiles.sh sourced first
#
# A bootstrap run is destructive in a way nothing recorded: it moves whatever
# real file is in the way to a fixed .backup name (clobbering any previous one)
# and silently repoints symlinks that pointed elsewhere. So before a run
# touches anything, this asks the same question `git commit` asks — describe
# what you are about to do — with the modifications listed as comments in the
# buffer. Write a message and the run proceeds and the message is journaled;
# save an empty message and the run aborts having changed nothing.
#
# Only *modifications* reach the buffer: an existing file or directory about to
# be backed up (overwrite), or a symlink about to be repointed (relink). Links
# that are already correct, and brand-new ones, are counted but not listed —
# there is nothing to lose there, and on a clean machine the buffer would
# otherwise be the whole dotfile inventory. Which means the common case, a
# settled machine re-running bootstrap, never opens an editor at all.
#
# Scope is the _dotfile_links table. The one content-destroying site outside it
# is the vim colors directory, which has its own dir-or-per-file fallback.

# Where the record lands. Outside the repo on purpose — a bootstrap run must
# never dirty the tree, the same policy _check_theme_generated states for the
# generated theme files. The isg/ namespace matches the theme mode file at
# ${XDG_CONFIG_HOME:-~/.config}/isg/theme.
_journal_file() {
    echo "${XDG_STATE_HOME:-$HOME/.local/state}/isg/bootstrap.log"
}

# ── Run state ─────────────────────────────────────────────────────────────────
# _JOURNAL_MODS holds one `state|label|dst|src|detail` record per modification.
# detail comes last so a '|' in a path cannot break the split, and is rendered
# rather than recomputed: by the time the entry is written the old symlink
# target is gone, so readlink at that point would report the new one.
_JOURNAL_MODS=()
_JOURNAL_OK=0
_JOURNAL_NEW=0
_JOURNAL_MESSAGE=""
_JOURNAL_WRITTEN=0

# Flags, set by the entry script's argument loop.
BOOTSTRAP_MESSAGE="${BOOTSTRAP_MESSAGE:-}"
BOOTSTRAP_NO_JOURNAL="${BOOTSTRAP_NO_JOURNAL:-0}"
BOOTSTRAP_PLAN_ONLY="${BOOTSTRAP_PLAN_ONLY:-0}"

# ── Bits of context for the header ────────────────────────────────────────────
_journal_os() {
    uname -s | tr '[:upper:]' '[:lower:]'
}

_journal_host() {
    hostname -s 2>/dev/null || echo unknown
}

_journal_profile() {
    if [ "${BOOTSTRAP_MINIMAL:-0}" = "1" ]; then echo minimal; else echo full; fi
}

# Branch, short SHA and the shell prompt's own dirty marker (* dirty, = clean,
# per ZSH_THEME_GIT_PROMPT_DIRTY/CLEAN) for the checkout being installed from.
# This is what ties an entry to the commit it was bootstrapped out of.
_journal_repo() {
    local d="${DOTFILES_DIR:-$HOME/.rc}" sha ref
    sha="$(git -C "$d" rev-parse --short HEAD 2>/dev/null)" || {
        echo "(not a git checkout)"
        return 0
    }
    ref="$(git -C "$d" symbolic-ref --short HEAD 2>/dev/null)" || ref="detached"
    if [ -n "$(git -C "$d" status --porcelain 2>/dev/null | head -1)" ]; then
        echo "$sha $ref *"
    else
        echo "$sha $ref ="
    fi
}

# ${p/#$HOME/\~} would be shorter, but leaves the backslash in the output.
_journal_tilde() {
    local p="$1"
    case "$p" in
        "$HOME")   echo "~" ;;
        "$HOME"/*) echo "~${p#"$HOME"}" ;;
        *)         echo "$p" ;;
    esac
}

# ── The plan ──────────────────────────────────────────────────────────────────
_journal_collect() {
    _JOURNAL_MODS=()
    _JOURNAL_OK=0
    _JOURNAL_NEW=0

    local label kind src dst state detail
    while IFS='|' read -r label kind src dst; do
        state="$(_link_state "$src" "$dst")"
        case "$state" in
            ok)
                _JOURNAL_OK=$((_JOURNAL_OK + 1))
                ;;
            new)
                _JOURNAL_NEW=$((_JOURNAL_NEW + 1))
                ;;
            overwrite)
                detail="saved as $(_journal_tilde "$dst").backup"
                _JOURNAL_MODS+=("$state|$label|$dst|$src|$detail")
                ;;
            relink)
                detail="was -> $(_journal_tilde "$(readlink "$dst" 2>/dev/null)")"
                _JOURNAL_MODS+=("$state|$label|$dst|$src|$detail")
                ;;
        esac
    done < <(_dotfile_links)
}

# One aligned pair of lines per modification, every line carrying $1 as its
# prefix — so the same renderer fills the '#   ' comment block in the editor
# buffer and the '    ' indented body of a journal entry.
_journal_render() {
    local prefix="$1" entry state label dst src detail
    for entry in "${_JOURNAL_MODS[@]}"; do
        IFS='|' read -r state label dst src detail <<< "$entry"
        printf '%s%-9s  %-30s -> %s\n' \
            "$prefix" "$state" "$(_journal_tilde "$dst")" "${src#"$DOTFILES_DIR"/}"
        printf '%s%-9s  %s\n' "$prefix" "" "$detail"
    done
}

_journal_summary() {
    printf '%d to modify · %d already in place · %d new\n' \
        "${#_JOURNAL_MODS[@]}" "$_JOURNAL_OK" "$_JOURNAL_NEW"
}

# ── The editor buffer ─────────────────────────────────────────────────────────
_journal_buffer() {
    local tmp="$1"
    {
        echo ""
        printf '# Bootstrap: %s · %s profile · %s\n' \
            "$(_journal_os)" "$(_journal_profile)" "$(_journal_host)"
        printf '# Dotfiles: %s\n' "$(_journal_repo)"
        echo "#"
        echo "# Write a message describing this bootstrap. Lines starting with '#' are"
        echo "# ignored, and an empty message aborts the run without changing anything."
        echo "#"
        echo "# Modifications to be made:"
        _journal_render "#   "
        echo "#"
        printf '# %s\n' "$(_journal_summary)"
    } > "$tmp"
}

# The message as git would read it: comment lines dropped, trailing whitespace
# trimmed, surrounding blank lines removed. Empty output means abort.
_journal_message_from() {
    grep -v '^#' "$1" | awk '
        { sub(/[[:space:]]+$/, ""); line[NR] = $0; if (NF) last = NR }
        END {
            for (i = 1; i <= last; i++) {
                if (started || line[i] != "") { started = 1; print line[i] }
            }
        }
    '
}

# Can we actually open the terminal? Not `[ -e /dev/tty ]`: the device node
# exists in a CI container or under a pipe with no controlling terminal, and
# only opening it says so — otherwise a headless run aborts on "Device not
# configured" instead of proceeding without a message. The subshell keeps the
# descriptor from leaking into the editor.
_journal_has_tty() {
    ( exec 3< /dev/tty ) 2>/dev/null
}

# $EDITOR is nvim in an interactive shell, but is routinely unset here —
# bootstrap runs under bash and .zshenv does not export it — so the
# ${EDITOR:-nvim} fallback the rest of this repo uses is the real code path,
# not a nicety.
_journal_prompt() {
    if ! _journal_has_tty; then
        echo "[WARN] Non-interactive; proceeding with no bootstrap message."
        _JOURNAL_MESSAGE="(no message: non-interactive run)"
        return 0
    fi

    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/BOOTSTRAP_EDITMSG.XXXXXX")" || return 1
    _journal_buffer "$tmp"

    # </dev/tty because the caller's stdin is the component registry's process
    # substitution, and >/dev/tty so a full-screen editor still reaches the
    # terminal when the run is being piped or tee'd to a file.
    if ! ${EDITOR:-nvim} "$tmp" </dev/tty >/dev/tty 2>&1; then
        rm -f "$tmp"
        echo "[ABORT] Editor exited non-zero; nothing changed."
        return 1
    fi

    _JOURNAL_MESSAGE="$(_journal_message_from "$tmp")"
    rm -f "$tmp"

    if [ -z "$_JOURNAL_MESSAGE" ]; then
        echo "[ABORT] Empty message; bootstrap aborted, nothing changed."
        return 1
    fi
}

# ── Writing the entry ─────────────────────────────────────────────────────────
_journal_write() {
    local note="${1:-}" file
    file="$(_journal_file)"
    mkdir -p "$(dirname "$file")" || return 0

    {
        printf 'bootstrap %s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)"
        printf 'Host:     %s · %s · %s\n' \
            "$(_journal_host)" "$(_journal_os)" "$(_journal_profile)"
        printf 'Dotfiles: %s\n' "$(_journal_repo)"
        echo ""
        # s/./    &/ and not s/^/    /: indents the body without leaving four
        # spaces of trailing whitespace on a multi-line message's blank lines.
        printf '%s\n' "$_JOURNAL_MESSAGE" | sed 's/./    &/'
        echo ""
        _journal_render "    "
        if [ -n "$note" ]; then
            printf '\n    %s\n' "$note"
        fi
        echo ""
    } >> "$file"

    _JOURNAL_WRITTEN=1
}

# Between the prompt and the end of the run the changes are actually being
# applied, so a crash in there must not lose the record: write the entry
# whatever the exit status, marked when the run did not reach the end.
_journal_on_exit() {
    if [ "$_JOURNAL_WRITTEN" = "1" ]; then
        return 0
    fi
    _journal_write "! run exited $1 before completion"
}

# ── Public surface ────────────────────────────────────────────────────────────

# --plan: what a run would modify, then stop. Also the way to exercise all of
# the above without an editor.
bootstrap_journal_plan() {
    _journal_collect
    echo "[STEP] Planning dotfile modifications..."
    _journal_render "  "
    echo "[INFO] $(_journal_summary)"
}

# Called before the first component runs. Non-zero means abort the run.
bootstrap_journal_open() {
    if [ "$BOOTSTRAP_NO_JOURNAL" = "1" ]; then
        return 0
    fi

    _journal_collect

    if [ "${#_JOURNAL_MODS[@]}" -eq 0 ]; then
        echo "[SKIP] No dotfile modifications to describe."
        return 0
    fi

    echo "[STEP] $(_journal_summary)"
    _journal_render "  "

    if [ -n "$BOOTSTRAP_MESSAGE" ]; then
        _JOURNAL_MESSAGE="$BOOTSTRAP_MESSAGE"
    else
        _journal_prompt || return 1
    fi

    trap '_journal_on_exit $?' EXIT
}

# Called once every component has run.
bootstrap_journal_commit() {
    if [ "$BOOTSTRAP_NO_JOURNAL" = "1" ] || [ "${#_JOURNAL_MODS[@]}" -eq 0 ]; then
        return 0
    fi
    trap - EXIT
    _journal_write
    echo "[OK] Bootstrap recorded in $(_journal_tilde "$(_journal_file)")"
}
