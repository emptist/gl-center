# Erlang target, and how a split-target system is built

**Everything here was run on this machine** — the commands are given so it can
be re-measured. The project's own feasibility note is
`glib/docs/reference/multi-target-beam-2026-10-25.md`; this file is the
*language* half: what the compiler demands, what the ecosystem offers, and how
to decide what moves.

---

## 1. The mechanism

The official tour, quoted verbatim
(`tour.gleam.run/advanced-features/multi-target-externals/`):

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

**Compiled locally on gleam 1.19.2**: two attributes, one function, both
targets.

> With Erlang concurrent IO is handled transparently by the runtime, while in
> JavaScript concurrent IO requires the use of promises or callbacks.

**So the split is per function, not per project.** Pure code is written once.
Only the function that touches the outside world needs two bodies.

---

## 2. What the compiler actually enforces — measured on glib

`gleam build --target erlang` in the glib tree (2026-10-26) fails with **13
errors in 2 modules**, and the two error shapes are the whole rulebook:

**(a) A `pub fn` with no implementation for the target is a package-level
error.** Not a warning, and not deferred to the call site:

```
error: Unsupported target
  ┌─ src/glib/ffi_helpers.gleam:4:1
  │
4 │ pub fn get_field(data: dynamic.Dynamic, field: String) -> dynamic.Dynamic
  │ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The `get_field` function is public but doesn't have an implementation for
the Erlang target. All public functions of a package must be able to compile
for a module to be valid.
```

**(b) A *private* external is only an error where it is used:**

```
error: Unsupported target
    ┌─ src/glib/execution/market_time.gleam:176:21
176 │   let ets_minutes = ffi_get_ets_minutes_from_now()
    │                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This value is not available as it is defined using externals, and there is
no implementation for the Erlang target.
```

**Two consequences worth designing around:**

1. **The public surface is the migration bill.** A private external costs one
   call site; a public one costs the build. Keeping a boundary function private
   is a real decision, not a tidy-up.
2. **Errors surface module by module.** Fixing the two reported modules does
   not mean the rest is clean — it means the compiler stopped reporting.
   Re-run until it is green; do not infer coverage from a short error list.

**The measurement, reproducible:**

```sh
cd /Users/jk/gits/hub/tools_ib/glib && gleam build --target erlang
```

---

## 3. Three shapes for a split-target system

| shape | what it is | when |
|---|---|---|
| **one package, two externals per boundary function** | the tour's mechanism; `gleam.toml` still names one `target` for the build, but every boundary function compiles on both | the system is one program and should stay one program |
| **two packages, one `target` each, joined by data** | `try_multi_target` did this: an Erlang engine plus a JavaScript getter, connected by a file | a spike, or two programs that genuinely have different deploy units |
| **one package, Erlang only** | drop the JavaScript externals | the boundary has a BEAM answer for everything |

**`try_multi_target` proved the second shape and it is a proof, not a
template** — the owner's own words: *"the proof project is just a proof, don't
copy code from it."* What it established is that the engine's shape (decode →
indicators → signals → a web server) runs on BEAM. What it did **not**
establish is the JavaScript half: it dies with `require is not defined in ES
module scope`, and its encoder is a stub.

**For glib the first shape is the right one.** The engine is one program; the
front-end page is not Gleam and never will be; and the pure core is the asset.

---

## 4. How to decide what moves — the measurement, not a judgement

The boundary is where `@external` is, and it is countable:

```sh
grep -rl "@external" src/ --include=*.gleam     # which modules are boundary
grep -rn "@external" src/ --include=*.gleam | wc -l   # how many functions
```

Modules with **zero** externals need **no change at all**: they already compile
for both targets. Modules with externals are the work list, and each one gets
either an Erlang body or a decision to stay JavaScript.

**The second test, and it is the one that catches design rot:** a module with
no `@external` that *imports* a boundary module is not pure. Count imports of
the seven boundary modules as well — those are the coupling that decides
whether the core can actually be lifted.

