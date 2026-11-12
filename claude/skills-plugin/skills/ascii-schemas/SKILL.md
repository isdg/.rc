---
name: ascii-schemas
description: Use when the user asks for a schema, an ASCII diagram, or to draw, depict or visualize how something works, what a PR or plan changes ("schema before and after", "explain 737 on schema"), or where a piece fits in an earlier schema; also when they say they don't get an explanation of a flow, topology, layering or state over time.
---

# ASCII schemas

A schema is a picture in the terminal: a fenced block of monospace text,
drawn with Unicode box-drawing. No Mermaid, HTML page or artifact unless
the user asks for one.

## Before drawing

- **Read first.** A schema is a claim about the system. Every box and
  arrow names a real thing: function, `file:line`, route, key, table, pod,
  flag. Mark what you didn't verify with `?` and say so under it.
- **One question per picture.** Where does it run, in what order, what
  decides, what changed, how state evolves. Several questions get several
  views, labelled A, B, C, with one line saying what each shows.
- **Enter where the user stands.** Start from the trigger they know (the
  tool call, route, cron, click) and follow one request in time order. An
  internal decision or an abstract overview is the wrong first box.

## Pick the shape

| the question                    | shape                                   |
| ------------------------------- | --------------------------------------- |
| where does it run, who owns it  | containment: nested host/pod/process    |
| one request through the code    | call path: numbered steps, `file:line`  |
| order across processes          | swimlanes: a column each, time downward |
| what decides                    | decision table, first match wins        |
| what a PR or plan changes       | before/after in the same layout         |
| how state evolves               | frames: one layout repeated per step    |
| layering                        | stack: user on top, hardware at bottom  |
| where the time goes             | timeline with measured numbers          |

Examples of each are in [SHAPES.md](SHAPES.md).

## Drawing rules

- **Single-width glyphs only:** `─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼`, `═ ║ ╔ ╗ ╚ ╝`,
  `─► ◄─ ▼ ▲ → ←`. No emoji, ✅ ❌ ⚠ ✔ or CJK, no tabs: they shift every
  column after them. Status is text: `OK`, `FAIL`, `!`, `(R1)`.
- **Width:** at most 100 columns in chat, 80 in a file committed to a
  repo. Too wide means split it into views; don't squeeze it.
- **Label every arrow** with the call, protocol or payload, and every
  boundary (process, pod, machine, network hop). Use `──►` for a call and
  `══►` for a stream or socket; add a one-line legend for any other style.
- **Mark where control returns.** Split sync from async at that point:
  "the tool returns here; nobody has joined yet".
- **Problems live on the picture.** Tag a race, bottleneck or bug at its
  exact spot (`(R1)`, `!`), then explain the tags in bullets below.
- **Prose stays short:** one line before the picture, bullets or a table
  after for what a picture can't carry (why, risks, numbers, next steps).

## Follow-ups

- **"In the same schema", "where does X fit":** redraw the same layout
  with X added and marked `◄ new`. Don't switch layouts.
- **"I don't get it":** change the shape, not the volume. New entry point,
  fewer lanes, split views. Ask what's unclear only if you can't tell.
- **"More detailed":** add real names, `file:line`, numbers and host
  boundaries; split into views rather than widen.
- **"ascii":** draw with plain ASCII only: `+ - | < > v ^`.

## Check before sending

Write the draft to a scratch file and run the checker next to this file:
`python3 <skill dir>/check.py <draft>` (add `--width 80` for repo files).
It flags drifted box edges, wide glyphs, tabs and long lines; fix them
and re-run until it prints nothing. About a third of past boxed schemas
shipped with a right edge one column off.
