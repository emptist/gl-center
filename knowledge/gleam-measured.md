# Gleam for this project — what the compiler proved, not what a tutorial says

**Every claim here was compiled.** The probes are permanent in
`~/.workbuddy/skills/gl-center/probe/` (`src/q_*` build and run; `broken/`
holds the recorded refusals), and the commands are given so you can re-run them
rather than trust this file.

The companion is `python-isms.md` — the same language seen from the side a
Python writer comes from, because that is where the ugly code comes from.

---

## 1. The compiler decides truth; the language server answers "where"

**Corrected 2026-10-26.** This section used to say *"There is no LSP in this
project's toolchain"* — said without measuring, and false. Measured that day on
`.gleam` files: `hover` returns the signature **and its doc comment**,
`goToDefinition` resolves across modules, `findReferences` reaches `test/` too,
`incomingCalls` / `outgoingCalls` work, and `documentSymbol` lists a whole module
with types and line numbers. Use it wherever the reflex is `grep -rn`.

It never competes with the compiler: a diagnostics pane would only re-say what
`gleam build` says, slower. `gleam build` is the ground truth **for what
compiles**; the server answers what a thing *is* and where it lives.

Two properties make the compiler worth trusting:

**A `case` over a custom type must be exhaustive.** Probed:

```gleam
pub type Shape { Circle(radius: Float) Square(side: Float) }

pub fn name(shape: Shape) -> String {
  case shape {
    Circle(_) -> "circle"
  }
}
```

```gleam
error: Inexhaustive patterns
   ┌─ src/probe.gleam:19:3
19 │ ╭   case shape {
20 │ │     Circle(_) -> "circle"
21 │ │   }
   │ ╰───^
The missing patterns are:

    Square(side:)
```

**This is the engine of the whole language.** A new constructor is a compile
error in every `case` that must mention it — so a "closed set" is a type, not a
convention. The moment you find yourself writing a `catch-all` arm for a
value your own type enumerates, the type is the better answer.

**A missing arm is not a warning.** It is an error, and the error names the
missing constructor. Read it; it is a free list of the work.

---

## 2. There are no methods, and no `null`

Gleam is not object oriented, and the compiler says so when you try:

```gleam
let x = Some(1)
let _ = x.is_none()
```

```gleam
error: Unknown record field
   ┌─ src/probe.gleam:10:13
10 │   let _ = r.is_err()
   │             ^^^^^^ This field does not exist
The value being accessed has this type:

    Result(Int, a)

It does not have any fields.

Gleam is not object oriented, so if you are trying to call a method on this
value you may want to use the function syntax instead.

    is_err(value)
```

**Measured, and this bit us in this project:** `Option` has **no**
`is_none()` and `Result` has **no** `is_err()`. The function forms are
`option.is_none(value)` / `result.is_error(value)`. On the **JavaScript
target** the compiled `Result` is two classes with `isOk()` on each — there
is no `isErr()` at all, only a module-level `Result$isError`. A `.mjs` file
that calls `result.isErr()` dies at runtime, not at compile time.

The rule that follows: **absence is a value, not a null.** `Option(a)` means
"there may be an `a`"; `Result(a, e)` means "this succeeded or failed with a
reason". Both are constructors you match on.

---

## 3. `use` is the shape of a chain, not sugar

Decoders in this project are written as a chain, and the shape matters:

```gleam
pub fn decode_bar() -> decode.Decoder(BinanceSourceBar) {
  use open_time <- decode.field("open_time", decode.int)
  use open <- decode.field("open", decode.float)
  use high <- decode.field("high", decode.float)
  use low <- decode.field("low", decode.float)
  use close <- decode.field("close", decode.float)
  use volume <- decode.field("volume", decode.int)
  decode.success(BinanceSourceBar(open:, high:, low:, close:, volume:, open_time:))
}
```

`use x <- thing` is `thing` called with a callback that binds `x`. The
callback's last expression is the result. This is not decoration — it is what
makes a six-field decoder readable without a wall of `case`.

The same shape carries error propagation:

