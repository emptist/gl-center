# Gleam idioms — what "well-written Gleam" means, with the measurements

**Why this file exists.** `python-isms.md` says what is *wrong*. This file says
what is *right*, and every claim here was compiled and run under `/tmp/gleam_probe`
(gleam 1.19.2, stdlib 1.0.3), on **both** targets where the two differ. Where a
claim is about a stdlib signature, the signature is quoted from
`build/packages/gleam_stdlib/src/gleam/…`, not from memory.

The one sentence underneath all of it: **the shape of the code is the shape of
the data.** If the code is reaching for an index, a default, a flag or a
sentinel, the type is not carrying the shape and the reader is being asked to
remember it.

---

## 1. Shape first: the type carries what the code would otherwise check

```gleam
pub type ManualAction {
  Enter
  Exit
  Hold
}
```

instead of `fn signal(recognised: Bool, exited: Bool)`. Two booleans have four
combinations and the type says nothing about which of them exist; one
constructor per case has three, and a fourth cannot be spelled.

**The test:** if a case is impossible, can the reader *say so* in the type? If
the answer is "no, it is impossible because of a comment", the type is missing
a constructor.

Related, and the same money:

- **`Result(a, String)` is half a design.** The compiler cannot force a caller
  to handle each reason when the reason is a string. A `pub type BarError { … }`
  makes every reason a constructor, and then a missing arm is a compile error.
  (`String` is fine at a boundary where the text is only ever printed.)
- **A tuple of three or more is a type that has not been written yet.**
  `#(Float, Float, Float)` has no field names; a record has three.
- **`Option` for absence, `Result` for failure, never both, never neither.**

---

## 2. Expression, not statement

### Pipe, not a chain of rebindings

The Python-shaped habit is a sequence of `let x = step(x)` — statements
simulating mutation. The Gleam shape is the data flow as one expression:

```gleam
pub fn run(tf: Timeframe) -> Timeframe {
  tf |> indicator_step |> leaves |> branches |> strategy
}
```

A chain of rebindings is not *wrong*, and a `case` in the middle legitimately
breaks a pipe. But every `let same_name = …` is a place where the data flow
stops being visible, and five of them in a row is a loop written by hand.

### `use`, not nested `case`

`use x <- thing` is `thing` called with a callback that binds `x`. Two jobs,
both measured in this project:

```gleam
use a <- result.try(parse(a_number))   // error propagation; the rest never runs
use open <- decode.field("open", decode.float)  // decoder chains
```

`result.try` in a `use` chain: `Ok(2) |> chain` → `Ok(4)`; `Error("nope")` →
`Error("nope")` and the body does not run. **Measured.**

### The last expression is the value

There is no `return`. A function that binds a value and then names it on the
next line (`let v = …` / `v`) is a Python reflex; name the expression.

---

## 3. The combinators that exist — measured against stdlib 1.0.3

Read from `build/packages/gleam_stdlib/src/gleam/`, not from memory. The
surprises are the point of this section.

**`option`** — `all`, `is_some`, `is_none`, `to_result`, `from_result`,
`unwrap`, `lazy_unwrap`, `map`, `flatten`, `then`, `or`, `lazy_or`, `values`.

- **There is no `option.filter`.** The filter is `then` with a function that
  returns `Option`: `Some(3) |> option.then(keep_if_positive)` → `Some(3)`;
  `Some(-3) |> …` → `None`; `None |> …` → `None`. **Measured.**

**`bool.guard`** — the signature is the trap:

```gleam
pub fn guard(
  when requirement: Bool,
  return consequence: a,
  otherwise alternative: fn() -> a,
) -> a
```

- The third label is **`otherwise`**, and it is **lazy** — it takes a function.
  You cannot write `else:` — `else` is a keyword and the parser rejects it
  (*"Found the keyword `else`"*, measured). **Measured both ways.**
- Because the alternative is a closure, `bool.guard` is *not* shorter than a
  two-arm `case`. Use it where an expression is needed (a record field), not to
  look clever. **A plain `case` on a `Bool` is idiomatic Gleam and needs no
  excuse.**

