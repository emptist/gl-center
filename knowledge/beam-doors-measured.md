# One BEAM, many doors — measured 2026-11-15

Canonical name: `/Users/jk/gits/gl-center/knowledge/beam-doors-measured.md`.
A **single-file hard link**, made with `ln` and no `-s`, exposes the same inode
as `~/.workbuddy/skills/gl-center/references/beam-doors-measured.md`.
This is the house model (`README.md` §1/§2/§5): one file, one `ln` per
consumer, no linked directory tree, no symbolic link. `stat -f '%i %l'` is
the check; `cmp` is only a byte-level sanity check.

Toolchain measured: Gleam 1.19.2 / OTP 29 / Erlang, Elixir 1.20.4 on the same
VM. Every claim below names the probe that produced it and its **real exit
code**. A claim about the language is compiled, not recalled; an `erl -noshell`
experiment is labelled as such and is not called a Gleam compile.

Owner, verbatim (2026-11-15): *"BEAM里面有的东西好像都不用另外做什么，直接可用，
gleam语言和erlang elixir都是BEAM的门，归元无二路，方便有多门，gleam是最方便
的那扇门"*; and *"你担心依赖BEAM的问题，不用担心，我就是打算靠BEAM吃饭的。
你没看到我最近的项目都是gleam"*. ⇒ BEAM is the platform, not a portability
risk to hedge against. "Cross-ecosystem readable" is not a requirement to
charge against a BEAM-native format.

## 1. A runtime API needs no dependency, no codec, no hand-written target source

Probe `/tmp/glibe_beam_door_probe`, `gleam run -m beam_door_probe`, **exit 0**.
`gleam.toml` held only `name`, `version`, `target = "erlang"`;
`manifest.toml` had **0 packages**; `src/` had **0 `.erl` files**. Four
`@external(erlang, ...)` lines reached `erlang:term_to_binary`,
`erlang:binary_to_term`, `erlang:monotonic_time` and `lists:reverse`, and all
worked. Two values of **different variants** round-tripped through ETF as
`True` each — the variant tag survives a BIF, no encoder was written.

Build output was `.beam` files plus the generated `@@main.erl` runner stub.
Gleam 1.19 emits Erlang abstract forms (`.abstr`) → `.beam`; no ordinary
per-module `.erl` source exists (`gleam-core.md` §9). **A green build is not
proof that no `.erl` was written** (§3).

One measurement is not a rule: the first probe asserted
`monotonic_time() > 0` and got `False`; this run's raw value was
`-576460751688905208`. The probe now prints the value only. Monotonic time is
an arbitrary origin, not a wall clock.

## 2. Elixir is a door to the same VM, not a bridge to another runtime

Measured on this machine: Elixir 1.20.4 and OTP 29. `:code.which(String)`
resolves to a plain `Elixir.String.beam`. In one `erl -noshell` session,
`code:ensure_loaded(lists)` and `code:ensure_loaded('Elixir.String')` both
return `{module, ...}`, and `'Elixir.String':upcase(<<"beam">>)` returns
`<<"BEAM">>`. From Gleam, one line

```gleam
@external(erlang, "Elixir.String", "upcase")
fn upcase(s: BitArray) -> BitArray
```

called through `gleam run -m elixir_door` printed `"BEAM"`, **exit 0**; the
compilation target stayed `erlang`, as `gleam-core.md` §9 requires (Elixir
keeps the `Elixir.` prefix but the `erlang` target).

Two facts, not one mechanism:
- OTP BIFs need **no configuration at all**; Elixir's standard library needs
  one `ERL_LIBS` code path — a deployment detail, not written code.
- An Erlang string literal is a **list**; Elixir's `String.upcase` wants a
  **binary**. Passing the list gives `function_clause`. That is the shape of
  the value, not an FFI boundary.

## 3. `@external` is not FFI and not hand-written Erlang

Official Externals guide, read 2026-11-15: the page uses **no** word "FFI";
*"Gleam on Erlang can use Erlang, Elixir, LFE, and other BEAM languages"*;
*"most projects won't use any at all"* is a statement about how often externals
are needed, **not** a goal of zero. `@external` is a normal, necessary Gleam
design; `gleam add` + `@external` is the whole way to a BEAM runtime API.

Three compiler probes (`/tmp/glibe_target_probe`, `target = "erlang"`, real
exit codes):