```gleam
use a <- try(parse_int(a_number))
use b <- try(parse_int(an_error))   // returns the error here
Ok(a + b)                            // never runs
```

---

## 4. Multiple targets, one Gleam function

**This is the capability that makes the BEAM target possible for this
project.** The official tour states it (`tour.gleam.run/advanced-features/
multi-target-externals/`, quoted verbatim):

> Multiple external implementations can be specified for the same function,
> enabling the function to work on both Erlang and JavaScript.
>
> If a function doesn't have an implementation for the currently compiled-for
> target then the compiler will return an error.

```gleam
pub type DateTime

@external(erlang, "calendar", "local_time")
@external(javascript, "./my_package_ffi.mjs", "now")
pub fn now() -> DateTime
```

**Probed and compiled locally** (gleam 1.19.2) — two `@external` attributes on
one function, one per target, and the project builds.

The tour's caveat is the whole design constraint:

> With Erlang concurrent IO is handled transparently by the runtime, while in
> JavaScript concurrent IO requires the use of promises or callbacks. If your
> code uses the Erlang style it is typically not possible to implement in
> JavaScript, while if callbacks are used then it won't be compatible with
> most Gleam and Erlang code.

**So the split is not "Gleam on one side, FFI on the other" — it is per
function.** A pure function is written once and runs on both targets; only
the function that touches the outside world needs two bodies. That is what
makes a split-target system possible at all, and it is what
`try_multi_target` proved for this family of projects.

The `gleam.toml` `target` field still chooses which target is compiled:

```toml
target = "javascript"   # or "erlang"
```

---

## 5. `opaque` is a real seal, not a comment

```gleam
pub opaque type BinanceSourceBar {
  BinanceSourceBar(open: Float, high: Float, ...)
}
```

With `opaque`, the constructor is **not** visible outside the module: another
module cannot build one, only receive one. Measured in this project: a
JavaScript caller trying to construct one is refused by the compiler
(*"Use of private value"*), which is the seal doing its job.

