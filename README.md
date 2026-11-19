# gl-center — the Gleam knowledge centre under `gits/`

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
| `/Users/jk/gits/gl-center/gleam-thinking-core.md` | canonical name in the centre |
| `~/.workbuddy/skills/gl-center/references/gleam-core.md` | the skill's authoritative copy |
| `tools_ib/glibe/docs/gleam-thinking-core-to-memory.md` | glibe's git-tracked mirror |
| `prog_langs/.../speak_engl/docs/gleam-thinking-core.md` | speak_engl's former stale copy |

Measured 2026-11-13: all four are inode `337552766`, `22713` bytes, `cmp`
identical. The stale 325-line `speak_engl` variant (R21 / R49 violations) and
the enriched "standard" are no longer live content — both are preserved under
`variants/`. `COMPARISON.md` still records the line-level decisions, including
the two general Erlang-interop gotchas that the enriched version had added to
§8.

The inode number and link count ARE the relation, so `stat` is the check.
`cmp` is only a byte-level sanity check and is trivially true for two names
of one file:

```
stat -f '%i %l' /Users/jk/gits/gl-center/gleam-thinking-core.md \
  ~/.workbuddy/skills/gl-center/references/gleam-core.md \
  /Users/jk/gits/hub/tools_ib/glibe/docs/gleam-thinking-core-to-memory.md \
  /Users/jk/gits/hub/prog_langs/swift/two_way_com_training/speak_engl/docs/gleam-thinking-core.md
```

## 2. The flat shelf — `knowledge/`

`knowledge/` is **one level deep: 23 tracked files, 0 subdirectories, 0
symlinks** (18 in the original shelf, plus `externals.md`,
`beam-doors-measured.md` and `beam-cross-platform-measured.md`, all added
2026-11-15, plus `gleam-document-led-tdd.SKILL.md` and
`beam-on-the-ground-measured.md`, both added 2026-11-19). Each
file is a single `ln` to a single document in a WorkBuddy skill directory:
`SKILL.md`, sixteen `references/*.md`, and four `workflows/*.md` point into
`~/.workbuddy/skills/gl-center/`
(the core card itself is NOT duplicated here — it is the root file above);
`gleam-document-led-tdd.SKILL.md` is the whole single-file gdltdd skill and
points into `~/.workbuddy/skills/gleam-document-led-tdd/`. There is no mirrored
directory tree. A file is placed here once; whoever uses it links to it.
One exception, measured 2026-11-19: `beam-on-the-ground-measured.md` was
contributed by an AI that does not use WorkBuddy (owner: *"这个作者AI可能并未
使用workbuddy"*), so it has NO WorkBuddy counterpart. Its second name is a hard
link into the producing project's docs:
`prog_langs/.../audio_splitter/docs/beam-on-the-ground-measured.md` — same inode
`341770712`, links 2. That is still the same one-file protocol, just a different
consumer directory.

Measured 2026-11-15: `externals.md` had two **byte-identical but separate
inodes** (centre `339942506`, skill `339942149`, `cmp` 0). `cmp` cannot tell a
copy from a link; `stat -f '%i %l'` can. `ln -f` replaced the skill's loose
copy with a link to the centre's inode (now links 3: centre, skill reference,
and `tools_ib/glibe/docs/externals.md`, linked for easy reference). Editing
must be **in place** — an editor's atomic save replaces one directory entry
(§5). `beam-doors-measured.md` and `beam-cross-platform-measured.md` were added
the same way, each as a single-file hard link, with no `-s` anywhere.

```
ln /Users/jk/gits/gl-center/knowledge/type-reflex.md \
   <some-project>/docs/type-reflex.md
```

That is the whole protocol. No sync daemon, no copy step, no guard script.
Editing either name edits the same inode.

### The gdltdd skill, shared 2026-11-19

`gleam-document-led-tdd.SKILL.md` is the document-led-TDD skill (owner name
"gdltdd"). It is a **whole skill in one file** — valid SKILL.md frontmatter
plus body — so it needs no `references/` tree. Measured: centre
`knowledge/gleam-document-led-tdd.SKILL.md` and
`~/.workbuddy/skills/gleam-document-led-tdd/SKILL.md` are one inode
(`341913160`, links 2, `cmp` 0). The centre is canonical; the WorkBuddy skill
name was a loose copy (links 1) before it was replaced with `ln -f`.

A consumer either loads it in place from the centre path, or links it into its
own project — one file, the same protocol as §2:

```
ln /Users/jk/gits/gl-center/knowledge/gleam-document-led-tdd.SKILL.md \
   <project>/.workbuddy/skills/gleam-document-led-tdd/SKILL.md
```

Editing the shared file is **in place only** (§5): new experience and
enlightenments — e.g. the 2026-11-19 compound-todo refinement — were appended
to the skill body before the link was made, and a future append edits this same
inode. An editor's atomic save would replace the name and drop the link.

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
gleam_language = { path = "../../../gl-center" }   # from glibe
# or: { path = "/Users/jk/gits/gl-center" }
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

## 4b. How an AI consumes this centre — with and without WorkBuddy

The same files serve two kinds of consumer. Both follow §2/§5; only the
discovery and the link destination differ. Everything below is verified on this
machine (2026-11-19).

### WorkBuddy AI (skills auto-discovered from `~/.workbuddy/skills/`)

1. Already installed: `~/.workbuddy/skills/gl-center/SKILL.md` (the thinking
   core, hard link, inode `324709842`) and its `references/`, `workflows/`.
   Just load the `gl-center` skill by name — no linking needed to read.
   `gleam-document-led-tdd/SKILL.md` is likewise installed as a hard link.
