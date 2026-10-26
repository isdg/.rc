---
name: worktrees
description: Use when creating, entering, finishing or removing a git worktree, when a session, subagent or workflow runs in one, or before the first push from a wt/ branch.
---

# Worktrees

- **Where they go.** `--worktree`, isolated subagents, workflow agents and
  background sessions get a worktree from `~/.claude/hooks/worktree.sh`:
  `~/<repo>-<name>` on branch `wt/<name>`, cut from origin's default branch.
  Rename the branch to `<type>/<scope>/<slug>` (`git branch -m`) before its
  first push; until then a hook refuses `git push` and `gh pr create`.
- **Done means upstream.** Before you finish, commit and push everything
  worth keeping. A worktree is garbage once it is clean and every commit is
  on a remote or already merged (squash merges count).
- **Collect your own garbage.** When the work is done, leave the worktree
  with `ExitWorktree` and remove it. What's left behind — subagent and
  workflow worktrees are never removed for you — is swept at session start
  once it is a day old, clean, unlocked, upstream and no live session works
  in it; `~/.claude/hooks/worktree.sh gc --dry-run` lists what would go.
- **Never remove work.** Don't delete a worktree with uncommitted or
  unpushed changes, or one the hook didn't make (the main checkout, a
  pooled worktree). Neither the hook nor the sweep will.
