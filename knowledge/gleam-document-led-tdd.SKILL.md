---
name: gleam-document-led-tdd
description: This skill should be used when building, reworking, or auditing a Gleam module whose design must be settled before any working body exists — in-code module docs, typed `todo` skeletons, compiler-driven gap discovery, unit tests, then bodies. Trigger on 文档领先的TDD / 先写文档和空架子 / 把设计搞对 / Gleam module design, or whenever bodies, tests or language-syntax probes are being written before the type relations are fixed, or when asked to check whether a Gleam project followed document-led TDD.
agent_created: true
---

# Gleam document-led TDD

Settle the design in code comments and type relations before writing a single
working line. A skeleton with every relation in place IS the design; a body
written before it is a guess.

## The order

1. Write the `////` module doc naming the `.planning` item, and `///` on every
   type, field and function. State what the module READS and WRITES — every
   upstream named there is a contract.
2. Write the skeleton only: types, fully annotated signatures, `todo as "…"`
   bodies. No working line anywhere, including conversions moved from another
   module. **No `new` / `create` / `make` birth function (owner R49): every
   `new` is a bug until proven otherwise. A value is built where it is owned;
   a birth fn, if genuinely needed, says WHICH birth.**
3. Run `gleam build --warnings-as-errors`. Treat its errors as the list of
   design gaps AND the unimplemented list — read each one to its line. **Never
   classify a class of warnings as "expected skeleton shape" (owner R48)**:
   the only warning that exposed an AI-invented type was one single
   `Unused function argument`. The flag exists on `build` alone; `check` /
   `test` / `docs` / `format` have no equivalent.
4. Walk the imports backwards from this module to the top-level type. Add
   missing or wrongly-owned types and functions as skeletons too, then build
   again until 0 errors.
5. Write the unit tests that hold the design goals. Record RED.
6. Fill one body, compile, repeat to GREEN. `gleam build --warnings-as-errors`
   runs from the FIRST skeleton onward and is in CI; each filled body removes
   one diagnostic. It is a fixed gate, not a phase-specific reward.

## Measured in glibe, 2026-11-12 (plan 04-13)

Only what has actually happened. Extend after each later round, never ahead.

- Writing `timeframe.gleam`'s `////` exposed the upstream contracts: the
  `SourceBar → DataBar` conversion was owned by the wrong module
  (`databar.of_sourcebar`, with a `fold_sourcebar` bucket beside it), and five
  upstream modules had no `////` module doc at all.
- `gleam build` on the skeleton: exit 1, four `Unknown record field` errors
  (`manual_enter` / `manual_exit`), all in `engine.gleam` — the compiler named
  the leftover of an earlier, wrong module split. The skeleton itself produced
  only todo / unused-argument warnings.
- Deleting that module and the grep guard that enforced its split, and putting
  the conversions in their owning modules, brought `gleam build` to exit 0
  **without writing a working line**.
- Walking backwards reached the top-level Value: `desk.gleam` had a READ half
  (`timeframe_under`) but no WRITE half, so `put_timeframe_under` was added
  as a documented skeleton beside it.
- `gleam test` on the skeleton: **64 passed / 19 failures**, every failure a
  `todo` carrying its file:line.

### Second measurement — GREEN (same round)

- After filling the bodies: `gleam test` **83 passed, no failures**;
  `gleam build --warnings-as-errors` = 0; format / guards / docs / two probes
  all clean.
- The pipeline is now the product code: five steps, each
  `fn(Timeframe) -> Timeframe`, no step taking a bar.
- Two historical `monitor_test` assertions had to be replaced: they pinned
  the old bucket-accumulator behaviour, which the new straight line removes.
  A design change that overturns an earlier test is recorded, not hidden.

## Reviewing the skeleton (owner R43, 2026-11-12)

The purpose of skeletons is to turn a design that was only **recorded** into
one that is **carried out**: `////` / `///`, type relations and in/out types
present the whole system clearly without a single working line, so an AI can
read and reason about it too.

**"Revise the skeleton repeatedly" means this**: go back to the owner's design
and check whether the skeleton as built is correct — is the **wording exact**,
is there anything **invented** that the design never said. It does NOT mean a
process where one unit test pulls in parts and a later test overturns them.
That was a misreading; do not describe it as the method.

Why it works: with no working code the system is light enough to load into the
context at once — see it all, hold it all, miss nothing. Once the whole
architecture is right, filling bodies one at a time goes quickly and correctly.

