# gleam-language — the standard Gleam "thinking core" reference

This repository is the **standard reference** for the Gleam language doc that
every project loads before writing / reviewing Gleam. It is the single place the
content is maintained; the scattered copies that still live inside individual
project repos are left in place (not overwritten) and are archived here under
`variants/` so their divergence stays auditable.

## What this repo contains

- `gleam-thinking-core.md` — **THE STANDARD.** This is the file to read. It is
  the reconciled canonical: the corrected `glibe` variant **plus** two general
  Erlang-interop gotchas pulled from the `speak_engl` addendum (see
  `COMPARISON.md`). It is the document every project should treat as authoritative.
- `variants/` — the **historical copies** as they were found in the tree, kept
  with provenance so the divergence is auditable and never silently lost:
  - `speak_engl__docs__gleam-thinking-core.md`
    (from `prog_langs/.../speak_engl/docs/gleam-thinking-core.md`)
  - `glibe__docs__gleam-thinking-core-to-memory.md`
    (from `tools_ib/glibe/docs/gleam-thinking-core-to-memory.md`)
- `COMPARISON.md` — the line-level diff analysis: what each variant had, which
  is current, and the per-hunk reconciliation decision.

## Status of the other copies (important)

The other repos keep their own copies **as-is**. They are **not** the standard,
but they are **not** overwritten or deleted either. The `glibe` copy is a
byte-copy of the old base; the `speak_engl` copy is a stale, partly-violating
snapshot. Both remain where they are; this repo simply declares its own
`gleam-thinking-core.md` the standard to read **for now**. Convergence of the
other repos onto this file is a later, owner-approved decision — not done here.

## The reconciliation decision (what makes the standard)

`gleam-thinking-core.md` = the **glibe variant** (corrected, current, and
byte-identical to the skill copy at
`~/.workbuddy/skills/gleam-language/references/gleam-core.md`) **plus** a §8
enrichment: the two *general* Erlang-interop sharp edges the `speak_engl`
addendum named but `glibe`'s §8 only gestured at (the `os:cmd` charlist trap
and `dynamic/decode.field`'s 3-argument form). The `speak_engl` variant's
project-specific remainder (Whisper NIF, `FEASIBILITY.md` §7.1) is excluded as
inappropriate for a shared core. See `COMPARISON.md` for the line-level evidence.

## Sync protocol (going forward)

1. **Edit the standard here first.** Change `gleam-thinking-core.md` in this repo.
2. After any edit, `cmp` it against `variants/glibe__docs__gleam-thinking-core-to-memory.md`
   is no longer required to match — that variant is a historical snapshot, not a
   live mirror. The standard is this file, full stop.
3. **Other repos** (`speak_engl`, `glibe`, the `gleam-language` skill copy) keep
   their existing copies until the owner decides to converge them onto this
   standard. No cross-repo write is performed by this repo.

## Migration status — NOT applied (by owner decision)

The earlier plan to replace the other repos' copies with pointers is **set
aside**. The other repos retain their copies; this repo provides the standard
for now. Revisit only if the owner wants the repos to converge.
