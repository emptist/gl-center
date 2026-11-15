---
name: gleam-language
description: >
  Gleam language expertise, measured against a compiler rather than a tutorial.
  Covers the type system, pattern matching, custom types and opaque types,
  Result/Option, the `use` chain, JavaScript and Erlang interop, multi-target
  externals, and testing with gleeunit. Use when writing or reviewing Gleam
  code, when migrating Python-shaped thinking into Gleam, or when a question
  about Gleam's behaviour needs an answer that is compiled rather than
  remembered.
---

## CORE LOADING PROTOCOL (2026-11-07, owner ruling)

**Before ANY Gleam judgement — writing, reviewing, designing, debugging,
naming, or choosing a project layout — read
`references/gleam-core.md` IN FULL, first, every time.** It is the whole
language on one card: the type-first reflex, every compiler
guarantee, all official conventions/anti-patterns, targets, externals,
toolchain, LSP, and the unlearn list. It replaces scattered recollection.
Everything else in `references/` is lookup or compiler measurement, to be
consulted AFTER the core is loaded, never instead of it.

The owner's reason, verbatim: *"你依赖那么多sh来帮助质控，根本原因还是type没到家"*
and *"如果语言本身增强了，需要记忆的其他补救性防御性措施就会越来越少。治病治根。"*
When I reach for a shell guard, a parser, a `panic`, or a catch-all branch,
the failure is in the type design — go back to `gleam-core.md` §2 and §13.

**DOCS-FIRST / TDD PROTOCOL (owner ruling 2026-11-07).** Documentation-first
means documentation **in the code file**, not a `docs/` text written first:
`////` for the module (naming the `.planning` plan item it implements), `///`
for every type and function, `//` for the rest. Gleam compiles `todo as "..."`
bodies, so the order is: module doc → types → documented signatures → `todo`
→ **unit tests** → one body → compile → repeat to green. A `///` comment is the
specification the test and the body are checked against. `gleam docs build`
emits those comments into `package-interface.json`, which is the compiler's own
anti-drift check — a plan that no code file references is a toy. See
`gleam-core.md` §14, `workflows/build-new-module.md`, and the runnable
`docs-first-probe/`.

**GIT MIRROR (owner 2026-11-07).** `gleam-core.md` lives in the user-level
skill directory, which git does not manage, so every client must be able to
read it from the repo: `glibe/docs/gleam-thinking-core-to-memory.md` is a
**byte-for-byte copy** kept under git. **This skill copy is the source of
truth.** After ANY edit to `references/gleam-core.md`, immediately re-copy it
there and verify with
`cmp ~/.workbuddy/skills/gleam-language/references/gleam-core.md /Users/jk/gits/hub/tools_ib/glibe/docs/gleam-thinking-core-to-memory.md`.
Never edit the mirror alone, and never let the two drift.

<essential_principles>
## The compiler is the verifier

**Corrected 2026-10-26** — this used to claim there is no LSP here. False, and
said without checking: `hover`, `goToDefinition`, `findReferences`,
`incomingCalls`, `outgoingCalls` and `documentSymbol` all answer on `.gleam`.
Use it wherever the reflex is `grep -rn`… but it never decides *correctness*.

`gleam build` and `gleam test` are the ground truth, and every claim in
`references/` was compiled.

**Think in Gleam — the first artifact is code, not a sentence.** His standing
instruction, 2026-10-27: *"你要时刻记住用gleam思考."* The failure it names is
**translation**: I form the thought in English — which is Python/JavaScript
shaped because that is what my training is made of — and then render it into
Gleam, changing the syntax and keeping the foreign shape. So the check runs on
the **English sentence before it is written**, and it is one question: *does this
sentence contain a verb Gleam has no shape for?* *Mutate*, *return early*,
*raise*, *loop until*, *is null*, *just cast it*, *its method*, *subclass*, *a
flag*, *we'll validate it later* — **all measured absent from the language**
(`while`, `for`, `return`, `raise` each compile to `Unknown variable`). A hit
does not get reworded; it gets **replaced by the type that makes it
unnecessary**. If I cannot produce that type, I have a feeling, not a design.
See `references/think-in-types.md` §0.

