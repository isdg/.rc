# Lines stay within 80 columns

In every language, for code, comments, strings and config alike; any
language can break a line, so none is exempt. Break the way the language's
formatter or style guide does, and split long strings with the language's
own concatenation. A line that won't fit is usually a signal to extract a
variable or name things tighter.

A limit the project's formatter enforces (ruff/black `line-length`, rustfmt
`max_width`, prettier `printWidth`) wins, or it would just re-join the
lines; only what can't be broken — URLs, external identifiers, generated
files, lockfiles — may overflow. Don't reflow lines you aren't touching.