**`list`** — the ones that stop you writing a loop:
`fold`, `try_fold`, `fold_until`, `fold_right`, `map`, `index_map`, `map2`,
`map_fold`, `filter`, `filter_map`, `find`, `find_map`, `take`, `drop`,
`take_while`, `drop_while`, `split`, `window`, `window_by_2`, `chunk`, `scan`,
`unique`, `sort`, `combinations`, `transpose`, `zip`, `flatten`, `append`,
`prepend`, `reverse`, `last`, `first`, `rest`, `length`, `is_empty`.

- **There is no `list.at`.** There is no index operator. `list.first(list.drop(xs, i))`
  is not "Gleam's indexing" — it is three functions standing where a shape should
  be, and it panics when `i` is out of range. **If you need the nth element you
  are iterating wrong**: take, drop, fold, or sort-and-take.
- **`list.append` is O(len(first))**, and `list.append(acc, xs)` inside a fold
  is quadratic. The accumulator is built by `prepend` and reversed once. This
  is the single most common performance shape in code written by someone who
  learned lists in Python.

**`result`** — `map`, `map_error`, `try`, `try_recover`, `all`, `values`, `or`,
`lazy_or`, `unwrap`, `lazy_unwrap`, `is_ok`, `is_error`, `nil_error`,
`replace_error`, `flatten`. **Measured: `Result` has no `is_err()`**, and on the
JavaScript target the compiled `Result` has `isOk()` and **no** `isErr()`.

**`order`** — `is_lt`, `is_eq`, `is_gt`, `negate`, `reverse`, `to_int`,
`compare`, `break_tie`. Comparing produces an `Order`; do not collapse it to a
`Bool` and then forget which two cases you merged.

---

## 4. Naming

- Files are `snake_case` and so are modules; the path *is* the module name.
  `web/branch_view.gleam` is `glib/web/branch_view`.
- Types and constructors are `UpperCamel`; functions and fields are
  `snake_case`.
- **Functions are verbs; fields and labels are nouns.** `interval.to_string`,
  `working_databar_archived`, `databar_from_sourcebar`.
- **A name must say the domain, not the mechanism.** `dict.new()` is fine
  because a container's empty state is its only birth. `Timeframe.new()` is not:
  *"no bar has been dealt with yet"* is a **domain proposition**, and a
  mechanism-word hides it. If the module's own comment already contains the
  sentence, the function name should be that sentence (`born`).
  Red flag list: `new`, `create`, `make`, `init`, `data`, `info`, `helper`,
  `manager`, `process`, `handle`, `update` — each is a job that has not been
  said.
- **A rename reaches the code and the prose.** Never a quote: his words stay
  verbatim.

---

## 5. `let assert` and `assert` are two DIFFERENT syntaxes — never swap them

Gleam has two assertion forms. They are not "the same keyword in two styles":
they are **different grammar** with different jobs, and confusing them is a
**syntax error**, caught before the program runs.

### `let assert <pattern> = <expr>` — the older form (bind + crash)

- Binds variables out of a **pattern** and crashes if the value does not match.
- The right-hand side of the `=` MUST be a **pattern** — `Some(x)`, `Ok(v)`,
  `Pair(a, b)`, a literal, a wildcard. A boolean expression is **not** a pattern.
- **Measured on both targets** with `let assert Some(x) = none`: it is `panic`
  with a nicer message — JavaScript throws and the process dies (`value: None
  {}`); Erlang prints `runtime error: let assert` / *Pattern match failed*. So
  it is not "an assertion in the Python sense"; it is a crash you promised the
  compiler would never fire.

### `assert <bool_expr>` — the newer form (standalone boolean guard)

- **New in Gleam v1.11.0** — the compiler rejects it on any older compiler
  (glib builds on 1.19.2, so it is fine). This is the form `gleam-idioms.md` §5
  did **not** mention when it was first written, which is exactly why the older
  section only knew `let assert` and never warned you the two are different.
- No binding, no `=`. A bare Boolean; it crashes only when it evaluates to
  `False`.

### Swapping them fails to PARSE — measured on 1.19.2

