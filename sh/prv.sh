#!/bin/bash
# Backend for the `prv` PR picker (zsh/rc.d/16-fzf.zsh). fzf runs reloads and
# key actions in a fresh shell, where zsh functions don't exist, so they live
# here.
#
#   prv.sh list [QUALIFIER...]   one row per open PR involving me
#   prv.sh merge REPO NUMBER     confirm, then `gh pr merge --merge`
#
# A row is `repo<TAB>number<TAB>display`. The display starts with an
# orchbus-style state cell, worst state first:
#   [!] conflicts   [x] checks failing   [c] changes requested   [d] draft
#   [~] checks running   [?] GitHub still computing mergeability
#   [✓] mergeable, checks green or absent
set -u

QUERY='query($q: String!) {
  search(query: $q, type: ISSUE, first: 100) {
    nodes { ... on PullRequest {
      number title isDraft updatedAt mergeable reviewDecision
      author { login }
      repository { name nameWithOwner }
      commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
    } }
  }
}'

JQ='
def cell:
  (.commits.nodes[0].commit.statusCheckRollup.state // "NONE") as $ci
  | if .mergeable == "CONFLICTING" then "\u001b[31m[!]"
    elif $ci == "FAILURE" or $ci == "ERROR" then "\u001b[31m[x]"
    elif .reviewDecision == "CHANGES_REQUESTED" then "\u001b[31m[c]"
    elif .isDraft then "\u001b[2m[d]"
    elif $ci == "PENDING" or $ci == "EXPECTED" then "\u001b[33m[~]"
    elif .mergeable == "UNKNOWN" then "\u001b[2m[?]"
    else "\u001b[32m[✓]" end
  | . + "\u001b[0m";
def age:
  (now - (.updatedAt | fromdate)) as $s
  | if $s < 3600 then "\($s / 60 | floor)m"
    elif $s < 86400 then "\($s / 3600 | floor)h"
    else "\($s / 86400 | floor)d" end;
.data.search.nodes[]
| [.repository.nameWithOwner, .number, cell,
   "\(.repository.name)#\(.number)", .title, .author.login, age]
| @tsv'

list() {
  gh api graphql -f query="$QUERY" \
    -f q="is:pr is:open involves:@me sort:updated-desc $*" --jq "$JQ" \
    | awk -F'\t' -v OFS='\t' '
        { row[NR] = $0; if (length($4) > w) w = length($4) }
        END {
          for (i = 1; i <= NR; i++) {
            split(row[i], f, "\t")
            printf "%s\t%s\t%s  %-*s  %s  \033[2m· %s, %s\033[0m\n",
              f[1], f[2], f[3], w, f[4], f[5], f[6], f[7]
          }
        }'
}

merge() {
  local repo=$1 number=$2 answer
  read -r -p "merge ${repo}#${number} with --merge? [y/N] " answer
  [[ $answer == [yY] ]] || return 0
  gh pr merge --merge "$number" -R "$repo"
  read -r -p "press enter to go back "
}

case ${1:-} in
  list) shift; list "$@" ;;
  merge) shift; merge "$@" ;;
  *) echo "usage: prv.sh list [QUALIFIER...] | merge REPO NUMBER" >&2
     exit 2 ;;
esac
