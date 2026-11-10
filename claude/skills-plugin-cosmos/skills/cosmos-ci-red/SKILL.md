---
name: cosmos-ci-red
description: Use when CI is red, missing or stuck on a cosmos-saas pull
  request or on main ("ci is red", "why is CI failing on 123", "no CI
  on this PR", "fix CI"), or when a pre-push hook rejects a push.
---

# Red CI on cosmos-saas

Read the failing log before forming a theory. One workflow (`ci.yml`),
five gate rows, fail-fast inside each: a red run shows one failure per
gate, and the next one appears only after the fix.

## Triage, in this order

```sh
gh pr checks <n>                        # which rows are red, or none
gh pr view <n> --json baseRefName,mergeStateStatus,headRefOid
gh run view <run-id> --log-failed | rg -n -m40 'error|Error|FAILED|✗'
```

1. **No checks at all** → the PR does not target `main`/`release`, or
   was retargeted without a push. `ci.yml` ignores `edited`: merge
   `origin/main` in and push.
2. **`watch:` rows red, gates green** → not your failure. They are
   repo-wide counts, non-blocking; say so and move on.
3. **Red on main too** (`gh run list --branch main --workflow ci.yml
   -L 5`) → not this PR. Merge main once it is fixed; don't patch it
   in the PR.
4. **Branch behind main** (`mergeStateStatus: BEHIND`, or the failure
   is in a file the PR never touched) → merge `origin/main`, push.
5. Otherwise it is the PR's own failure: match it below.

## Known causes

| symptom in the log                                   | cause and fix |
| ---------------------------------------------------- | ------------- |
| "API contract drift", "backend SDK drifted"          | route or model changed: `pnpm backend:typegen`, commit the output |
| `database.types.ts` or Python rows drift             | schema changed: `pnpm db:typegen` (needs the migration applied locally: ask the user) |
| "Different tests were collected between gw3 and gw14" | random value in `parametrize` args: use fixed literals; rerun with `-n 4` |
| `uv lock` freshness                                   | `uv lock`, commit `uv.lock` |
| migration timestamp duplicate                         | a hand-picked timestamp: recreate with `supabase migration new` |
| ty: unused ignore in `cvn/backend/hooks`, or 20+ `redundant-condition-strict` | local env only: rerun the full `uv sync` recipe from the worktree notes; CI is right, the local run is not |
| `ModuleNotFoundError` at API boot in a release job, CI green | API image syncs `--extra api` only, CI syncs all extras: a livekit plugin import reached API code. Repro: `uv sync --frozen --no-dev --package cosmos --extra api` in a scratch venv, then `import cosmos.api.main` |
| knip `Unlisted dependencies` / `Unresolved imports`  | real: fix. `Unused exports`: grep the repo before deleting |
| locale parity                                         | a key added in one language only: add it to every locale |

## Pre-push failures on this machine

- **`pnpm` exits 134 (SIGABRT)** under Homebrew Node 26, which also
  fails the `backend-api-typegen` hook whatever the diff. For a
  backend-only change run `ruff check`, `ruff format --check`, `ty
  check`, vulture and the touched tests by hand, push `--no-verify`,
  and say so in the PR.
- **`ERR_PNPM_EEXIST`** on the first push from a worktree: retry.
- **Commit "succeeds" but nothing is committed** in a pool worktree:
  tracked hook scripts are missing (pre-commit exit 127). Check
  `git status --porcelain | wc -l` and use a clean worktree.

## Fixing

- Reproduce the one failing check locally, scoped: `pnpm exec oxlint
  <paths>`, `pnpm --filter web typecheck`, `uv run pytest <file> -n 4`.
  Never run a build.
- Fix the code. No debt lines in `.oxlintrc.json`, no baselines, no
  `# noqa`, no skipped test to get to green.
- If the user said they are merging the PR, the fix goes on a new
  branch and PR, not on that branch.
- After the push, `gh pr checks <n> --watch` in the background and
  report the final state; a second failure in the same gate is expected
  (fail-fast), not a regression.