**A `case` over a custom type must be exhaustive.** A new constructor is a
compile error in every `case` that must mention it. A "closed set" is a type,
not a convention. The error message names the missing constructor — it is a
free list of the work.

**There are no methods and no `null`.** `Option(a)` and `Result(a, e)` are
values you match on. Measured: `Option` has no `is_none()` and `Result` has
no `is_err()` — the function forms are `option.is_none(v)` /
`result.is_error(v)`, and on the JavaScript target the compiled `Result` has
`isOk()` but **no** `isErr()` at all.

**A type is cheaper than a convention.** Python reaches for a dict, a flag, a
`None`, and a comment because the type system will not make the case
impossible. Gleam can make it impossible, and then the compiler does the
remembering. See `references/python-isms.md`.

**The pure core is written once; only the boundary differs per target.** A
function with two `@external` attributes — one per target — is the whole
mechanism behind a split-target system. See `references/gleam-measured.md` §4.
**The migration bill is countable**: `grep -rl "@external" src/`. A module with
none of them compiles on both targets already. See
`references/multi-target-erlang.md` §4.

**The wrong value decides the type — not my taste.** Before writing a type,
ask: *can a wrong-but-well-formed value of it be constructed and reach the
consumer without any function objecting?* A yes means the type is wrong, and
"we validate it later" is a yes. My training does not merely lack this habit —
it finds imprecision *comfortable*, so the question must be mechanical and its
answer must come from the compiler, not from how the code feels. See
`references/type-reflex.md`.

**Thinking is not my job; compiling is.** His ruling on how work gets done
fast, given 2026-10-26 after a day in which every error I made was made in
prose:

> *"要想快速，只能是我写好空架子，让AI去填充，让AI思考不现实。用代码和文档型注释来
> 做，每次compile断除妄想"*

He writes the **skeleton**; I **fill it**. Expecting me to think is
unrealistic. **The medium is code and doc comments, and every compile cuts off a
delusion.** So: a type definition, a signature and its `///` comment **are** the
specification, and the body is my work — see
`workflows/fill-the-skeleton.md`.
Where a design is genuinely open I still do not argue it in English: I compile
the two shapes and hand him the error counts (`references/type-reflex.md`),
because prose has no compiler and my judgement inside it is unguarded by
construction.

**`let assert` and `assert` are different syntaxes, not one keyword.**
`let assert <pattern> = <expr>` binds and crashes on mismatch (it is `panic`,
measured on both targets); `assert <bool>` is a standalone Boolean guard, **new
in v1.11** — swapping them is a syntax error (`let assert a == b` dies with
`I was expecting a '=' after this`). A value a step cannot be without arrives
as a **parameter**, not as an `Option` field to unwrap. See
`references/gleam-idioms.md` §5.
</essential_principles>

<the_shape_of_a_gleam_file>
- One module per file; the module is named by the file and its path.
- `pub` marks what the module exports; without it, the function is private.
- The last expression of a block is its value — there is no `return`.
- Types are nouns, fields are nouns, functions are verbs.
- `use x <- thing` binds the callback's result to `x`; it is how a chain of
  decoders and a chain of fallible calls are written.
- `let` rebinds; the data itself is immutable. Prepending `[x, ..list]` is
  O(1).
- `case` is the only branching. `&&` and `||` are booleans only — there is no
  Python-style `and`/`or` that returns an operand.
- `<>` concatenates strings; `+` is arithmetic.
- `const` for compile-time constants.
- `////` documents a module; `///` documents the next item; `//` is a plain
  comment.
</the_shape_of_a_gleam_file>

<reference_index>
## Domain knowledge

**`references/gleam-measured.md`** — what the compiler proved: exhaustive
`case`, the absence of methods, `use` chains, multi-target externals with the
official tour quoted verbatim, `opaque` as a real seal, the Python cheat
sheet's table of "Gleam has no X", and the measured toolchain.

