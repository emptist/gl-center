# Provenance of the archived `gleam-thinking-core` copies

These files are byte-copies of documents found elsewhere in the tree. This
manifest records, for each archived file, the **exact source path** it came from
so it can always be traced back to its root folder.

## Naming scheme

A filename is `<project>__<relative-path-with-slashes-as-__>`. It encodes the
project name and the path *within* that project, but it intentionally omits the
ancestor directories above the project. Those omitted ancestors are listed in
the **Full source path** column below — that is the authoritative traceability
record.

| Archived file (in this `variants/`) | Project | Relative path within project | Full source path (root folder) |
|---|---|---|---|
| `speak_engl__docs__gleam-thinking-core.md` | `speak_engl` | `docs/gleam-thinking-core.md` | `/Users/jk/gits/hub/prog_langs/swift/two_way_com_training/speak_engl/docs/gleam-thinking-core.md` |
| `glibe__docs__gleam-thinking-core-to-memory.md` | `glibe` | `docs/gleam-thinking-core-to-memory.md` | `/Users/jk/gits/hub/tools_ib/glibe/docs/gleam-thinking-core-to-memory.md` |

## Notes
- The two full copies above are the only genuine full-text copies discovered.
  `glibe/deprecated/...` files only *reference* the doc (not full copies) and are
  not archived here.
- To reconstruct the exact original location of any archived file, take its
  project + relative path and prepend the matching root folder from the last
  column. Example: `speak_engl` + `docs/gleam-thinking-core.md` →
  `prog_langs/swift/two_way_com_training/speak_engl/docs/gleam-thinking-core.md`.
