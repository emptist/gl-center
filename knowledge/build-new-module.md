# Workflow: build one Gleam module, documentation first

**Owner ruling 2026-11-07:** documentation-first is not "write `docs/` first".
The documentation is **in the code file**: `////` for the module, `///` for a
type or function, `//` for anything else. Gleam compiles a module whose bodies
are `todo as "..."`, so the order can be:

```
plan link -> `////` -> types -> `///` -> signatures -> `todo` -> TESTS -> bodies
```

A plan that lives only in `.planning/` or `docs/` while the code file names
nothing is a toy: the code can drift and nobody notices. The `////` block names
the plan item it implements, so the link is in the compiled artifact too —
`gleam docs build` writes every `////` line into `package-interface.json`.

**Required reading before starting:** `references/gleam-core.md` IN FULL
(`SKILL.md` CORE LOADING PROTOCOL). Then `references/think-in-types.md` and
`workflows/fill-the-skeleton.md`.

---

## Step 1 — the plan link and the module doc

Create `src/<domain>/<name>.gleam` beginning with `////`. First line says what
this module holds; a later line says which plan governs it. Name an existing
plan path — **check it exists before writing it**. Example (compiled 2026-11-07):

```gleam
//// The interval ladder for a market feed.
////
//// Plan: `.planning/phases/03-stream-processing/03-01-PLAN.md`, stage 1.
//// The types and the `///` comments are the specification; the bodies are the
//// work.
```

`////` at the top of the file is **module documentation**; `//` is a plain
comment and is invisible to `gleam docs`. A `//` header, however thoughtful,
does not appear in `package-interface.json`.

## Step 2 — types, then documented signatures

Define the domain types first. Closed set -> one constructor per variant; an
error -> a domain error type, never `Error(String)`; an identifier -> its own
type. Then write each public function's **signature and `///` comment** and a
`todo as "..."` body. The `///` text is the requirement; the signature is what
makes a broken requirement unrepresentable.

```gleam
/// A closed set of chart intervals. Adding one forces every `case` to be updated.
pub type Interval {
  IntervalOneMinute
  IntervalFifteenMinute
  IntervalOneHour
  IntervalOneDay
}

/// Render an interval as the spelling the exchange expects.
pub fn to_string(interval: Interval) -> String {
  todo as "fill this body from the function docs above"
}
```

Every module function is annotated (arguments AND return). No `if/else`, no
`return`, no `null`, no catch-all `_` over your own custom type.

`gleam build` now compiles with **0 errors**. It emits one
`warning: Todo found` per unfinished body plus one `warning: Unused function
argument` per signature whose argument is not yet used. Measured with two
bodies: 4 warnings, 0 errors. Consequence: **the skeleton phase cannot pass
`gleam build --warnings-as-errors`** — that gate belongs to the GREEN phase,
not to the RED one.

## Step 3 — tests, before any body exists

Create `test/<package_name>_test.gleam` (gleeunit looks for that exact name).
Use `assert` (Boolean guard) and `let assert` (pattern + crash), not libraries
that no longer exist (`gleam/should` is not gleeunit 1.11).

```gleam
import docs_first
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn interval_spelling_test() {
  assert docs_first.to_string(docs_first.IntervalOneMinute) == "1m" as "IntervalOneMinute spells 1m"
}
```

`gleam test` is now **RED**: each unfinished body crashes with its `todo`
message and the file/line. Measured: `0 passed, 2 failures` with
`todo src/docs_first.gleam:16` and the `info:` text from the `todo`. Red is the
specification being executable, not a failure.

A test asserts what the `///` comment promised. If the comment promises
something the signature cannot deliver, **report it** — do not edit the comment
to fit the code, and do not edit the skeleton to fit the body
(`fill-the-skeleton.md`).

## Step 4 — fill one body, compile, repeat

One `todo` at a time. `gleam build` after each. The compiler's warning count is
the remaining-work counter:

```sh
gleam build 2>&1 | grep -c 'Todo found'
```

Count that heading, not the word `todo` — the warning prose contains it too.
When the last body is filled: 0 warnings, `gleam build --warnings-as-errors`
green, `gleam test` green, `gleam format --check` green.

## Step 5 — the documentation is a build artifact

```sh
gleam docs build
```

Measured 2026-11-07, Gleam 1.19.2: `build/dev/docs/<pkg>/docs_first.html`
renders the `////` paragraphs and each `///` on its type/function;
`build/dev/docs/<pkg>/package-interface.json` carries them as
`"documentation"` strings. **This is the anti-drift mechanism**: the plan link
inside `////` is now machine-readable data emitted by the compiler, not prose
someone has to remember to cross-check. No grep guard needed.

A complete, runnable example is in `../docs-first-probe/`: green
`src/docs_first.gleam`, `test/docs_first_test.gleam`, and the RED skeleton in
`examples/skeleton.gleam.example`.

---

## Order that is wrong

Documentation as Step 6, after code and tests — that was the old version of
this file. It also used `gleam/should` (not the runner here) and
`Result(String, String)` (a `String` where a domain error type belongs). Both
are deleted. Documentation is Step 1 because the `///` comment is the spec the
test and the body are checked against.

## Done when

- [ ] `////` module doc names an existing `.planning` plan item.
- [ ] Every public type/function has `///`; every function is annotated.
- [ ] Tests existed and were RED before the bodies were written.
- [ ] `gleam build --warnings-as-errors` = 0; `gleam test` = 0; `gleam format --check` = 0.
- [ ] `gleam docs build` emits the module docs into `package-interface.json`.
- [ ] No `todo`, no `panic`, no `let assert` in library code.
