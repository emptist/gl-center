# Thinking in types — the order that forces it

Defensive checks (guards, tests, review) are a floor, not a cure. The failure
they are set against happens **before** any of them can run: I choose the shape,
and the choice feels right. His words:

> *"通过defensive机制很难，因为你不是那样想的，关键要让你习惯那样想，用type思考，
> 用functional思考，用gleam思考…你还必须要有skill之类的东西，约束你的思维模式。"*

So this file is not knowledge. It is **an order of operations that produces an
artifact at every step**, because a step without an artifact is a step I will
skip.

## 0. The verb test — am I thinking in Gleam at all?

His standing instruction, 2026-10-27:

> *"你要时刻记住用gleam思考."*

Not "check the code against Gleam afterwards" — **think in it**. What it is
aimed at is **translation**: I form the thought in English, which is
Python/JavaScript shaped because that is what my training is made of, and then
render it into Gleam. The rendering changes the syntax and keeps the foreign
shape. Everything below this section is downstream of stopping that.

So the test runs on the **English sentence, before it is written down**. Every
sentence about behaviour has a verb. If the verb is one of these, the thought is
not a Gleam thought, and the sentence must be **replaced by the type that makes
it unnecessary** — not reworded:

| the word in my sentence | measured | what I must name instead |
|---|---|---|
| *update it in place* / *mutate* / *set the field* | values are immutable; `let` rebinds | build a new value and thread it |
| *return early* | `return` → **Unknown variable** | `case`, or `use <- result.try` |
| *raise* / *throw* / *try-except* | `raise` → **Unknown variable**; cheat sheet: `Result(a, e)` | return the error |
| *loop until* / *while* / *for each* | `while` and `for` → **Unknown variable** | recursion, or a `list` / `iterator` function |
| *is null* / *might be None* | `Option(a)` | match it; never a sentinel |
| *just cast it* / *treat it as* | there are no casts | decode at the boundary into a type |
| *call its method* | **no methods, no OOP** | a module function taking the value |
| *subclass it* / *a base type* | no inheritance | variants, and one shared body |
| *a flag* / *a kind field* | a field is a bone | a constructor |
| *we'll validate it later* | a deferred check is a leak | the constructor, or the type is wrong |
| *the global* / *keep some state* | no shared mutable state | pass it in, carry it out |

All four bare-word refusals were compiled on 1.19.2, 2026-10-27 — the file is
`probe/broken/bug_no_imperative.gleam`. The rest are in
`references/gleam-measured.md` §6 (official cheat sheet) and `python-isms.md`.

Two sentences are always the tell, because both announce relief rather than
thought: **"it's simpler without a new type"** and **"this is basically the same
thing"**. Both mean a type has not been written.

**Artifact:** the English sentence is gone, and a type or a signature stands in
its place. If I cannot produce the replacement, I do not have a design — I have
a feeling, and refusing feelings is what the compiler is for.

## The order

### 1. Kinds before verbs

Write every type first. No function bodies, often no functions at all. For each
noun ask *what set does it range over?* and answer with the set:

| if the set is… | then the type is… |
|---|---|
| closed and small (`1m/1h/1d`, `enter/exit/hold`) | a custom type, one constructor per member |
| open | a type **plus** the boundary that parses into it |
| a thing with named parts | a record — never a tuple, never a `Dict(String, x)` |
| states that exclude each other | variants of one type |
| something that can be absent | `Option` — and only then |
| two kinds that differ in **nothing but the kind** | two constructors, **even with no fields at all**. The constructor *is* the identity; nothing compares contents. Official example, reduced: `pub type SchoolPerson { Teacher() Student() }` |
| a grade that must not reach another grade's consumer | **one type per grade**, each wrapping one shared body. Variants of *one* type let the wrong grade be handed over — they only force every consumer to name it |

**Never decide whether a value "is" a kind by looking at what is inside it.** If
you are inspecting fields to work out which one you have, the type already lost.

**Artifact:** the type definitions, compiled alone. Nothing else exists yet.

### 2. Write the wrong value — for every type in step 1

Not "think about whether it could go wrong". **Construct the wrong value** and
hand it to the consumer that would misread it:

```sh
gleam build --target javascript 2>&1 | grep -c "^error:"
```

