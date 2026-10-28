---
name: landing-on-main
description: Use when committing, finishing or delivering a change in a git repo the user owns personally (its GitHub owner is the user's own login, e.g. the dotfiles repo), or before opening a PR in one.
---

# Landing on main

In a repo the user owns, finished work lands on local `main` and is pushed
straight to `origin/main`: no PR. This is the user's standing exception to
"I do the merge" and "never push straight to main"; everywhere else those
rules hold and the `pr-conventions` skill applies.

- **Owned means owner == you.** Check before relying on this skill:
  `gh repo view --json owner -q .owner.login` must equal
  `gh api user -q .login`. Org repos fail the check even with admin rights.
  So does a repo with no GitHub remote or a failing `gh`: fall back to PRs.
- **Branch in your own worktree.** Commit on a `<type>/<scope>/<slug>`
  branch in a worktree only you use. A shared checkout can switch HEAD under
  you, and then `commit` and `merge` hit someone else's branch. Commits stay
  small, one change each, titles within 50 characters.
- **Catch up, then land.** `git fetch origin`, rebase the branch onto
  `origin/main`, re-run the repo's checks, then fast-forward `main`:
  `git fetch . <branch>:main`. It never touches another checkout's HEAD.
  If git refuses because `main` is checked out elsewhere, confirm that
  checkout is on `main` and clean, and run `git merge --ff-only <branch>`
  there in the same command. Never a merge commit, never a squash.
- **Push main, nothing else.** First read `git log origin/main..main`: it
  may hold other sessions' landed commits, and they go up with yours. If
  anything there is not finished work, stop and ask. Then
  `git push origin main`. Never force. A rejected push means `main` moved:
  fetch, rebase the branch, land and push again. A rejection from branch
  protection means this repo wants PRs after all: say so and open one.
- **Clean up.** Once `main` is pushed, delete the branch and finish the
  worktree per the `worktrees` skill.
- **The user can still say "PR".** An explicit ask for a PR or a review,
  or a change risky enough that you would want one, beats this skill: ask.
