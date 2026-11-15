# BEAM cross-platform reach — measured 2026-11-15

Canonical name: `/Users/jk/gits/gleam-language/knowledge/beam-cross-platform-measured.md`.
A **single-file hard link**, made with `ln` and no `-s`, exposes the same inode
as `~/.workbuddy/skills/gleam-language/references/beam-cross-platform-measured.md`.
House model (`README.md` §1/§2/§5): one file, one `ln` per consumer, no linked
directory tree, no symbolic link. `stat -f '%i %l'` is the check; `cmp` is only a
byte-level sanity check.

Owner, verbatim (2026-11-15): *"BEAM非常坚固可靠并且小巧，跨一切平台，简直是不可多得的好东西，
只不过群众永远追逐热点而不知道用好东西而已。加上Gleam语言，简直是AI的救星，
AI整天忙忙碌碌，但是最终碌碌无为，很难把一个中等复杂的项目做成落地无隐患，
因为语言有问题，不能对治AI的先天性疾病。Gleam就是可以拿来治AI的好药。
关于BEAM跨平台，我的项目 speak_engl 已经证实了。"*

The philosophical half (BEAM is the good, neglected tool; Gleam's strong typing
is the cure for AI's congenital "can't land a project cleanly" disease) is the
owner's **view** — quoted, not asserted as a language fact. The cross-platform
half is **measured below** from his `speak_engl` project.

## What `speak_engl` proves

`speak_engl` is a Gleam-on-BEAM English-speaking coach engine. Its README states
the architecture directly:

> *"A reusable English-speaking coach engine lab built in Gleam on the BEAM.
> Runs on-device via mob (iOS/Android) and plushie (desktop) — **one Gleam core
> for all platforms, no server needed**."*
> *"The engine runs entirely on the phone."*

(`/Users/jk/gits/hub/prog_langs/swift/two_way_com_training/speak_engl/README.md`,
lines 1–3 and the "engine runs entirely on the phone" line.)

The same BEAM `.beam` files are embedded in the native shell per platform:

| Platform | Shell | Evidence |
|---|---|---|
| **macOS / Linux / Windows** | `plushie` (Gleam, Elm-arch) | `GLEAM_APP_TECH_STACK.md:215` *"Desktop (macOS, Linux, Windows) \| plushie"*; `:533` *"plushie.yml \| Desktop binary build \| macOS (also produces Linux/Windows cross-compiled binaries)"* |
| **iOS** (13+) | `mob` (BEAM embedded on-device) | `GLEAM_APP_TECH_STACK.md:214` *"Android + iOS \| mob \| BEAM embedded in native shell \| 0.9.27, production apps on App Store + Play Store"*; `:222-223` floor iOS 13+ |
| **Android** (9 / API 28+) | `mob` (BEAM embedded on-device) | `GLEAM_APP_TECH_STACK.md:222` Android 9 (API 28); `:642` mob Android floor verified against official support matrix |

The "one core for all platforms" claim is not prose — the CI matrix builds and
runs it on every target:

- `.github/workflows/test.yml`: `core` on `ubuntu-latest`, `mobile` on
  `ubuntu-latest` (`platforms/coach_spike`), `desktop` on `macos-latest`
  (drives the system `say` command for voice). OTP 29 / Gleam 1.19.2 /
  Elixir 1 on every job (`erlef/setup-beam@v1`).
- `.github/workflows/mob-ios.yml`: runs on `macos-latest`, downloads
  `otp-ios-sim-d199a49a (ERTS 17.1.1)` and boots an iPhone 17 Pro simulator —
  **a BEAM runtime cross-compiled for iOS**.
- `.github/workflows/mob-android.yml`: runs on `ubuntu-latest`, installs Android
  NDK `27.2.12479018` + Zig `0.17.0` (the C cross-compile driver mob requires)
  and builds a real `.apk` — **a BEAM runtime cross-compiled for Android**.
- `.github/workflows/mob-build.yml`: `gleam build` → BEAM on `ubuntu-latest`,
  then `mix compile --warnings-as-errors` in `platforms/coach_spike`, and
  `Code.ensure_loaded` confirms the modules load.

`GLEAM_APP_TECH_STACK.md:117-118` states the substrate fact: *".beam files from
all three languages [Erlang/Elixir/Gleam] are fully interchangeable in the same
BEAM process"*. That is why one Gleam core reaches five platforms: the runtime
is portable; only the native shell (`mob`/`plushie`) differs per target, and the
domain `.beam` is shared.

## Measurement boundaries

- This is a **project-level confirmation**, not a BEAM benchmark. No throughput,
  startup-time, or binary-size numbers are claimed here; the only size fact is the
  toolchain's own (`otp-ios-sim` ERTS 17.1.1, NDK 27.2.12479018).
- "Solid / reliable / small" are the owner's qualitative words (verbatim above),
  not measured in this file. What is measured is **reach**: one Gleam core
  compiles to `.beam` and runs on macOS, Linux, Windows, iOS, and Android.
- `speak_engl` uses `mob` (third-party) for mobile cross-compilation; the Zig/
  NDK steps are `mob`'s, not handwritten BEAM code. See
  `beam-doors-measured.md` §3 for the "no hand-written `.erl`" boundary.

## How a consumer finds this file

`ln /Users/jk/gits/gleam-language/knowledge/beam-cross-platform-measured.md <consumer>`
— one file, one link. A hard link cannot dangle; an editor's atomic save
(temp + `rename`), `mv`, or `git checkout -- <file>` replaces that one entry
with a fresh inode and drops the link count by one. In-place writes
(`open(..., "r+")`) write through the inode. Check with `stat -f '%i %l'`, and
confirm `find <dir> -type l` returns nothing.
