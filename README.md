# gleam-language — single source of truth for the Gleam "thinking core"

This repository is the **single source of truth** for the Gleam language
reference that every project loads before writing/ reviewing Gleam. It replaces
the scattered, drifted copies that used to live inside individual project repos.

## What this repo contains

- `gleam-thinking-core.md` — **the canonical document.** This is the one file
  every project should read. It is byte-identical to the corrected copy found in
  `glibe/docs/gleam-thinking-core-to-memory.md`, which in turn is the git mirror
  of the skill copy at
  `~/.workbuddy/skills/gleam-language/references/gleam-core.md`.
- `variants/` — the **historical copies** discovered in the tree, kept with their
  provenance so the divergence is auditable:
  - `speak_engl__docs__gleam-thinking-core.md`
    (from `prog_langs/.../speak_engl/docs/gleam-thinking-core.md`)
  - `glibe__docs__gleam-thinking-core-to-memory.md`
    (from `tools_ib/glibe/docs/gleam-thinking-core-to-memory.md`)
- `COMPARISON.md` — the diff analysis: what each variant had, which is current,
  and why the canonical is what it is.

## Why this repo exists

The same document was copied into several projects. Because each project's AI
kept editing its local copy, the copies **drifted**. One copy (`speak_engl`)
is a stale pre-correction snapshot that still *violates* standing owner rulings
(R21 constructors spelled out; R49 no `new`). The other (`glibe`) is the
corrected, current version. Having N copies means N places to forget to fix.

This repo collapses N → 1.

## The reconciliation decision

`gleam-thinking-core.md` = the **glibe variant**, because it is the corrected,
current version and it equals the skill's authoritative copy. The `speak_engl`
variant contributes nothing the canonical lacks (its only unique paragraph is a
project-scoped note already absorbed into §8); its R21/R49 violations must not
propagate. See `COMPARISON.md` for the line-level evidence.

## Sync protocol (do this, not the old way)

1. **Edit here first.** Change `gleam-thinking-core.md` in this repo.
2. **Propagate** to the two places that must stay in lock-step:
   - the skill copy: `~/.workbuddy/skills/gleam-language/references/gleam-core.md`
   - the project mirror: `tools_ib/glibe/docs/gleam-thinking-core-to-memory.md`
   (`cmp` the three after any edit; they must be identical).
3. **Other projects** (`speak_engl`, etc.) should stop carrying their own copy.
   Replace their local `gleam-thinking-core*.md` with a one-line pointer to this
   repo (or delete it and rely on the skill load). They must never re-fork the
   content.

## Migration status (action needed in other repos)

- [ ] Replace `speak_engl/docs/gleam-thinking-core.md` with a pointer to this repo.
- [ ] Confirm `glibe/docs/gleam-thinking-core-to-memory.md` stays a byte-copy of this file.
- [ ] Confirm the skill copy at `~/.workbuddy/skills/gleam-language/references/gleam-core.md`
      stays a byte-copy of this file.

These edits touch other repos and have **not** been applied yet — they are
flagged here for the owner to approve before any cross-repo write.