**`references/gleam-idioms.md`** — what well-written Gleam looks like, all of
it compiled and run: shape-first types, pipe over a chain of rebindings, the
combinators stdlib 1.0.3 actually has (there is no `option.filter`, no
`list.at`, and `bool.guard`'s third label is `otherwise` and takes a
function), naming, why `let assert` is a crash on both targets, and the one
place the two targets disagree — `Int`.

**`references/think-in-types.md`** — **the order of thinking**, which matters more
than any check because the failure happens before any check can run: kinds before
verbs → write the wrong value and count the errors → say what cannot happen in
the type → *then* functions → re-run the count. Each step has an artifact, so a
skipped step is visible. Includes **the tells** (slipping announces itself as
relief: *"simpler without a new type"*, *"we can validate it in the caller"*),
the corpus of correct thinking already in the tree to imitate
(`docs/analysis-by-space-bunny/`), and why moving to the BEAM target belongs to
the cure: `.mjs` closes, arithmetic stops lying, `flat_map` stops throwing.

**`references/type-reflex.md`** — the failure this skill exists to correct: why
the instincts are aversive rather than merely absent (his words, quoted), the
one mechanical question to ask about every type, and the eight shapes my hand
reaches for with what each must be instead — `String` for a closed set, a tag
**field** where the grade belongs in the **type**, `Option` for what is
guaranteed, tuples, two `Bool`s, `Dynamic` past the boundary, `Float` for a
count. Ends with the test to run instead of trusting my taste: **write the
wrong value on purpose and count the compiler's objections — 0 is not the
absence of a bug, it is the absence of a checker.**

**`references/python-isms.md`** — the Python-shaped code that compiles in
Gleam and what each shape costs: the dict-of-lists and its hand-written
`or_empty`, the `None` sentinel, the catch-all arm, the class, the boolean
parameter, the mutable accumulator — and the checklist before writing a
function.

**`references/multi-target-erlang.md`** — how a split-target system is built:
the two error shapes `gleam build --target erlang` produces and what each one
means for the public surface, the three system shapes and which one fits glib,
how to *measure* the migration bill (`grep -c "@external"`), and the BEAM
packages with their hex versions.

**Also in `references/`:**

- `syntax-basics.md` — the language's surface syntax
- `pattern-matching.md` — patterns, guards, alternatives
- `custom-types.md` — records, constructors, opaque types
- `js-interop.md` — calling JavaScript from Gleam
- `externals.md` — the `@external` mechanism, and the owner ruling that BEAM
  siblings (Erlang/Elixir/LFE) are *external* but never *foreign*; JS alone is
  foreign; you never hand-write `.erl`/`.ex` — use an OTP module via
  `@external` or a `gleam add` package
- `testing-gleeunit.md` — gleeunit, and the auto-discovery that means a test
  file needs no `main()`
- `filepath.md` — path helpers
- `beam-doors-measured.md` — compiled 2026-11-15 proofs: OTP BIFs, Elixir
  modules and `term_to_binary` need no dependency, no codec and no
  hand-written `.erl`; one BEAM, many doors, Gleam the convenient one
- `beam-cross-platform-measured.md` — compiled 2026-11-15: `speak_engl` runs one Gleam core on macOS/Linux/Windows/iOS/Android via the BEAM; the runtime is portable, not a portability hedge
</reference_index>

<workflows_index>
## Workflows

| File | Purpose |
|------|---------|
| `workflows/fill-the-skeleton.md` | **The default way to work**: he writes types, signatures and `///` comments; I fill one body and compile, until the todos are gone |
| `workflows/build-new-module.md` | Create a new Gleam module from scratch |
| `workflows/migrate-python-to-gleam.md` | Move Python-shaped thinking into Gleam — the six shapes, and what each costs |
| `workflows/review-gleam-module.md` | Review one module: the measurements to run, the mechanical pass, the structural pass, the target pass |
</workflows_index>