**Precondition, do not generalise**: this works because the design was already
mature and the work is a transcription of it. It is not a method for inventing
a design from scratch. The review is a check against an existing correct
design, not an exploration that produces one.

### Measured — one retrospective check (same R43 round)

Not a skeleton-stage review: it was done AFTER the bodies existed. Read the
`////` / `///` citations back against the source they quote. Result: the names
`bars_listed`, `sourcebar.to_databar`, `UC-62` and two cited doc ranges all
have real sources (nothing invented), but one citation was wrong —
"What stays is what names the record" is at `timeframe.gleam:32-35`, not
`:28-31` — and a plan still named a converter the round had deleted. All were
corrected. **Measured fact: wording/citation drift survives a green build and
green tests; only reading back against the design finds it.**

## Measured in glibe, 2026-11-12 (doc-tdd rebuild, plan 05-01)

Owner ruling: the previous implementation is **history only** — *"什么都没弄对，
丢了不可惜"*. A new `doc-tdd` branch rebuilt the whole framework from zero.
Everything below happened at the skeleton stage; not one working line exists.

- **Clear the old layer first.** Old `src/`, `test/`, scripts, probes and
  catch-up notes (79 files) moved to `deprecated/` — readable, but not a
  source of names, not compiled, not guarding anything. A stale README that
  still told readers to run a deleted guard script was retired too.
- **Names come from the owner's verbatim wording only — not from the retired
  code, and NOT from AI-written prose in the ruling archive.** After the move
  I read the deprecated types and function signatures to harvest field and
  constructor names. That was the mistake: *"你的旧实现搞他干嘛"* /
  *"你现在把types搞清楚，其他的东西从我的用词当中去获取即可"*. My first
  correction said "owner's verbatim words **and the ruling archive**" — that
  second half was itself wrong and cost a whole invented type (R46, below).
  The ruling archive is evidence about owner quotes, not a word list: AI
  wrote its connective prose, and a name the owner merely **questioned** in
  a quote is the object of the question, not a naming. Leave un-named things
  EMPTY until a real consumer exists. A closed set's container name is a
  structural necessity; a domain concept he never named is a fabrication.
- **No project-level guard sh.** The project keeps only what the Gleam
  compiler itself can check. `gleam docs build` → `package-interface.json`
  is the compiler's own anti-drift artifact, not a script. Behavioural
  discipline (timely commits) is not detectable by a script.
- **Old red/green results are not evidence.** In a rebuild, the retired
  code's pass/fail counts measure nothing. Use the compiler as a **design
  probe** that reports gaps, not a scoreboard.
- **Gleam's own commands are the probes**: `gleam check` (type-check only,
  no codegen), `gleam export package-interface --out <path>` (module/type/fn
  JSON straight out, no digging in `build/`), `gleam docs build`,
  `gleam format --check`. Read `gleam --help` / `gleam help <subcommand>`
  before assuming a tool does not exist.

### Measured — the FIRST skeleton's unit tests are empty too

`test/glibe_test.gleam` contains no assertion and calls no `todo` body. Each
test binds a function to an explicitly annotated type, e.g.
`List(fn(Timeframe) -> Timeframe)` holding the five pipeline steps. If a
signature drifts from the design, **the compiler rejects this file** — that
is the test at this stage. `gleam check` / `gleam build` /
`gleam format --check src test` all exit 0 with zero design gaps.
`gleam build --warnings-as-errors` does NOT exit 0 at this stage (85
diagnostics: Todo / unused-argument / unused-private-constructor); that is
the honest unimplemented list, neither a failure score nor a reward. The
unused-private-constructor ones confirm the `opaque` seal is real.

### Measured — reviewing skeletons BEFORE bodies (owner R43)

This is the round the retrospective check above was NOT. With 12 modules and
zero working lines the whole system loads at once, and re-reading the owner's
rulings against each name produced eight findings, recorded in
`.planning/phases/05-doc-tdd/05-01-PLAN.md` §5. Two are worth keeping here:

- **A false citation is a real defect.** `branch.gleam` claimed the owner
  never named branch constructors and labelled an AI paraphrase
  `R39 (owner, verbatim)`. Both were wrong: R2 quotes `YinBranch` /
  `YangBranch`, and R39's verbatim text says no such sentence. Fix: cite R2,
  replace the self-invented placeholder constructor with the owner's two.
  **Check that every "verbatim" quote really is verbatim.**