Zero → go back to step 1. There is no arguing with a count, and there is no step
2½ where a comment covers for it. Measured, the same mistake both ways: a record
with no grade let a IntervalOneMinute bar into an IntervalOneHour consumer with **0 errors** and printed
the wrong close; variants answered with **1 error — `Inexhaustive patterns`,
naming the missing `Min1Bar` and `Hour1Bar`**. Note where it lands: the variants
are one type, so the call site is fine — it is **the consumer** that cannot leave
the other grades out. The check sits exactly where the misreading would be.
(Re-runnable: `probe/broken/`, both files.)

Three measurements belong together here, because together they are the whole
argument, and missing one is how I argued backwards for weeks:

| where the grade lives | wrong value handed over | what the build says |
|---|---|---|
| nowhere (one record) | silently read | **0 errors**, wrong answer printed |
| a **field** inside the record | silently read | **0 errors** — a careful reader and a careless one compile *side by side* |
| one type, one constructor per grade | still handed over | **1 error** — `Inexhaustive patterns`, the consumer cannot omit a grade |
| **one type per grade**, sharing a body | never handed over | **1 error** — `Type mismatch`, `Expected Hour, Found Minute`, at the call site |

The last two rows cost nothing extra: the body is untouched and shared, adding a
grade costs **0 sites** in the per-grade shape (measured — compare **2 errors at
2 any-grade functions** when a constructor is added to the union shape).

**Artifact:** the scratch module and its error count, in
`~/.workbuddy/skills/gleam-language/probe/`. Keep it — it becomes the regression
probe for that type.

### 3. Say what cannot happen, once, in the type

Read your own comments. Every line that says *"this cannot happen"* or *"never
both"* is a shape the type failed to prevent. Move each one into a type, or delete
it as a lie.

**Artifact:** zero remaining impossibility-comments, or a numbered list of the
ones left, each with a reason it must stay prose.

### 4. Only now write functions

Each one has a type that tells its whole story. Absence is `Option`; failure is
`Result`; a closed set is never a `String`; several results are a named record;
no side effect crosses into an engine module. If a function cannot be written
against the types from step 1, **the types are wrong**, not the function.

### 5. Re-run step 2 at the end

Types drift while functions are written. Zero errors becoming non-zero is a
regression, even though everything still compiles and every test still passes.

## The tells — what slipping feels like

The failure is aversive, so it announces itself as relief. Watch for the relief:

- *"this is simpler without a new type"* → new type needed
- *"they're basically the same thing"* → two variants of a type you haven't written
- *"let's keep it flexible for now"* → `Dynamic` reaching past the boundary
- *"we can validate it in the caller"* → validation that belongs in a constructor
- *"just an `Option`, it's fine"* → the value is guaranteed; pass it as an argument
- *"`_ -> …` is fine here"* → §1.11; the compiler was naming your work for free
- reaching for a **field** to record a kind → the kind belongs in the **type**

## Sample thinking to imitate, that is already in the tree

`docs/analysis-by-space-bunny/` — 1275 lines of reasoning done *this way*, by the
model whose habits worked. `02-THE-MEASURED-BASE.md` reasons from measurements and
types; `01-HOW-THE-BAD-IDEAS-EVOLVED.md` traces how each good shape was lost.

**Read the relevant one before designing anything, and imitate its movement:
claim → measurement → consequence.** It is closer than my own priors, which are
the thing being corrected.

## Why the BEAM target is part of this, not separate

Moving the work off the JavaScript target removes the hiding places rather than
adding checks:

- **The `.mjs` hatch closes.** Anything puzzling could be solved by writing
  untyped JavaScript with no types at all — 15 such bodies exist in glib today.
  An Erlang `@external` is at least a visible, greppable, `"@external"`-countable
  boundary, and the typed BEAM packages cover most of what the hatch was for:
  `gleam_httpc` (HTTP), `simplifile` (files, **dual-target**), `mist` (server and
  WebSocket).
- **The arithmetic lies less.** Measured on 2026-10-26: `9007199254740993` is
  `9007199254740992.0` on JavaScript and `+1` changes nothing; Erlang keeps it
  exact. A number silently wrong is worse than a crash.
- **The stdlib's JavaScript output has holes.** Measured: `list.flat_map` reads
  `list.head` off what it is given, so a callback returning a compiled JS *array*
  throws; the workaround was a hand-fold, which is a workaround, not a shape.

**Honest limits of this.** A target does not teach anybody to think. Purist
regression is still possible inside a typed Gleam file, and an Erlang external can
be written sloppily. What the move buys is that the escapes become **visible and
countable**; the thinking itself is changed by the order above, not by the VM.
