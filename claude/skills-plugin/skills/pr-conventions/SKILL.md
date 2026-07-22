---
name: pr-conventions
description: Use when opening a pull request, deciding how to size or split a change, sequencing multi-part work across PRs, or naming a branch.
---

# PR conventions

Keep pull requests small and type-focused so they stay reviewable. Size
expectations depend on the PR *type*:

- **Feature** — roughly **200–450 added lines AND few deletions** (net-positive
  new code; keep both sides small). If building the feature makes other code
  dead, do that removal in a **separate cleanup PR** — don't bundle large
  deletions into a feature PR.
- **Cleanup / removal** — ~0 adds, deletions any size (deletes are cheap to
  review).
- **Refactor** — roughly equal adds/deletes (net ≈ 0).
- **Pure rename/move** — large diff but trivial; call it out in the description.

When implementing multi-part work, land it as a sequence of small PRs
(e.g. foundation → UI → cleanup) and let the user merge each before continuing.
That consecutive ordering is for **dependent** PRs (each builds on the last);
**independent** PRs are the exception — open them in parallel, with no need to
wait for a merge between them.

If a feature (or any change) can't fit in one reasonably-sized PR, **propose a
split up front** — break it into a sequence of PRs and include **tests at each
intermediate step** so every PR is independently verifiable and safe to merge
before the next one lands.
*Added* lines are the real review cost, so bound them; but a feature shouldn't
also carry heavy deletions.

## Branch naming

Name every branch `<type>/<scope>/<slug>` — e.g. `fix/scribe/pagination`,
`chore/general/tests`.

- **type** — the change kind: `feat`, `fix`, `refactor`, `chore`, `cleanup`,
  `docs`.
- **scope** — the affected area/component (e.g. `scribe`); use `general` when
  no single scope fits.
- **slug** — a short kebab-case description of the change (e.g. `pagination`,
  `tests`).

## Size scale

Use *added + changed* lines as the size signal; **deletions count much less**
(a mostly-deletion PR is cheap to review and is a healthy sign, not a risk).

- **XS** 0–9 · **S** 10–49 · **M** 50–249 · **L** 250–999 · **XL** 1000+

Aim for **S–M**. An **L/XL** is a signal to split. (The 200–450 feature target
is already an "L" — prefer < 250 when the work allows.)

## PR etiquette

- **One logical change per PR** — one feature, one fix, or one refactor. Never
  bundle unrelated changes.
- **Good description** — first line = summary; body = *what* and *why*. Avoid
  bare "fix bug"-style messages.
- **Improve-the-codebase bar** — approve/merge when the PR clearly improves
  things; don't hold out for perfection.
- **Big moves/renames** are low-risk despite huge diffs — say "this is just a
  move" in the description so the size doesn't alarm the reviewer.