- **Nearly deleted real design.** `Timeframe`'s eight growing/settled leaf and
  branch fields looked like a transcription of the retired implementation.
  Reading back R1 ("four twins"), R2 and R4 (`growing_yang_branch` in the
  one-line recognition rule) showed they are the owner's design. They were
  kept and their `///` doc was rewritten to cite those rulings instead of
  falsely claiming "the old field list is not transcribed here".
  **The output of the review is pinning each name to its source, not deleting
  names.** Also removed here: one invented placeholder, two false claims,
  five invented module names from the plan's index.

Net (of that first pass only): one constructor replaced, two false
attributions struck, four missing provenances added, five phantom modules
removed. `gleam export package-interface --out` confirmed all 12 `////`
module docs render intact with no `//` truncation. **The pass then declared
"no domain concept lost" — an over-claim corrected one hour later below.**

### Measured — the SECOND skeleton review deleted a whole type (owner R46)

The owner read a name the first review had waved through and ruled:
*"TimeframeSettings 是AI搞出来的东西，我不知道是什么玩意"*, then gave the
check that the first pass lacked: *"问题是他做什么，谁用他，为什么存在"*.

Measured answers, on the skeleton: **what it does** — one type, one
zero-field constructor, zero functions; **who uses it** — three references,
all of them type annotations in the skeleton (`Timeframe.settings`,
`timeframe.new(settings)`, one empty shape test), zero real consumers;
**why it exists** — because AI prose had become authority: the owner had
*questioned* the name in R23, my ruling §3 answered "no such entity" and
then wrote "keep it as a parameter block", and the next ruling cited that
line as a legitimate word source. Three hops from AI prose to vocabulary.

Fix: delete the module, the field, the birth function whose only reason was
receiving that parameter, and the empty test. **Do not rename it and do not
leave an empty placeholder** — a parameter arrives as a field of the type
that really owns it, when its real consumer exists (R26 / R32).

Two durable lessons:
1. **Ask the three questions of every type and function in a skeleton**, and
   require the provenance to point at an **owner verbatim quote**, not at a
   line of one's own ruling text. A name appearing in a ruling is not
   thereby his name.
2. **A green compiler does not check where names came from.** `gleam check`,
   `gleam build`, `gleam docs build` and the full `////` interface were all
   clean with this invented type present; the R43-style read-back is the
   only check that finds it. Also: a review pass's conclusion is only about
   the items it actually examined — never generalise it to the whole tree.
3. **The review needs a trigger, not another rule** (owner R47). Every
   judgement already in hand (R26 / R32 / R34 / R35 / R43) was enough to
   catch a type with zero fields, zero functions and zero real consumers,
   yet the R43 pass checked only provenance — are the names his, are the
   quotes verbatim — and never asked what the type DOES. All checks pointed
   outward; none pointed at the thing itself. Owner: *"如果我不提出来，你能不能
   根据逻辑自己发现问题呢？"* / *"这是什么玩意你自己看得懂不？"* The added
   trigger: after writing each `////` / `///`, translate it into **who reads
   or writes which concrete value**; a sentence that cannot be translated is
   fabrication. The deleted module's `///` was four "it is NOT …" clauses,
   one since-voided assertion and zero facts, and beside it I had written
   "an empty type with a `///` doc is a valid skeleton item" and "no
   function here on purpose" — turning the red flag into an exemption.
   **Never write a "`///` exists" or "no behaviour by design" clause as the
   reason an empty type is allowed.** A green compiler and fully rendered
   `////` docs pass even when the doc text says nothing.