Use `opaque` when a value should only be made by the module that owns its
invariants (a provider's bar, a decoded record). Use a plain `type` when the
constructor is genuinely part of the interface.

---

## 6. Things that are not in the language

From the official Python cheat sheet (`gleam.run/cheatsheets/gleam-for-python-users/`),
the ones that change how code is written here:

| you want | Gleam has | so write |
|---|---|---|
| `class` with methods | **no OOP, and methods cannot be added to types** | a custom type plus module-level functions |
| `None` / `null` | `Option(a)` | match it; never a sentinel value |
| `raise` / `try` / `except` | `Result(a, e)` and `use ... <- try(...)` | return the error |
| `dict` literal | `dict.from_list([#("k", v)])` | or, better, a custom type |
| pattern-matching a dict | **not possible** | a custom type with constructors |
| `and` / `or` returning an operand | `&&` and `||`, booleans only | `case` |
| `+` for strings | `<>` | |
| `type Headers = list[tuple[str, str]]` | `pub type Headers = List(#(String, String))` | |
| `Final` for constants | `const` | |
| decorators | not in the language | |

Also from the sheet: **Gleam lists are immutable and homogeneous**, and
prepending is O(1) — `[1, ..list]`. `..` is also the list-pattern operator:
`let [a, b, ..rest] = xs`. Tuples (`#(a, b)`) are the **only** collection
that may mix types.

---

## 7. Time zones: the library carries them, and `gleam_time` does not

**`gleam_time` has no time zones.** Measured: its three modules are
`timestamp`, `calendar` and `duration`, and no function in them answers "what
is the offset in `America/New_York` on this date". The library that does is
**`tzif`**, which reads the **IANA tz database** — the same rules `pytz` gives
a Python system, and the same ones the platform's own `Intl` uses.

```gleam
import tzif/tzcalendar
import zones

let db = zones.database()
case tzcalendar.from_calendar(date, time, "America/New_York", db) {
  Ok([one]) -> Ok(one)
  Ok([]) -> Error("no instant")     // the hour the clocks skip
  Ok([_, _]) -> Error("two instants") // the hour the clocks repeat
  Error(_) -> Error("no such zone")
}
```

**`zones` is the data package for the JavaScript target** — the browser has no
`/usr/share/zoneinfo` to read. (`tzif_loader` reads the OS's files, which
works on a server and not in a browser.)

**Why the answer is a LIST, and why that matters.** A wall-clock reading can
be *impossible* (the hour the clocks skip) or *ambiguous* (the hour they
repeat). The library returns a list for exactly that reason. **A hand-written
rule has to decide what to do with those two hours, and every decision it can
make is wrong.**

**The worked failure, from this project.** A hand-written DST rule was written
first — the second Sunday of March to the first Sunday of November, computed
from `calendar.day_of_week` — and it was wrong in the way hand-written rules
are wrong: the comparison dropped the date and answered by the time of day
alone, so every reading on the day *before* a transition was decided by the
wrong day. **The moment the arithmetic is about a database of rules, the
database is already installed on the machine.** (Ruling: *"需要使用库的功能，
不要自己手搓"*.)

**A zone is a NAME, and it should come from the provider** — not from the
provider's documentation alone but from the provider's data and API: a stamp
that carries `TMZ` names its own zone, and `reqContractDetails` →
`contractDetails.TimeZoneId` names the exchange's. A constant in the code is
the last resort, and it is an assumption until measured.

## 8. `string.slice` is a byte offset and a byte COUNT

Measured: `string.slice("20240102", 4, 6)` is `"0102"`, **not** `"01"`. The
second argument is how many bytes to take, not the end position. The
end-position reading is the natural one and it is wrong: it hands the month
`"0102"`, which is no month, and every such value is refused.

This is the same shape as the `int`/`Float` distinction: **the API's
argument means something other than what its name suggests, and the
compiler will not tell you.**

## 9. The toolchain, measured


- **gleam 1.19.2** at `/opt/homebrew/bin/gleam` in this environment (the
  `glib-development` skill's `1.18.1` path is stale — check
  `which gleam && gleam --version`).
- `gleam format --check src test` — the formatter is the style authority.
- `gleam build --target javascript` — compiles.
- `gleam test` — runs the suite. **gleeunit auto-discovers test files**: a
  test file with no `main()` still runs. Only three older files in this
  project still call `gleam_unit.main()` themselves.
- The compiler **warns on unused imports** and names the line. Treat it as an
  error.

---

## 9b. Re-measured 2026-10-26 — and one thing I had wrong

All compiled and run on **gleam 1.19.2** (permanent probe directory:
`~/.workbuddy/skills/gl-center/probe/`).

- **`io.debug` does not exist.** *"The module `gleam/io` does not have a
  `debug` value."* **The debug printer is `echo`** (a keyword, not a function;
  it prints `file:line` then the value). I had been writing `io.debug` from
  recollection. **This is the exact failure the owner names: recalling training
  material instead of compiling.**
- `Ok` / `Error` are **prelude** constructors. `result.Error(1)` fails with
  *"Unknown module value"*; write `Error(1)`. **`Some` / `None` are NOT**
  (measured 2026-10-26, corrected: this file used to claim they needed no
  qualifier). Without `import gleam/option` every use fails — *"The custom type
  variant constructor `Some` is not in scope here."* Either form works once it
  is imported: `import gleam/option.{type Option, None, Some}` then `Some(x)`,
  or `import gleam/option` then `option.Some(x)`. Evidence:
  `probe/src/q_prelude_option.gleam` runs; `probe/broken/bug_no_option_import.gleam`
  is the control and does not compile.
- `option.is_none` / `result.is_error` **do exist as functions** (stdlib 1.0.3,
  `option.gleam:92`, `result.gleam:37`). What does not exist is **method
  syntax** — `value.is_none()`, `value.is_err()` — and there is no `is_err`
  at all (the name is `is_error`). `option.filter` and `list.at` do not exist.
- `use x <- result.try(..)` **chains and leaves early**: a later step is never
  reached after an `Error`. `use` works over any function taking a callback
  last, including a hand-written `Option` combinator. The tour warns against
  over-using it: *"Usually the regular function call syntax results in more
  approachable code!"*
- The pipe inserts the subject as the **first** argument, so `x |> f(a)` is
  `f(x, a)`. `f(_, 2, 3)` captures. Labels may be given out of order.
- `let assert` on a `None` **kills the program** — `Pattern match failed…`,
  `gleam_error: 'let_assert'`, and the rest of the function never runs. It is
  not a fallback; it is a crash with a good message.

---

## 9c. Re-measured 2026-10-27 — what an import is for

Two asked by him directly, both wrong as I expected them to be; compiled all the
same (`probe/src/q_frame.gleam`, `probe/src/q_needs_import.gleam`,
`probe/src/q_dir_leaf.gleam`).

- **Reading a field requires the type — no inference saves it.**
  `pub fn f(timeframe) { echo timeframe.working_databar.open }` gives **two**
  `error: Unknown type for record access` (*"I don't know what type this is"*) —
  one per level of the access. One level gives one. **Passing the value through
  untouched does compile** (`pub fn f(state) { state }`, type inferred), but the
  instant a field is opened the type is demanded, and with it the module. So a
  function cannot accept a `Timeframe` "anonymously" in order to dodge a
  dependency: touching it *is* the dependency.
- **`list.first` returns `Result(a, Nil)`, not `Option(a)`.** Returning
  `Option(Int)` from it is a `Type mismatch`; convert with a `case`, or return
  the `Result`. This is what `timeframe.gleam:580` asserts a pattern out of.
- A named module must be imported to be named even **qualified**: writing
  `q_dir_state.State` with no import line is `error: Unknown module`.

Consequence for placement (argued in full in
`docs/reference/timeframe-placement-2026-10-27.md` §3): since a lower module
must never name the container, whatever it owns has to take values, not the
record — and that, not the cycle, is the reason the cycle never appears.

## 10. The three questions to ask before writing Gleam

1. **Can a custom type say this instead?** If the answer is "a dict of lists
   keyed by an int, plus a flag for whether it is present" — the answer is a
   type with constructors, and the compiler will then force every reader to
   handle every case.
2. **What does the compiler already force?** The gate's exhaustive `case`, the
   decoder's field names, the `Result` of a fallible function. Build the
   design so the compiler does the work, and do not re-implement a check the
   type system gives for free.
3. **Is this the pure core or the boundary?** The pure core is written once
   and runs on every target. The boundary is where `@external` lives, and it
   is the only place a target may differ.

## Official sources worth keeping (verified 2026-10-26)

The language's own words, because this skill is about what Gleam guarantees, not
what I think it does.

- **Custom types** — <https://tour.gleam.run/data-types/custom-types/>. "A custom
  type is defined with the `type` keyword followed by the name of the type and a
  constructor for each *variant* of the type… Custom type variants can be
  pattern matched on using a case expression." Note the example constructors
  written **bare** (`Spring`, `Summer`) — no parentheses.
- **`SchoolPerson`** — the canonical Teacher/Student example comes from the
  official release notes:
  <https://github.com/gleam-lang/website/blob/b354a44691f3c70790aae3b5f612cca15f2fd8f/_posts/2022-02-23-gleam-v0.20-released.md>.
  Same page carries the programmatic philosophy quoted in `type-reflex.md`
  ("the compiler should be responsible for finding all these locations").
  The 2019 v0.6 notes describe the runtime shape: a constructor's **name** is
  carried with the value to distinguish it — corroborated here by reading the
  generated JavaScript (a class per constructor, `instanceof` to discriminate).
- **Conventions, patterns and anti-patterns** —
  <https://gleam.run/documentation/conventions-patterns-and-anti-patterns/>.
  On replacing booleans: "The bool type will be used for many unrelated pieces
  of data, so it is possible to mistake one bool value for another **without a
  type error to prevent the mistake**." Also the `LoggedInUser/Guest` visitor
  pattern — each variant carrying only what that case has, which is the same
  move as one type per grade.

**Remember:** gleam.run, not the tour, is the site he named. The tour is a page
inside it.