2. To use a shelf file inside a *different* WorkBuddy project, link it into that
   project's own skill dir (§2 example). The project can then load it as a skill.
3. New knowledge goes in by appending to the canonical file **in place** —
   `cat >>`, `>` , `cp src name`, or a Python `open(path, "w")`. Do NOT edit a
   linked file through an editor that does write-temp-then-rename (atomic save):
   that replaces the name with a fresh inode and silently drops every other
   link (§5). After any edit: `stat -f '%i %l' <both names>` must still show one
   inode and the same link count.

### Non-WorkBuddy AI (plain file access, no skill loader)

1. No skill registry is needed — the centre is a plain directory of markdown.
   Read the files directly:
   - thinking core: `/Users/jk/gits/gl-center/gleam-thinking-core.md`
   - the shelf: `/Users/jk/gits/gl-center/knowledge/*.md`
   - the gdltdd skill as a normal doc:
     `/Users/jk/gits/gl-center/knowledge/gleam-document-led-tdd.SKILL.md`
   - the Gleam design note: `src/gleam_language.gleam` `////` block (§3), or
     `gleam docs build` / `gleam export package-interface` output.
2. To keep a local name in your own project, hard-link the single file (§2):
   ```
   ln /Users/jk/gits/gl-center/knowledge/<file>.md <project>/docs/<file>.md
   ```
   — or, if the project has no `docs/`, put it beside its `README.md`. This is
   exactly how `beam-on-the-ground-measured.md` was linked into
   `audio_splitter/docs/`.
3. To depend on the *code* (the `Stage` types / `////` note), use the `gleam.toml`
   path dependency in §4 — links carry markdown/code files, a path dependency
   compiles the package.
4. Same rules as WorkBuddy for editing: in-place writes only, no symlinks
   (`ln -s` is ruled out), no directory links. `find <dir> -type l` must be empty.

### What does NOT travel to GitHub

A hard link is a filesystem fact, not git data. When the centre is pushed to
GitHub, the remote stores ordinary file bytes; a consumer who clones gets an
independent copy with **no link back** to the centre (§5, "git clone" row).
The link exists only on this machine between the local paths. Both audiences
must re-create it locally (`ln`) after a fresh clone; reading the markdown from
the clone works without any link.

## 5. A hard link cannot break; a directory entry can be replaced

Owner 2026-11-13, verbatim:

> "file link (ln without -s or anything else) should not be broken in a
> unix/linux filesystem. since it is basically a record of pointers to
> actual storage on disk filesystem, if it is so easy to break, then it is
> not linked."

That is the exact model: the inode owns the storage and counts its
directory entries; `ln` adds one more name pointing at that inode. There is
no reference chain and nothing that can dangle — only a symbolic link can
dangle. What earlier notes called a "broken link" was **one name being
replaced by a new, independent file**.

Measured 2026-11-13 on this machine (APFS device `16777231`):

| Action | What the filesystem does |
|---|---|
| `ln a/file.md b/file.md` | second directory entry for the SAME inode; link count 2 |
| edit in place, `> name`, `cp src name` over an existing link | writes THROUGH the existing inode; every name sees it, link count unchanged |
| `ln dir_a dir_b` | `EPERM` — Unix links are file-level, directories cannot be linked |
| `mv` / `rename(2)` **within one filesystem** — including renaming the directory that CONTAINS the file, or renaming the link name itself | moves a directory entry only; SAME inode, link count unchanged. Proven 2026-11-19 below |
| editor atomic save (write temp = NEW inode, `rename` over the name), `git checkout -- <file>`, `git restore` | the name ends up pointing at a fresh inode; the other names still hold the original file and the link count drops by one |
| `git clone` on another machine | git stores bytes, not directory entries — the clone gets ordinary independent files; the relation never travelled |
| another filesystem / volume | `ln` refused; hard links cannot cross devices |
| `ln -s a b`, then remove `a` | the ONLY dangling-link case, and it is a symlink |

Measured 2026-11-19 (`/tmp/gleam_rename_probe`, APFS): a file `dirA/file.md`
hard-linked to `outside_link.md` (inode `341919344`, links 2). `mv dirA dirB`
— renaming the **containing directory** — left the inode and link count
unchanged; then `mv outside_link.md renamed_link.md` — renaming the **link
name** — did too; writing through one name was visible through the other.
Owner 2026-11-19: *"file link will remain even I would change the folder name
the file now lives in … renaming should not break any hard link"* — this is
why the centre may be renamed for GitHub without any relinking. A rename is
not an inode replacement; only a fresh-inode overwrite is (row above).

So the single source is a filesystem fact, not a protocol: no `cmp` gate,
no guard script, no sync daemon, nothing to re-copy. The only discipline is
HOW a name is written — write in place. `cp` over an existing hard link was
measured to keep the inode (`339900185`, link count 2 before and after), so
it is safe; earlier notes that listed it as a breaker were wrong.

If a name has been replaced, `stat -f '%i %l'` shows a link count short by
one. Re-add that one directory entry:

```
ln -f /Users/jk/gits/gl-center/gleam-thinking-core.md \
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

The `GIT MIRROR` paragraph in `knowledge/SKILL.md` (line 44) still describes
the older copy-and-`cmp` protocol and says *"This skill copy is the source of
truth"*. It is a stale DESCRIPTION, not a hazard: `cp` over an existing hard
link keeps the inode, and `cmp` is trivially true for two names of one file.
Rewriting the skill's loading protocol is left for the owner.

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