4. **Measured mechanism for "why did `gleam check` pass?"** (owner R47 §1.1).
   It did NOT need a fabricated consumer function. Before deletion every
   body was `todo`; `new(settings)` never read its argument (warning only),
   and a `pub` record field with ZERO readers produces **no diagnostic** —
   the compiler assumes an external reader. Current skeleton warnings:
   30 `Todo`, 52 `Unused function argument`, 3 `Unused private constructor`,
   **0 field-never-read, 0 errors**, while all 8 `DataBar` and all 10
   `Timeframe` fields are themselves unread. core §1 guarantees no
   *inconsistencies*, not *meaning*; a coherent empty shell is maximally
   free of inconsistencies. Deleting the referenced type left the other
   8 `Timeframe` signatures and 10 fields byte-identical — proof that the
   "reference" was circular, not a need. Also: the old doc said "numbers
   one **engine** runs on"; deleting `engine.gleam` I string-replaced
   `engine` → `Timeframe` and called it a new spec. **A renamed sentence
   is not a description.**
   **Correction after the owner asked "what did gleam check actually report?"**:
   it DID warn. With the pre-deletion files restored, `gleam check` printed
   `timeframe.gleam:81:12 — Unused function argument: settings ... This
   argument is never used / Hint: _settings`, followed by a `Todo` at
   `:82:3`; 31 Todo + 53 unused-argument + 3 private-constructor warnings,
   0 errors, 822 lines. The `import` was NOT flagged unused (the type name
   really appears in the field and parameter annotations), and the
   fabricated module appeared **zero times** in the log. So the compiler
   reported the empty use — but it was one of 53 identical warnings, and
   the skeleton workflow explicitly classifies todo/unused-argument
   warnings as expected shape, so the signal was filtered out as noise.
   **The compiler reported it; the process defined it as ignorable.**
   In a skeleton, a silent module is more suspicious than a noisy one.
   **This classification is void as of R48** — see the WAE measurement below.

### Measured — `gleam build --warnings-as-errors` (owner R48)

`gleam --help` (1.19.2) has no such global flag. Reading each subcommand's
help showed it on **`gleam build` only**: "Consider the build failed if the
package contains any warnings"; `check` / `test` / `docs build` / `format` /
`dev` / `compile-package` have none. My own `gleam-core.md` §10 / §13 / §14
already named this command; CI did not run it and I had never run it locally.

Real run on the 11-module skeleton: exit 1, 806 lines, ending
`error: 85 warnings generated.` (30 `Todo found`, 52 `Unused function
argument`, 3 `Unused private constructor`). WAE turns the whole warning set
into a build failure, so a category of them can no longer be declared
"expected". It is now in `.github/workflows/test.yml` — a compiler flag, not
a guard sh (R44). The skeleton's red state is honest and shrinks one
diagnostic at a time as bodies are filled.

Trap measured in `/tmp/underscore_probe`: `_a` is a **discard name** — the
body cannot reference it (`error: Syntax error / Found a discard name`), and
`add(_a: 1)` is a syntax error too. Following the compiler's `_settings`
hint in bulk would have silenced the ONLY warning that exposed the invented
`TimeframeSettings`. Never use `_` to make something whose three questions
(R47) are unanswered look clean.

### Measured — a type cannot own "its own settings" (owner R48)

R46 deleted the type but only fixed its name's provenance. R23 §1:699-701
preserves the AI reasoning: "one per interval, therefore it must be a field
of Timeframe". Four contradictions: identity lives in the holder's Dict key,
so a Timeframe does not know its interval (R37); a Timeframe is a pure VALUE
that runs nothing — the pipeline steps do, and R40-A lets steps take extra
parameters (R33); ibOptions' settings files were a Python+pandas limitation,
where the right shape is one field on an existing type (R34 / R32); and
R46's diff deleted the field while the other 8 signatures and 10 fields
stayed byte-identical, proving the NAME invented a holder rather than a
relation finding one. The doc that made it sound plausible was four "it is
NOT" clauses plus an exemption line (R47).

### Measured — `new` was invented to feed an invented field (owner R49)

*"为了这个毫无用处的field你确实编造了一个毫无用处的function叫做 new …
几乎见到new的地方必定是bug存在的地方"*. Pre-R46
`timeframe.gleam:79-83` held
`pub fn new(settings: TimeframeSettings) -> Timeframe { todo }`; its only
job was receiving a parameter that did not exist in the design. R46's
deletion list was the field, one import, one READS name and **this `new`**;
the other 8 signatures and 10 fields stayed byte-identical. A useless field
needs a `new` to feed it and a `new` makes the field look like it has an
origin — circular, with a third fabricated part.

The rule: Gleam values are constructed where they are owned; a birth
function that cannot say WHICH birth it is does not exist; **every `new`
is checked as a bug, with no container exemption**. My own `gleam-language`
skill said "a container may be `new`" and its `gleam-core.md` §3 example
literally contained `pub fn new(...)`. Both are now struck (§3 →
`clamp_positive`, §5 gains a No-`new` entry, SKILL.md's `<do_not>` loses the
exemption), and the repo mirror is `cmp`-equal.

