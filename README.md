# gleam-language — the Gleam knowledge centre under `gits/`

Owner rulings 2026-11-13, verbatim:

> "不要链接目录结构，仅去硬link gleam-thinking-core 那个文件，因为各自的项目中有几个版本，造成混乱必须设计这个单一数据源"
>
> "skill等等文档也一样处理，放在哪里，谁用谁链接就行了，单一文件链接，说link的时候，在unix世界就是指单独文件的"
>
> "这样在我的 gits/里面就有了一个gleam语言的skill等等资料中心。各project不用去各自为政，混乱不堪"

This repository is that centre. It is a real Gleam package, a flat shelf of
single-file hard links, and ONE canonical thinking-core file. Projects do not
keep their own copies any more; whoever needs a file links to it.

## 1. One file, one link — the thinking core

`gleam-thinking-core.md` at the root of this repo is the single source. These
four names are **one file**, not four versions (same inode, same bytes):

| Name | Role |
|---|---|
| `/Users/jk/gits/gleam-language/gleam-thinking-core.md` | canonical name in the centre |
| `~/.workbuddy/skills/gleam-language/references/gleam-core.md` | the skill's authoritative copy |
| `tools_ib/glibe/docs/gleam-thinking-core-to-memory.md` | glibe's git-tracked mirror |
| `prog_langs/.../speak_engl/docs/gleam-thinking-core.md` | speak_engl's former stale copy |

Measured 2026-11-13: all four are inode `337552766`, `22713` bytes, `cmp`
identical. The stale 325-line `speak_engl` variant (R21 / R49 violations) and
the enriched "standard" are no longer live content — both are preserved under
`variants/`. `COMPARISON.md` still records the line-level decisions, including
the two general Erlang-interop gotchas that the enriched version had added to
§8.

Verify at any time:

```
stat -f '%i %l' /Users/jk/gits/gleam-language/gleam-thinking-core.md \
  ~/.workbuddy/skills/gleam-language/references/gleam-core.md \
  /Users/jk/gits/hub/tools_ib/glibe/docs/gleam-thinking-core-to-memory.md
cmp /Users/jk/gits/gleam-language/gleam-thinking-core.md \
  /Users/jk/gits/hub/tools_ib/glibe/docs/gleam-thinking-core-to-memory.md
```

## 2. The flat shelf — `knowledge/`

`knowledge/` is **one level deep: 18 files, 0 subdirectories, 0 symlinks**.
Each file is a single `ln` to a single document in
`~/.workbuddy/skills/gleam-language/`: `SKILL.md`, thirteen `references/*.md`
(the core card itself is NOT duplicated here — it is the root file above),
and four `workflows/*.md`. There is no mirrored directory tree. A file is
placed here once; whoever uses it links to it.

```
ln /Users/jk/gits/gleam-language/knowledge/type-reflex.md \
   <some-project>/docs/type-reflex.md
```

That is the whole protocol. No sync daemon, no copy step, no guard script.
Editing either name edits the same inode.

## 3. The Gleam package — where the design note lives

`gleam.toml` (`name = "gleam_language"`, `target = "erlang"`),
`src/gleam_language.gleam` and `test/gleam_language_test.gleam`. The `////`
module documentation of `src/gleam_language.gleam` is the
virtual-design / entity-development note: the two shapes, the stage order,
the "find the missing link" method, the one-type-one-module division of work,
why a type carries the fact, why a stream is not a list, what the compiler
checks in each stage, and the three-shape layer probe. It quotes the owner
verbatim and cites glibe's `RULINGS.md` only as provenance.

`gleam docs build` renders it to HTML; `gleam export package-interface`
emits all 103 documentation lines plus the `///` text of `Stage`, its two
constructors and `to_string` into `package-interface.json` — the compiler's
own anti-drift check on the knowledge, not a prose promise.

## 4. How another Gleam project references this centre

In the consuming project's `gleam.toml`:

```toml
[dependencies]
gleam_language = { path = "../../../gleam-language" }   # from glibe
# or: { path = "/Users/jk/gits/gleam-language" }
```

```gleam
import gleam_language.{type Stage, Entity, Virtual}
```

Measured 2026-11-13 in a throwaway consumer: both the relative and the
absolute `path` form resolve, compile and import with 0 errors, and
`gleam build --warnings-as-errors` is green. One caveat measured the same
day: a consumer's own `gleam docs build` does **not** render a dependency's
`////` text. The documentation is produced by THIS package in THIS
directory — export it here, or read `knowledge/` directly.

For non-Gleam consumers (a project that only wants the card), use the
single-file hard link in §2 instead; a path dependency carries code, not
markdown.

## 5. What breaks a hard link (measured, not guessed)

All measurements were made on this machine on 2026-11-13, APFS device
`16777231`:

| Action | Result |
|---|---|
| `ln a/file.md b/file.md`, then edit `a` in place | same inode, link count 2, `b` sees the edit immediately |
| `ln dir_a dir_b` | `EPERM: operation not permitted` — Unix links are file-level, directories cannot be linked |
| editor "atomic save" (write temp, `rename` over the name) | **silent break**: the two names get different inodes and diverge |
| `git checkout -- <file>` / `git restore` | **break**: checkout writes a fresh inode |
| `git clone` on another machine | git stores bytes, not inodes; the clone gets an ordinary independent copy |
| another filesystem / volume | hard links cannot cross devices |

So: edit in place, and re-link after a checkout or a clone. Rebuilding one
file is one command:

```
ln -f /Users/jk/gits/gleam-language/gleam-thinking-core.md \
  /Users/jk/gits/hub/tools_ib/glibe/docs/gleam-thinking-core-to-memory.md
```

`find <dir> -type l` returning nothing is the check that no symlink slipped
in. The owner explicitly ruled out symbolic links.

## 6. History, kept but not live

- `variants/glibe__docs__gleam-thinking-core-to-memory.md` — the B version,
  now the single source.
- `variants/speak_engl__docs__gleam-thinking-core.md` — the stale A version.
- `variants/standard__pre-convergence-2026-11-13.md` — the enriched
  "B + two §8 gotchas" standard that this repo used to declare canonical.
- `variants/PROVENANCE.md`, `variants/diffs/`, `COMPARISON.md` — provenance
  and line-level evidence.

These are deliberately independent files, NOT links: a historical snapshot
must not change when the live card does. The earlier README's section
"Migration status — NOT applied (by owner decision)" is superseded by the
2026-11-13 rulings quoted at the top of this file.

One wording inconsistency remains, left for the owner to decide:
`knowledge/SKILL.md` still says *"This skill copy is the source of truth"*.
Physically that copy and the canonical root file are one inode, so no content
can diverge; but the authority statement now names the skill rather than this
centre. It was not rewritten here.

## 7. Gates (2026-11-13)

```
gleam check                              -> 0
gleam test                               -> 0
gleam format --check src test            -> 0
gleam docs build                         -> 0
gleam export package-interface           -> 0
gleam build --warnings-as-errors         -> 0   (no warnings)
```

## 8. Boundaries

No symlinks. No mirrored directory tree. No guard script, no sync daemon, no
automatic cross-repo write. No business implementation — the `////` note is
the design-stage artifact; `to_string` is the only computed value in the
package.
