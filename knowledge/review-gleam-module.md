# Reviewing a Gleam module

**Input:** a module path (e.g. `src/glib/timeframe.gleam`).
**Output:** a numbered list of findings, each with `file:line`, the shape, and
the Gleam shape that replaces it. No finding without a line number.

**Rule:** the compiler verifies, the reviewer interprets. Every rewrite is
compiled before it is reported as a fix.

---

## Navigate with the language server before grepping

WorkBuddy's LSP tool answers these on `.gleam` directly (measured 2026-10-26):

| question | operation |
|---|---|
| what is this thing, and what does its doc comment say | `hover` |
| where is it defined, across modules | `goToDefinition` |
| every site that mentions it, `test/` included | `findReferences` |
| who calls this function | `incomingCalls` |
| what this function calls | `outgoingCalls` |
| what is in this file, with signatures and line numbers | `documentSymbol` |

Reach for it wherever the reflex is `grep -rn "name" src test`. It returns
**signatures with types**, which grep never did — and nothing it says is a guess
about the current tree, because it reads the current tree.

**It does not replace the compiler.** A diagnostics panel would only re-say what
`gleam build` says, slower. Correctness stays `gleam build` + `gleam test`; the
server answers identity and location.

---

## Step 0 — measure, do not skim

```sh
f=src/glib/timeframe.gleam
wc -l "$f"
grep -c "let assert" "$f"                 # §5: each one is a crash site
grep -n "io\.print" "$f"                  # side effects in the core?
grep -n "list.append" "$f"                # quadratic accumulator
grep -n "list.first(list.drop" "$f"       # indexing: there is no list.at
grep -n "Result(.*, String)" "$f"         # untyped errors
grep -n "^pub fn" "$f"                    # the promised surface
grep -rn "@external" "$f"                 # boundary or core?
```

And, to see whether the surface is actually used:

```sh
grep -rn "timeframe\.leaves\|timeframe\.branches" src test
```

## Step 0b — the wrong-value test (do this before forming any opinion)

My taste cannot be trusted here; the compiler can. **Write the wrong value on
purpose, hand it to the consumer, and count the objections.**

```sh
# in a scratch project under /tmp — never in the tree under review
gleam build --target javascript 2>&1 | grep -c "^error:"
```

Concretely: take each record that crosses a module boundary and construct a
value that is **wrong but well-typed** — the wrong grade, the wrong stage, the
wrong unit — then see whether it reaches the consumer that would misread it.

| errors | reading |
|---|---|
| 0 | nothing prevents it; the type is the finding. Report it with the script that proves it accepts. |
| ≥ 1 | report the shape anyway if the message needs interpreting |

Then the one question, per type: *can a wrong-but-well-formed value be
constructed and reach the consumer without any function objecting?*
`"we check it later"` counts as yes. See `references/type-reflex.md`.

## Step 1 — the mechanical pass (behaviour-preserving)

Walk `gleam-idioms.md` §2, §3, §4 against the file, in this order:

1. **Names that name the mechanism** (`new`, `create`, `make`, `data`,
   `helper`, `manager`). Replace with the sentence the doc comment already
   contains.
2. **Alias bindings** — `let y = x` where `y` is used once. Delete.
3. **Catch-all arms over your own type**, and `case c { True -> … False -> … }`
   where a library function says it (`order.is_lt`, `bool.negate`).
4. **`Result(a, String)`** where the caller must branch on the reason — make it
   a custom error type.
5. **`list.append` in a fold** — prepend and reverse.
6. **`list.first(list.drop(xs, i))`** — restructure; there is no index.
7. **Chains of `let x = step(x)`** — pipe what can be piped.

Each of these is verifiable: `gleam build` and the test suite afterwards, and
the diff should be behaviour-identical.

## Step 2 — the structural pass (needs the owner)

These change a signature or a type, so they are **proposed, not applied**:

1. **`let assert` count.** For each one: is the value impossible by
   construction (say which construction, in the comment), or was it parked in
   an `Option` three lines earlier? The second kind is a parameter.
2. **Tuples of three or more** — name the record.
3. **Two boolean parameters** — name the type.
4. **A field that is `Some` for the length of one function** — it is a
   parameter being filed away.
5. **`pub` functions no other module calls** — a promise nobody is using.
6. **A core module importing a boundary module.**

## Step 3 — the target pass

```sh
gleam build --target erlang    # in a package that intends to move
```

Any `Unsupported target` is a finding: either the function needs an Erlang
body, or it must not be `pub`.

## Step 4 — write it up

For each finding: **`file:line` · the shape · what it costs · the Gleam
shape**. Group them as *behaviour-preserving* versus *structural*, because the
first kind can be applied immediately and the second kind is a decision for
the owner.

**Do not open a plan from a review.** A review reports; the owner decides.

## Step 5 — file the questions, same turn

Every puzzle raised along the way goes into a dated section of the review's own
document, **not into the reply**: what I did not understand, the sentence I was
going on, the measurement that settles it, and — when the confusion was mine —
the line that manufactured it, struck with the date. A question kept in the
conversation is a question I lose and later re-raise as new.
[user 2026-10-26]
