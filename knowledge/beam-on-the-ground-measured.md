# BEAM on the ground — measured quirks when Gleam rides the VM

**Compiled 2026-11-18, Gleam 1.19.2, Erlang/OTP 29.1.2.** Every entry here was hit and fixed in `audio_splitter` v1.1.0–v1.2.1, a Gleam package on hex that runs whisper_cpp via NIF + ffmpeg via shell + OTP filelib + persistent_term, all on one BEAM.

The claim of this file: **OTP BIFs are well-known; the friction lives in the boundary between Gleam's type system and BEAM's runtime shapes.** Every point below is a place where BEAM behavior was not what I expected from reading Gleam docs alone, and every fix came from one compile error plus one runtime probe.

---

## 1. `Charlist` is opaque — `List(Int)` ≠ `Charlist` at compile time

**Probe:** Call `@external(erlang, "unicode", "characters_to_list")` on a UTF-16 LE binary. The BEAM returns the codepoints as `List(Int)`. But `charlist.to_string` expects `Charlist`, not `List(Int)`. Same runtime representation (a cons-list of ints), different Gleam types.

```gleam
// Compile error:
let chars: List(Int) = binary_to_chars(bytes)  // from unicode:characters_to_list
let filtered = list.filter(chars, fn(c) { c > 0 })  // List(Int)
let content = charlist.to_string(filtered)
//   ^^^^^^^^^^^^^^^^ Expected type: Charlist  Found type: List(Int)
```

**Fix:** Accept that BEAM interop returns `List(Int)`. Convert at the boundary:

```gleam
@external(erlang, "erlang", "binary_to_list")
fn binary_to_list(binary: BitArray) -> List(Int)
```

Then use pure Gleam to turn the codepoint list back into a `String`: pattern-match BOMs, pair up UTF-16 bytes, call `string.from_utf_codepoints` (which expects `List(Int)` — not `UtfCodepoint`, contrary to what one might guess from the name).

**Why not use `charlist.from_list`?** That function is designed for this exact case — but if your codepoints came from BEAM and are `List(Int)`, you still have to hand-wrap each one in the codepoint newtype. `string.from_utf_codepoints(List(Int))` skips the dance.

---

## 2. `int.divide` returns `Result(Int, Nil)` — `/` returns `Int`

**Probe:**

```gleam
int.divide(10, 3) |> result.unwrap(0)  // Ok(3) — works, but verbose
10 / 3                                   // 3 — same result, operator form
```

`float.divide` also returns `Result(Float, Nil)`; the operator form for floats is `/.`. Anywhere you reach for `int.divide(x, y)` and immediately unwrap it, use `/` instead. The Result form exists for catching divide-by-zero, but `/` crashes — so pick based on whether you actually care about the zero case.

---

## 3. `list.filter_map` (1.19) expects `Result(b, e)`, not `Option(b)`

**Probe:**

```gleam
// ❌ Compile error:
let result = list.filter_map(items, fn(x) {
  case predicate(x) {
    True -> Some(x)    // Expected Result, got Option
    False -> None
  }
})
// Expected: fn(a) -> Result(b, e)
// Found:    fn(a) -> Option(b)

// ✅ Correct:
let result = list.filter_map(items, fn(x) {
  case predicate(x) {
    True -> Ok(x)
    False -> Error(Nil)
  }
})
```

In older Gleam versions this took `Option`. It changed. Don't guess — compile.

---

## 4. `init.get_plain_arguments()` returns `List(Charlist)`, not `List(String)`

Every CLI entry point looks like this:

```gleam
@external(erlang, "init", "get_plain_arguments")
fn init_get_plain_arguments() -> List(charlist.Charlist)

pub fn main() -> Nil {
  let args = init_get_plain_arguments() |> list.map(charlist.to_string)
  // Now args: List(String)
}
```

Skip the `.to_string` and you get opaque `Charlist` values — they print as `[65, 66]` in debug, not `"AB"`. Confusing for an hour.