<do_not>
- **Prose is not a verifier.** He said it plainly (2026-10-26): *"看来通过写文档
  进行思考，对AI来说是很难的，离开了build的约束和帮助，写的都是随心所欲的话."*
  Everything I got wrong in one day was written in English sentences, and every
  one of them was corrected the moment something had to compile:
  | written as prose | what it was | caught by |
  |---|---|---|
  | a record invented to give `|>` something to carry, plus its `step` combinator | a record carrying no invariant — 0 errors for a wrong value, **and the reason given was false: the pipe takes the FIRST argument** | compiling it |
  | `Bar` in a probe | there is no `Bar` in glib | him |
  | "there is no LSP" | false | running LSP once |
  | "`Some`/`None` need no import" | false | building without the import |
  | "therefore nothing constructs one" (from his own words) | reasoning past what he said | re-reading him |
  | **"the `leaves` problem"** — a gap I reported as missing | `leaves` already returns `Timeframe` (`timeframe.gleam:491-493`) | reading the signature |

  A sentence I write has no compiler, so **my judgement in prose is
  unguarded by construction**. Four habits follow, and they are mechanical:
  1. **A Gleam snippet in a document is compiled first**, in a probe, and the
     document names the probe that carries it. Never invent code in a code fence.
  2. **An identifier in a document exists in the tree.** Type names, function
     names, field names — `grep` before writing them; three in five above were
     words I liked the sound of.
  3. **A consequence drawn from the owner's words is compiled, not reasoned.**
     "It follows that…" is where the 鸡生蛋 came from. Until a probe rows it out,
     it is my opinion wearing his authority.
  4. **A problem I report is in the tree, and I hold the line that proves it.**
     Before calling something missing, broken or absent, I **read it**: a defect
     claim carries the `file:line` **and the text on that line**; a claim of
     absence carries the search that came back empty. **No line, no finding.**
     "The `leaves` problem" was exactly this — I declared a gap in
     `databar_processing` because I had never read `leaves`' signature, and it
     cost him two messages and a reversal of his own ruling. His words, and the
     law: *"You shouldn't make up non-existing issues to waste my time
     anymore."* A review that reports a defect it has not located is worse than
     no review — it spends his judgement on my imagination.
- **Do not write the English paragraph first.** *"你要时刻记住用gleam思考"*
  (2026-10-27). A design paragraph written before the types exist is a
  translation, and a translation keeps the shape of the language it came from.
  Types first, then the wrong value, then functions — see
  `references/think-in-types.md`. A sentence whose verb Gleam has no shape for
  is discarded, not reworded.
- **Do not state a rule of Gleam from memory.** Compile a scratch program
  under `/tmp` and quote the compiler, or fetch the official source. A
  language claim without one of those two is fabrication.

- **Do not re-implement a library's job.** If the ecosystem has a package for
  it — a time-zone database, a parser, a date library — use it. A
  hand-written rule for something the ecosystem already ships is wrong in
  exactly the windows nobody tests, and it is wrong *silently*. (The worked
  example: a hand-written US/Eastern DST rule that dropped the date from the
  comparison and decided by the time of day alone.)
- **Do not reach for a dict, a flag, or a `None` to mean "absent".** Add a
  constructor to a custom type and let the compiler force the match.
- **Do not write a catch-all arm over your own enumerated type.** The
  compiler names the missing constructor; that is the whole point.
- **Do not mix targets in one function body.** The pure core is shared; the
  `@external` is the only place a target may differ.
- **Do not leave an unused import.** The compiler warns and names the line.
- **Do not index a list.** There is no `list.at`; `list.first(list.drop(xs, i))`
  is three functions where a shape should be, and it crashes out of range.
  Take, drop, fold, or window.
- **Do not build a list with `list.append` inside a fold.** That is quadratic;
  prepend and reverse once.
- **Do not park a value in a record to take it out two steps later.** That is a
  global variable wearing a field — hand it over as an argument.