Active audit of the live tree: **zero `new` in `src/` / `test/`**, no second
`create` / `make` among 38 `pub fn`s. But the same pass found another false
verbatim: `config.gleam`'s `////` claimed "R33 names
`config.default_config()` as that one Value" — R33's four owner quotes name
only `Desk` and name NO function; `default_config` comes from AI ruling
prose. Corrected the provenance (kept the function) and replaced the
Python-shaped "this constructor" / "A constructor literal" wording with a
translatable fact. **This was a connected finding on the owner-prompted
chain, not self-triggered discovery; that remains unmeasured.**

## Measured in glibe, 2026-11-19 (app skeleton; compound todo granularity)

The first app modules were brought up doc-first (`app/message.gleam`,
`app/dashboard.gleam`): `////`/`///`, typed signatures, `todo as "..."` bodies,
then empty shape tests that **bind function references** (they never call a
`todo`, or the test goes red for the wrong reason). No body filled. Same order,
new layer (view/UI), not a new method.

### Measured — a compound todo is available, not mandatory (owner 2026-11-19)

Owner verbatim: *"todo也可以是细化的todo我演示过，就是case 或 use 等等之下的各小点的todo，
本质是函数细节不做，框架却可以先架好"*; then *"you can, not you must use compond todos"*;
then *"sometime compond todos can map your imports into structure without actual working
code, while the compiler warnings now become more helpful"*.

Source found by the owner's own pointer "用 `<{human: ...` 搜", in git history — not
inference: `instrument.gleam:116` at `2c54535` — *"a case match to todo in each case,
so you can find if the args are designed well"* — landed at `f839c71` as nine
`case interval` arms, each a `todo` pinning a concrete provider.

Two can-criteria (neither is a must): use a compound todo when (a) arms DIFFER and
each todo pins a concrete design choice (nine Intervals → nine providers), or (b) the
goal is to make imports checkable structure with zero working code and turn WAE into
a finer per-line list. Probe (`/tmp/gleam_todo_probe`): a `case`-of-todos imports
`{type Grade, Low, Mid, High}` and references all three constructors only inside
`todo` arms — **no unused-import warning**, and WAE lists one todo per arm with
file:line. When all arms do the same thing, one whole-function todo is correct:
`from_event`'s 12 Event arms all map to `MsgEye(event)`, so splitting them adds no
information. That forced split was reverted at once (`git diff` clean, `gleam check`
0). Boundary: this refines step 2's todo granularity only; R19 ② wording unchanged,
no code/type/dependency change from the ruling. Provenance: glibe `docs/RULINGS.md`
"2026-11-19 08:40 / 08:46 / 08:51".

## Auditing a project: `gleam_dltdd` (owner 2026-11-17)

To CHECK whether a Gleam project actually followed this process, run the
standalone checker — it reads the target's git log and reports per module:

```sh
export PATH="/opt/homebrew/bin:$PATH"
cd /Users/jk/gits/hub/tools_ib/gleam_dltdd
gleam run -m gleam_dltdd <path-to-gleam-project>
```

This works **only for Gleam**: `////` / `///` are in-code docs that
`gleam docs build` renders into `package-interface.json`, and `todo as "..."`
bodies compile, so a source snapshot in git carries the design evidence.
Other languages have no compiler-checkable design artifact in the source.

Verdicts (state at the module's **first commit**, not today):
- `doc-led` — a `////` module-doc block and `///` item docs were present at
  birth (design written before body). A pure type with no `todo` still counts.
- `CODE-FIRST` — working code with no module-doc block at birth.
- `no-evidence` — not judgeable from that snapshot.

Counts in the report are line counts in the first-commit snapshot; one `////`
block spans many lines, so `module_docs > 0` means "a block exists".

Measured on first run: glibe 15 modules → 6 doc-led / 9 code-first; the
checker's own 4 modules → 4/4 doc-led. Two judgement bugs were found and
fixed by that run (pure-type module misclassified; `////` counted per line),
recorded in `gleam_dltdd/.planning/01-dltdd/01-PLAN.md`. Refinement continues
from real use, not in advance.

## To be filled in as development reaches them

- Filling the FIRST body and cycling the empty shape tests to real assertions.
- A round where a real consumer forces a new field into a type (R26 / R32)
  after the skeleton is settled.
- A round where the R47 trigger fires **without an owner prompt**. Both
  skeleton reviews here were owner-prompted; self-triggered discovery is
  not yet measured.

Leave these empty until measured. A section describing a round that has not
happened is prose pretending to be a measurement.