---

## 5. BEAM NIFs block SIGINT — Ctrl+C is useless when whisper is running

**Measured:** `whisper_cpp`'s `whisper_full` NIF runs C++ inference in the BEAM scheduler thread without yielding. SIGINT arrives but the scheduler cannot handle it until the NIF returns. On a 5-minute dialogue with the tiny model, that's 5 minutes of unkillable process from Ctrl+C alone.

**Fix:** Design batch runs in bounded chunks (`--limit N`). Each run is one BEAM VM lifetime; Ctrl+C works between runs because `list.fold` yields to the scheduler between items. You can never rely on Ctrl+C mid-NIF.

**Bonus:** macOS sandbox makes it worse — even `kill -TERM` from another terminal may not land; `kill -9` (`SIGKILL`) is reliable.

---

## 6. `filelib:fold_files` takes Erlang regex, not glob

```gleam
// ❌ Crashes:
@external(erlang, "filelib", "fold_files")
fn fold_files(dir: String, glob: String, recursive: Bool, fun: fn(String, accum) -> accum, init: accum) -> accum

fold_files(audio_dir, "*.mp3", True, ...)
// ** (ArgumentError) errors were found at the given arguments:
//   * 2nd argument: invalid regular expression

// ✅ Works — literal dot, end-of-string anchor:
fold_files(audio_dir, "\\.mp3$", True, ...)
```

Erlang regex needs literal escaping. `"*"` alone is invalid (quantifier with nothing before it). `"\\.mp3$"` means "literal `.mp3` at end of filename".

---

## 7. OTP `persistent_term` as a zero-cost cache — perfect for NIF models

**Measured:** `whisper_full` NIF loads the GGML model from disk each call — ~500ms on first call per dialogue. Put it in `persistent_term` once and the cost is:

```gleam
@external(erlang, "persistent_term", "put")
fn persistent_put(key: String, value: dynamic.Dynamic) -> Nil

@external(erlang, "persistent_term", "get")
fn persistent_get(key: String) -> Result(dynamic.Dynamic, Nil)

pub fn get_or_load_model(path: String) -> Result(Model, WhisperError) {
  case persistent_get("align_whisper_model") {
    Ok(cached) -> dynamic.decode(cached) |> result.map_err(fn(_) { ModelDecode })
    Error(Nil) -> load_model(path) |> result.map(fn(model) {
      persistent_put("align_whisper_model", dynamic.from(model))
      model
    })
  }
}
```

Loads once per BEAM VM, stays resident for its lifetime. No Mnesia, no ETS, no `gen_server`. One BIF pair. Whisper model + all 272 dialogues = 5 hours with one load; without caching = 5 hours + 2 minutes of model reload overhead.

**Why `dynamic.Dynamic`?** `persistent_term` is a generic store; you stash the model as opaque, then decode on retrieval. The compiler can't verify what's inside — so decode with a fallback `ModelDecode` error.

---

## 8. UTF-16 decoding from a BitArray — pure Gleam, one safe BEAM @external

**Measured:** `file:read_file` + `decode.at([1], decode.string)` fails on UTF-16. UTF-16 bytes have nulls in every other position; the UTF-8 decoder gives up.

**Solution:** one `@external(erlang, "erlang", "binary_to_list")` (BEAM BIF, always succeeds), then pure Gleam BOM dispatch:

```gleam
pub fn read_transcript(raw: BitArray) -> String {
  case list.take(binary_to_list(raw), 4) {
    [255, 254, .._] -> decode_utf16_le(binary_to_list(raw) |> list.drop(2))
    [254, 255, .._] -> decode_utf16_be(binary_to_list(raw) |> list.drop(2))
    [239, 187, 191] -> bit_array.to_string(raw |> bit_array.drop(3))
    _ -> bit_array.to_string(raw)
  }
}

fn decode_utf16_le(bytes: List(Int)) -> String {
  let pairs = window_every_2(bytes)      // [lo, hi, lo, hi, ...] -> [(lo,hi), (lo,hi), ...]
  let codepoints = list.map(pairs, fn(#(lo, hi)) { lo + hi * 256 })
  string.from_utf_codepoints(codepoints)
}

fn window_every_2(xs: List(Int)) -> List(#(Int, Int)) {
  case xs {
    [a, b, ..rest] -> [#(a, b), ..window_every_2(rest)]
    _ -> []
  }
}
```

**Why this is the right shape** (per `externals.md` §5): one BEAM BIF at the boundary, zero hand-written `.erl`, pure Gleam for the rest. If you tried `@external(erlang, "unicode", "characters_to_binary")` to round-trip through UTF-8, you'd hit `dynamic.Dynamic` decode gymnastics and the BOM detection problem would still be there anyway.

---

## 9. macOS TCC sandbox: child BEAM can't write to parent's `build/`

**Probe:** Spawn `gleam run -m batch` from inside another shell's subprocess — it hits `"Permission denied (os error 13)"` writing to `build/gleam-dev-erlang.lock`. macOS TCC restricts what child processes can write to, and the lock file is already owned by the parent beam.smp.

**Fix:** Run `gleam run` from your foreground terminal, not from any subprocess or script. The user's shell is the owner; child BEAM processes inherit that ownership correctly.

---

## 10. `gleam clean` > `rm -rf build/` — it also clears `.gleam/` caches

`gleam clean` removes:
- `build/` — compiled beam files, .app files, release artifacts
- `.gleam/` — dependency build caches, extracted NIFs, hex tarballs

`rm -rf build/` leaves `.gleam/` untouched. If you've been iterating on `whisper_cpp` NIF versions, `gleam clean` is the one that actually wipes everything so the next `gleam build` re-extracts the NIF from hex. The Gleam toolchain is one binary, and the author designed it to own this cleanup — use it.

---

## 11. `gleam publish` namespace pollution: consolidate under one package root

**Probe:** If your package exports multiple top-level modules (e.g., `alignment` and `batch`), `gleam publish` warns:

```
Your package defines multiple top-level modules: alignment, batch.
Defining multiple top-level modules can lead to namespace pollution and
potential conflicts for consumers.
```

**Fix:** Move everything under one top-level module named after your package:

```
# audio_splitter/ on hex.pm
src/audio_splitter.gleam       → pub fn main() for CLI entry
src/audio_splitter/batch.gleam  → audio_splitter.batch
src/audio_splitter/aligner.gleam → audio_splitter.aligner
```

This is a breaking change (consumers `import alignment.aligner` → `import audio_splitter.aligner`), so bump semver MAJOR. But hex.pm already has your old version; the new one is just v2.0.0. Gleam 1.19's warning is strong enough to treat as required, not advisory.

---

## Summary: the shape of a BEAM boundary function

The pattern that works every time, distilled from 12 fixes in one session:

```gleam
// 1. One @external per boundary. BEAM BIF only — no hand-written .erl.
@external(erlang, "erlang", "binary_to_list")
fn binary_to_list(binary: BitArray) -> List(Int)

// 2. Pure Gleam handles the shape the compiler knows.
pub fn read_transcript(raw: BitArray) -> String {
  case list.take(binary_to_list(raw), 3) {
    [239, 187, 191, .._] -> bit_array.to_string(raw |> bit_array.drop(3))
    _ -> bit_array.to_string(raw)
  }
}

// 3. Every public function has a /// doc that names the boundary.
// 4. One test that exercises the boundary.
```

BEAM gives you everything you need — but every BIF returns a runtime shape that Gleam will type-check against its own conventions. The friction is never in BEAM; it's in the translation between BEAM's universe and Gleam's. And every translation error is a compile error first, a runtime bug second — so let the compiler be your reviewer.
