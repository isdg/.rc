# minimal git_prompt_info — the one oh-my-zsh function the theme uses
#
# ONE git call, not the two this used to make. `status --porcelain=v2 --branch`
# answers everything at once: the branch name, the upstream, how far ahead and
# behind it is, and — in the lines after the header — whether anything is dirty.
# symbolic-ref, the rev-parse fallback and the plain status all collapse into
# it. Measured in this repo, 26.6ms -> 13.3ms per prompt.
#
# The header is fixed-shape and easy to read line by line:
#     # branch.oid <sha>            always
#     # branch.head <name>          or "(detached)"
#     # branch.upstream <ref>       absent when there is none
#     # branch.ab +N -M             absent when there is no upstream
# so a missing upstream needs no special case: ab stays empty and the sync
# field renders as nothing. Detached HEAD falls back to the short oid, which
# the header already carries — that is what used to cost the second call.
#
# The loop breaks on the first non-header line: the dirty flag only needs to
# know that ONE exists, and a repo with thousands of changed files should not
# be read to the end to discover it.
#
# +N / -M rather than arrows, matching the ascii */= below. Both are only as
# fresh as the last fetch — nothing here touches the network, so "behind" means
# behind as of whenever you last looked.
#
# A tag field lived here briefly and was removed: --exact-match made it empty
# except on a release commit, which is not worth a call.
git_prompt_info() {
    local line ref="" oid="" ab="" dirty=""
    while IFS= read -r line; do
        case $line in
            "# branch.head "*) ref=${line#\# branch.head } ;;
            "# branch.oid "*)  oid=${line#\# branch.oid } ;;
            "# branch.ab "*)   ab=${line#\# branch.ab } ;;
            "# "*)             ;;
            *)                 dirty=1; break ;;
        esac
    done < <(command git status --porcelain=v2 --branch 2>/dev/null)
    [[ -n $ref ]] || return 0
    [[ $ref == "(detached)" ]] && ref=${oid[1,7]}

    local ahead=${${ab%% *}#+} behind=${${ab##* }#-} sync=""
    (( ahead ))  && sync+=" ${ZSH_THEME_GIT_PROMPT_AHEAD}+${ahead}%{$reset_color%}"
    (( behind )) && sync+=" ${ZSH_THEME_GIT_PROMPT_BEHIND}-${behind}%{$reset_color%}"

    local state=$ZSH_THEME_GIT_PROMPT_CLEAN
    [[ -n $dirty ]] && state=$ZSH_THEME_GIT_PROMPT_DIRTY
    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${state}${sync}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

source "$ISGRC/zsh/isg.zsh-theme"
