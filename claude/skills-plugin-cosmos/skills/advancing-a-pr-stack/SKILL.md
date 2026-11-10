---
name: advancing-a-pr-stack
description: Use when the user says a PR was merged ("merged 123",
  "merged, go on", "what is next?") while a stack or a series of PRs is
  open, or asks whether the stack was merged in the right order.
---

# Advancing a PR stack after a merge

"Merged" is the whole instruction: run every step below in one turn and
answer with the report at the end. Don't stop to ask between steps.

1. **Confirm the merge.** `gh pr view <n> --json state,mergedAt,
   mergeCommit,baseRefName`. If it is not `MERGED`, or it merged into a
   stack branch instead of `main`, stop and say so: that is the one
   case that needs the user.
2. **Find what it unblocks.** `gh pr list --author @me --state open
   --json number,title,baseRefName,headRefName`: the PRs whose base was
   the merged branch, plus PRs on `main` that only waited on rollout
   order.
3. **Retarget the next PR.** `gh pr edit <next> --base main`.
4. **Bring it onto main and push.** In its worktree (check
   `git branch --show-current` first, pool worktrees are shared):
   `git fetch origin && git merge origin/main`, resolve to "main + this
   PR's own changes", then a normal push. Never rebase or force-push.
   The push is what starts CI: `ci.yml` ignores the retarget itself.
5. **Check CI started.** `gh pr checks <next>`; if nothing is listed a
   minute after the push, the PR still targets a non-main base or is
   behind main. A red gate goes to the `cosmos-ci-red` skill.
6. **Only the next PR.** Don't merge main up through the rest of the
   stack and don't resolve the higher PRs' conflicts: list which will
   conflict and how each resolves, and leave them.
7. **Continue the plan.** If unbuilt work remains in the plan, start
   it now; "go on" means that.

## Rules that bite here

- **The merged branch is closed.** A fix for a merged PR, or for one the
  user said they would merge, goes on a new branch and PR from `main`.
- **Never merge a PR yourself**, and never push to `main`.
- **Squash merges make conflicts look large.** The child still carries
  the parent's commits; the result must equal main plus the child's own
  diff. Check with `git diff origin/main --stat` before pushing.
- **Push with the exit code visible:** redirect output to a scratchpad
  file and `echo exit=$?`. `git push | grep` hides a failed pre-push.
- **Rollout steps the merge implies** (migration to apply, Vault key,
  `helm upgrade`, deploy order): hand over the exact commands, don't run
  them.

## Report

End with one short block, nothing else:

```
merged   #N  <title>
next     #M  <title>   base main, CI running | green | red: <gate>
then     #P → #Q       (still stacked; #Q will conflict in <file>)
you      <command or action the user must do, if any>
```
