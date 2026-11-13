# Filling the skeleton he wrote

His ruling, 2026-10-26, and it is about speed as much as about quality:

> *"要想快速，只能是我写好空架子，让AI去填充，让AI思考不现实。用代码和文档型注释来
> 做，每次compile断除妄想"*

**He designs; I fill. Expecting me to think is unrealistic. The medium is code
and doc comments, and every compile cuts off a delusion.**

---

## What arrives

A skeleton is **compilable shape without bodies** — types, signatures, `///`
comments, and `todo` where the work goes. Example of the shape:

```gleam
/// The bar before the working one. Exists whenever a leaf does: a leaf is born
/// on a bar, and `leaves` is only asked to grow one that is already there.
pub fn last_bar(timeframe: Timeframe) -> DataBar {
  todo
}
```

**The `///` comment is not decoration — it is the requirement.** Whatever it
promises is what the body must deliver, and whatever it says is impossible is
what the signature must make impossible. If a promise cannot be honoured by the
types given, that is a **report**, not something to fix by editing his comment.

## Extension, owner ruling 2026-11-07 — the module doc, the plan link, and the tests

A file skeleton also has a **first line before the imports**: `////`, the module
documentation. It states what the module holds **and names the `.planning` plan
item it implements**. `//` is not documentation — `gleam docs` cannot see it and
`package-interface.json` will have an empty `"documentation"` list. The reason
for the link is drift: *"code files go without referencing to .planning plans,
and documents only live in docs folder while code modules may go the other way
and without anybody noticing it."* A plan with no link from the code is a toy.

The full order, measured on a real package 2026-11-07 (Gleam 1.19.2 / OTP 29):

| step | artifact | measured result |
|---|---|---|
| 1 | `////` module doc + plan link, types, `///` + signatures, `todo as "..."` bodies | `gleam build` **0 errors**, 4 warnings (2 `Todo found` + 2 unused args) |
| 2 | `test/<pkg>_test.gleam` with `assert` on what the `///` promised | `gleam test` **RED**: `0 passed, 2 failures`, each printing the `todo` message and file:line |
| 3 | fill one body, compile, repeat | `gleam build --warnings-as-errors` **0**, `gleam test` **0**, `gleam format --check` **0** |
| 4 | `gleam docs build` | `////` paragraphs and every `///` render in HTML and in `package-interface.json` |

Two consequences to remember:
- **`gleam build --warnings-as-errors` fails in the RED phase** (measured exit 1).
  It is the GREEN-phase gate. Do not "fix" the skeleton by deleting its `todo`s.
- `gleam docs build` is the **compiler's own** anti-drift check. It emits the
  plan reference as machine-readable data; no shell guard is needed to notice
  a module that has no `////`.

Runnable example: `../docs-first-probe/` (green state + RED skeleton in
`examples/`). The full workflow is `workflows/build-new-module.md`.

A **unit test comes before the body**, not after. `assert` / `let assert` are
the assertion devices; deliberately broken source files are not a test.

## The loop

```sh
gleam build --target javascript     # every single step, not at the end
```

1. **Fill one body.** Not two. One `todo` becomes code, then compile.
2. **Compile.** A red build is information, not failure — **it is the whole
   point.** The compiler emits one `warning: Todo found` per unfinished body,
   naming the file and line, so the remaining work is always countable:

   ```sh
   gleam build --target javascript 2>&1 | grep -c 'Todo found'
   ```

   Measured 2026-10-26 on a probe with **two** todos: that exact command prints
   `2`. `grep -c todo` prints `5` — it also matches the prose of the warning, so
   **count the heading, not the word**. A `todo` compiles and then crashes the
   process (Node exits; the hint says *"This code will crash if it is run"*),
   which is why "it builds" never means "it is done".
3. **Do not touch the skeleton.** If the types or the signature must change to
   make the body work, stop and say which one and why. **Changing his shape to
   suit my body is how modules get "confused"** — he used that word about a
   proposal of mine the same day.
4. **When a standard-library function is needed, do not recall one.** Look it up
   or compile it; a language claim from memory is fabrication (`SKILL.md`
   `do_not`). `gleam build` answers "does this function exist" faster than I can
   be wrong about it.
5. **Run the tests.** `gleam test`. Green is not the absence of a bug, but it is
   the presence of one check.

## What "filling" is allowed to decide

Only things **inside** one body:

- which `case` arms, in which order;
- which list function expresses the fold (`fold`, `map`, `filter_map`,
  `try_fold`);
- whether a step pipes.

**Nothing else.** Not a type, not a field, not a name, not a module boundary,
not whether a step belongs at all.

## When the skeleton leaves the design open

Do **not** write three paragraphs weighing the options — prose has no compiler
(see `SKILL.md`: *Prose is not a verifier*). Build both shapes in
`~/.workbuddy/skills/gleam-language/probe/src/` and hand him a table:

| shape | errors | where |
|---|---|---|
| grade in a field | 0 | nowhere — the wrong value is compiled |
| one type per grade | 1 | `Type mismatch` at the call site |

He reads the error counts and decides in ten seconds. That is faster than my
best paragraph, and it is **true**, which my best paragraph is not guaranteed to
be.

## The thing to remember between compiles

**Expecting me to think is unrealistic.** So the work is arranged so that
thinking is not needed: he supplies the shape, the compiler supplies the
verdict, and I supply only the step that can be checked immediately. Every step
uncompiled is a delusion waiting to be defended.