| you wrote | you meant | compiler error |
|---|---|---|
| `let assert a == b` | `assert a == b` (bool guard) | `Syntax error: I was expecting a '=' after this` |
| `assert Some(x) = v` | `let assert Some(x) = v` (bind) | `Syntax error: I was not expecting this` (Found `=`, expected …) |

The first row is the exact mistake made in glib's `timeframe.gleam`: a Boolean
comparison was written after `let assert`, which demands `<pattern> = <expr>`,
so the parser met `==` where it wanted `=`. The fix is to drop `let`:
`assert a == b`.

### When `let assert <pattern>` is legitimate

The value is impossible-by-construction *and* the comment names the
construction that makes it impossible (this project calls that UC-61). One or
two per module, each with its reason. A value a step cannot be without is a
**parameter**, not a field to unwrap — passing `databar: DataBar` deletes four
`let assert`s and adds a guarantee the compiler can see.

### When it is a symptom

The value was put into an `Option`/`Result` field a few lines earlier and taken
straight back out. **A value that a step cannot be without is a parameter, not
a field.**

---

## 6. State

- There is no mutation and no module state. A "loop" is `fold`, and the state
  is the accumulator.
- **Do not park a value in a record in order to take it out two steps later.**
  That is a global variable wearing a field. If step B needs what step A
  produced, A hands it to B — as an argument, or as a named record when there
  are two or three of them.
- **A record's field is either always meaningful or an `Option`.** A field that
  is `Some` for the duration of one function and `None` for the rest of the run
  is a parameter that was filed away.
- Prepending is O(1); `[x, ..xs]` is the cons. Build reversed, reverse once at
  the edge.

---

## 7. Module boundaries

- **The pure core imports no boundary.** A module that imports a view, a
  server, or a file writer is a module that cannot be tested without them.
- **A dependency injection is a function argument.** MVC/MVVM means the model
  names no view: `publish_model: fn(Timeframe) -> Nil` is an argument wired at
  the composition root, not an import.
- **Import direction is one way.** `timeframe → branch → leaf`. A cycle is a
  design error, not an inconvenience; break it by moving the shared thing down,
  not by importing up.
- **`pub` is a promise.** Every `pub fn` is a supported entry point. A function
  published only so a test can reach it should either be a supported step
  (written down as one) or be tested through the function that owns it.
- **`opaque` is a real seal**: outside the module the constructor is not
  visible, so the invariants hold. Use it for values that only one module may
  make (a provider's decoded bar).

---

## 8. Where the two targets differ — measured, not assumed

One probe, run on both targets, identical source:

```gleam
echo 9007199254740993
echo 9007199254740993 + 1
```

| target | output |
|---|---|
| JavaScript | `9007199254740992.0` and `9007199254740992.0` |
| Erlang | `9007199254740993` and `9007199254740994` |

**Every other line of the probe was byte-identical** — `bool.guard`,
`option.then`, pipe-into-a-labelled-argument, `case` guards, `use` +
`result.try`, a three-constructor type. The only difference is **`Int`:

- on **JavaScript** an `Int` is a float64, so integers past 2^53 lose precision
  *silently*, and `n` and `n + 1` can print the same number;
- on **Erlang** integers are arbitrary precision.

So: **the pure core is genuinely portable, and the portability is not
cosmetic** — it is arithmetic. A system that counts money, microseconds or
satoshis in `Int` is running different arithmetic on the two targets, and
neither target warns.

---

## 9. The checklist before you write a function

1. **Can a type say this?** A dict, a flag, a `None` standing in for a case, an
   empty list meaning "absent", a tuple of three — all are a constructor that
   has not been written.
2. **Am I indexing?** There is no `list.at`. Take, drop, fold, or window.
3. **Am I appending in a fold?** That is quadratic. Prepend and reverse.
4. **Is this value optional here, or only in general?** Optional in general and
   certain here means it arrives as a parameter, not as a field to unwrap.
5. **Would a `let assert` here be a crash or a statement?** Nine in a module is
   nine crashes.
6. **Is the name the domain or the mechanism?**
7. **Is this the core or the boundary?** Only the boundary gets an `@external`,
   and only the boundary is allowed to differ per target.
8. **Is the error a type or a string?** If a caller must behave differently per
   reason, it is a type.