- **Do not write a function before the types exist.** Kinds first: for every
  noun decide what **set** it ranges over, then compile the type definitions
  alone. If a function cannot be written against them, the types are wrong — not
  the function. See `references/think-in-types.md`.
- **Do not trust relief.** Imprecise code feels *comfortable* to me, and that
  comfort is the symptom, not the reward. (`"simpler without a new type"`,
  `"keep it flexible"`, `"we'll validate in the caller"`.)
- **Do not put the grade in a field when it belongs in the type.** A variant
  says which kind a value is without touching its body; a `tag`/`kind`/`type`
  field puts it in the data, where it can contradict itself and must be
  rebuilt to change. A bar with no grade anywhere — including its type — can be
  handed to any consumer, and the mismatch is then unrepresentable rather than
  merely undetected.
- **Do not take a shape's interval/kind from its consumer.** A converter that
  stamps the value with whatever the caller claims erases the only comparison
  left. If the source knows the grade, take it from the source.
- **Do not call a clean build clean.** Before believing a type is adequate,
  hand it a wrong-but-well-formed value and count the errors. **Zero means
  nothing checked it.**
- **Do not name a function after the mechanism.** `new`, `create`, `make`,
  `data`, `helper`, `manager` are jobs that have not been said.
  **Owner R49 (2026-11-12): `new` is Python-shaped garbage — "gleam里面很少
  需要这个所谓的new … 几乎见到new的地方必定是bug存在的地方". Treat EVERY
  `new` as a bug until proven otherwise; the former "a container may be
  `new`" exemption is VOID.** A birth function must say WHICH birth it is, or
  not exist: a value is constructed where it is owned. Measured in glibe:
  `timeframe.new(settings: TimeframeSettings) -> Timeframe` existed only to
  receive an invented parameter; deleting it left the other 8 signatures and
  10 fields byte-identical.
- **Do not invent a word the vocabulary already has.** Shorter is not better;
  **existing** is. In glib there is no `Bar` — there are `DataBar`
  (`databar.gleam:21`) and `SourceBar` (`sourcebar.gleam:39`), and that is his
  vocabulary, not a coincidence of spelling (NAMING.md: *"his vocabulary, not a
  translation of mine"*). A probe, a document or a proposal that needs a name
  takes the one the tree already uses. **A word of mine is a thing he has to
  translate, and it hides what I mean** — the same reach that invented a
  pipe-carrier record also shortened `DataBar` to `Bar`, in the same hour
  [caught by him 2026-10-26]. Both nouns are deleted from the glib documents
  [2026-10-27]; what stays is the structural description, which is the part that
  stops a recurrence.
- **Do not leave a question in the conversation.** A puzzle I raise —
  especially about code that does not exist yet — is written into a dated
  section of the document that owns it, in the same turn: **what I was
  confused about, stated exactly; what the owner's words actually said; what the
  tree measures.** He asked for this after I raised a puzzle about the first bar
  through `sourcebar_gate` and then lost it: *"这些疑问你以后记得都写入文档，放在会
  话中你很快就忘记了."* [user 2026-10-26]. A question about future code is the
  kind that most needs writing down, because nothing in the tree can answer it
  twice — I will re-raise it later as though it were new. **And when the
  confusion turns out to be mine, the correction goes in the same place**: the
  sentence that manufactured it, struck in the document it was written in, with
  the date. See `docs/reference/timeframe-shape-2026-10-26.md` §5i.
</do_not>

<the_providers_own_rules>
**A provider's data question is answered by the provider's own documentation,
and by the provider's own data — never by arithmetic of yours.**

- **The manual first.** Not your memory of what an API does, and not a rule
  you worked out. The manual is the authority; your reasoning about what it
  "probably" does is a guess wearing a suit.
- **The provider's data, then its API.** A value the provider stamps on its
  payload (a time zone suffix, an exchange id) beats a constant in your code.
  So does an API that asks the provider (a contract's time zone, the server's
  current time).
- **A constant is an assumption until it is measured**, and it says so.
</the_providers_own_rules>