---

## 5. What BEAM offers that JavaScript does not — checked, not assumed

| job | package | version | note |
|---|---|---|---|
| HTTP client | `gleam_httpc` | 5.0.0 | *"Gleam bindings to Erlang's built in HTTP client, httpc"* — **Erlang only** |
| HTTP server | `mist` | 6.0.3 | *"a misty Gleam web server"*; used by `try_multi_target`. WebSocket support: check its docs before promising it |
| files | `simplifile` | 2.7.0 | *"Basic file operations that work on all targets"* — **both targets**, so it can replace a JS file FFI without giving up JavaScript |
| Erlang runtime | `gleam_erlang` | 1.3.0 | *"Types and functions for programs running on Erlang!"* — processes, atoms, the runtime itself |

(Versions read from hex.pm on 2026-10-26. Re-check before pinning.)

**And the arithmetic reason, which is not on any feature list:** measured in
`gleam-idioms.md` §8, `Int` is a float64 on JavaScript and arbitrary precision
on Erlang. A system that counts in integers is running different arithmetic on
the two targets, silently.

---

## 6. What should NOT move

- **The browser.** `priv/index.html` and the page's JS are not Gleam; there is
  no target for them and there should not be.
- **Anything whose only client is on npm.** A provider with a socket protocol
  and no BEAM library (IB's TWS) has no Erlang path. `try_multi_target` says it
  outright: *"IB symbols get no native path here on purpose."*
- **A boundary that already works and has no BEAM equivalent cheap enough to
  matter.** Moving code is not a virtue; the virtue is that the core can move.

---

## 7. The order of a migration, if one is opened

1. **Count the externals.** That is the bill, not an estimate.
2. **Prove the core first**: copy the zero-external modules into a scratch
   package with `target = "erlang"` and run the tests there. If that is green,
   the question was never "can the core move".
3. **Give each boundary function an Erlang body** — one `@external(erlang, …)`
   beside the existing `@external(javascript, …)`. Both stay; the function does
   not choose, the build does.
4. **Keep `gleam build --target erlang` in the guard suite** from step 3
   onwards. A boundary that works on one target and not the other is exactly
   the bug nobody notices on their own machine.
5. **Do not start a phase to do any of this** unless the owner opens one.
   Documenting that a thing is possible is not an obligation to do it.

---

## 8. Erlang-interop gotchas (measured on `speak_engl`, 2026-11-08)

Concrete instances of §1–§5 above, proven by compiling and running on macOS
(OTP 29 / Gleam 1.19.2). The principle is §8 of `gleam-core.md` ("use
`gleam_erlang`, do not replicate it"); these are the sharp edges:

- **`charlist` / `atom` are in `gleam_erlang`, not stdlib.** `gleam add
  gleam_erlang` (v1.3.0) provides `charlist.Charlist` / `atom.Atom` and the safe
  `atom.get(String) -> Result(Atom, Nil)`. Hand-rolling BIFs
  (`erlang:binary_to_list`, `binary_to_atom`) is the §8 anti-pattern — the
  "clever" path that was wrong.
- **`os:cmd` demands a charlist, not a binary.** Passing a Gleam `String`
  (UTF-8 binary) dies with `erlang:error(Badarg)` at `os:cmd`. Convert with
  `charlist.from_string`. (An Erlang REPL hides this: shell string literals are
  lists, not binaries.)
- **Elixir NIFs need the `Elixir.` prefix** (§9 rule): the `whisper_cpp` NIF is
  called as `Elixir.WhisperCpp.load_model` / `.transcribe`.
- **`decode.field` is 3-arg** in `gleam_stdlib` 1.0.5: `field(name, decoder,
  next)`; the bare 2-arg form is gone. Use `decode.field("text", decode.string,
  decode.success)`.
- **Wrap unsafe FFI in `Result` + dedicated external types** — `dynamic.Dynamic`
  stays only at the internal NIF boundary, never in a public signature.