| Probe | Exit | What the compiler did |
|---|---|---|
| JS-only external | **1** | `error: Unsupported target` — the target declaration blocks the JS half |
| `src/hand_written.erl` + `@external(erlang, "hand_written", "go")` | **0** | produced `hand_written.beam`; **the compiler does not block hand-written Erlang** |
| stray `src/foreign.mjs` | **0** | inert, merely copied into the build output |

⇒ The ban is on **AI writing `.erl` / `.ex` / `.mjs` source into `src/`**, not
on the `@external` attribute. Confusing the two is the recurring mistake.
BEAM siblings are *external* but never *foreign*; JavaScript alone is foreign
(`knowledge/externals.md` §2/§5).

## 4. Serialisation is a runtime API, not a codec to invent

Probe `/tmp/glibe_format_probe`, **exit 0**. Two `@external` lines to
`erlang:term_to_binary` / `binary_to_term` round-tripped a six-field value
whose grade lives in the **variant**, with zero codec and zero new dependency;
two different variants were checked separately.

- `gleam add simplifile` → `Added simplifile v2.7.0`; `append_bits` is itself
  `@external(erlang, "simplifile_erl", ...)`. Writing two bars **one at a
  time** produced 145 bytes (73 per record), with no buffer and no `reverse`.
- Measured bytes for one bar: JSON object **98**, ETF **73**. For ten bars:
  positional JSON array **991**, JSON lines **989**, ETF whole list **727**,
  ETF per record **73 × 10**. A positional JSON array cannot append one bar;
  JSON lines / ETF-per-record / keyed stores can.
- **OTP 29 already ships** `mnesia`, `dets`, `ets` (`code:ensure_loaded` →
  `{module, ...}`). An `erl -noshell` experiment inserted three bars
  deliberately **out of time order** and looked them up by timestamp: all
  hit, variant tag intact. In a keyed store the file has no "order" property;
  order is a projection at query time. **This experiment is Erlang-level, not a
  Gleam compile** — labelled as such.
- `hex.pm` read 2026-11-15 really has Gleam-native `sqlight`, `marmot`,
  `parrot`, `cake`, `gloo`, `gsv`, `tysv`; BEAM-side `khepri`, `esqlite`,
  `concord`; time-series-adjacent `oban_met`, `explorer`. Do not assert a
  package is absent without searching hex.

`gleam_stdlib` already ships `int.to_string`, `bool.to_string`,
`string.join`, `bit_array.byte_size`. The **first** version of this probe
hand-wrote `int_to_string` / `digits` / `join_with` / `bool_to_string` and a
fixed-width codec — the exact opposite of `gleam-core.md` §8/§12. It was
rewritten; all numbers above come from the rewritten probe. Loading the core
is not the same as thinking with it.

## 5. A `List` shape consequence, compiled

`/tmp/glibe_format_probe/src/read_order.gleam`, **exit 0**. A file stored
newest-first `[30, 20, 10]`, read one record at a time and accumulated with
`[record, ..acc]`, yields `10, 20, 30`; `list.first` is the **oldest** bar.
The reader contains no `reverse`, no `append`, no `length`. Order on disk does
not constrain the consumer; the consumer's read shape does. A keyed store has
no order at all (§4).

## 6. What this file does NOT claim

- `term_to_binary/2` options and `binary_to_term/2`'s `safe` warning: the
  official pages timed out three times and returned only the page header.
  **No verbatim quote was obtained, so none is written here.**
- No claim about ETF cross-version / cross-VM compatibility, and no
  performance benchmark beyond the byte counts and O(1)/O(n) shapes above.
- No export format is selected. The format question stays open in the project
  that raised it; this file records language and runtime facts only.
- "BEAM-native" is a property, **not a cost**, per the owner's direction at
  the top of this file.

## 7. How a consumer finds this file

`ln /Users/jk/gits/gl-center/knowledge/beam-doors-measured.md <consumer>`
— one file, one link. A hard link cannot dangle: it is a second directory
entry for one inode. What can change is a **name**: an editor's atomic save
(temp + `rename`), `mv`, or `git checkout -- <file>` replaces that one entry
with a fresh inode and drops the link count by one; in-place writes (`>`,
`cp` over an existing link, `open(..., "r+")`) write through the inode and
every name sees them. Check with `stat -f '%i %l'`, and confirm
`find <dir> -type l` returns nothing. Cross-device `ln` is refused; the two
names here are on dev `16777231`.
