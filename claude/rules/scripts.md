---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
  - "**/Makefile"
  - "**/Dockerfile"
  - "**/justfile"
  - ".github/**"
---

# Scripts you commit

Code that ships in a repo and may run where `rg` isn't installed (CI,
containers, other machines) keeps using `grep`, unless the project already
depends on `rg`.
