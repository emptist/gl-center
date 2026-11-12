# Comparison of the discovered `gleam-thinking-core` copies

Two genuine full copies were found (the `deprecated/` files in `glibe` only
*reference* the doc, they are not full copies):

| Variant | Path | Lines | Status |
|---|---|---|---|
| A | `prog_langs/.../speak_engl/docs/gleam-thinking-core.md` | 325 | **stale** — predates owner rulings R21 / R49 / R40-A / R41 / R48 |
| B | `tools_ib/glibe/docs/gleam-thinking-core-to-memory.md` | 378 | **current / corrected** — equals the skill's source-of-truth copy |

`cmp` reports they differ at char 892, line 15; 103 lines are added/changed.

## What changed between A (stale) and B (current)

### 1. §0 — Interval constructors (B fixes an R21 violation)
- **A** used abbreviated constructors: `MIN1 MIN15 MIN30 H1 D1 W1 MO1`.
  This violates owner **R21** ("constructors named in full, prefixed by the
  type name; wire codes live only in the codec/adapter").
- **B** uses `IntervalOneMinute … IntervalOneMonth` and adds the explicit
  "wire spellings such as `1h` live ONLY in the codec/adapter" paragraph, plus
  the R25 nuance (T+1 / CPU are not abbreviations).

### 2. §3 — smart constructor (B fixes an R49 violation)
- **A**: `pub fn new(i: Int) -> PositiveInt` — uses `new`.
- **B**: `pub fn clamp_positive(i: Int) -> PositiveInt` with the comment
  `// no \`new\` (owner R49)`. This is owner **R49** ("gleam里面很少需要这个
  所谓的new … 几乎见到new的地方必定是bug存在的地方").

### 3. §5 — pipeline discipline (B adds R40-A / R41)
- **A**: one line — "Subject first for `|>`; piping into a call puts the left
  side first."
- **B**: the full measured **pipeline-shape constraint** (R40-A / R41):
  `|>` fixes every step to `fn(Subject, ...extra) -> Subject`; measured error
  shapes; "when a design lets every function invent its own parameter order,
  an AI will."

### 4. §11 — anti-pattern nuance (B adds R25)
- **A**: "abbreviations" listed plainly as an anti-pattern.
- **B**: "abbreviations — but a professional term such as T+1 is not one (R25)".

### 5. §13 — checklist (B adds R21 to item 5)
- **A**: "Are names exact, full, domain-shaped?"
- **B**: "Are names exact, full, domain-shaped, with every constructor prefixed
  by its type name (R21)?"

### 6. §14 — docs-first gate (B adds R48)
- **A**: simpler version; says `--warnings-as-errors` "therefore fails in the
  RED phase and is the GREEN gate."
- **B**: the full **R48** explanation — `--warnings-as-errors` is a FIXED gate
  *including the skeleton phase*; the `_name` discard-name warning; "never
  classify a class of warnings as expected skeleton shape."

### 7. §8 — `charlist`/`atom` rule
- **B** folds the rule into §8: "gleam_erlang is where the Erlang-interop
  helpers charlist/atom live — `gleam add gleam_erlang`; never hand-roll BIFs."
- **A** lacks that sentence in §8 but has a closing **"Project addendum —
  speak_engl"** (lines 319–325) making the same point and pointing at
  `FEASIBILITY.md` §7.1 and the skill's `multi-target-erlang.md` §8. Those
  references are project-scoped and do **not** belong in the shared core, so
  this addendum was correctly dropped when the rule moved into §8.

## Conclusion

**B (`glibe`) is the canonical.** It is the corrected, current version and is
byte-identical to the skill's authoritative copy
(`~/.workbuddy/skills/gleam-language/references/gleam-core.md`). **A
(`speak_engl`) is a regression** — its R21/R49 violations must not be merged
into the single source of truth. The canonical `gleam-thinking-core.md` in this
repo is therefore a verbatim copy of B.
