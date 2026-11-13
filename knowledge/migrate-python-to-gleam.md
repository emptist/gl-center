# Workflow: migrate Python-shaped thinking into Gleam

**This replaces the old TypeScript-migration workflow, which belonged to
another project entirely (its paths pointed at a repository that is not this
one, and it required a reference file that does not exist).** The migration
that matters here is Python → Gleam, because that is where the ugly code
comes from — the owner: *"The codebase is full of python-ish implementations,
which are ugly and stupidly complex and difficult to maintain."*

Read `references/python-isms.md` first: it is the catalogue of the shapes and
what each one costs.

---

## Step 1 — find the shapes, not the lines

Do not rewrite a file because it looks Python-ish. Look for the **six
shapes**, each of which is a sign that a type is missing a constructor:

| what you will see | what it means |
|---|---|
| a `Dict` keyed by something you control | the key should be a constructor |
| a helper named `or_empty` / `unwrap_or` / `get_or(default)` | an absent value that should be `Option` |
| a `Bool` field that says "has X yet" | the absence should be the value itself |
| a `_ -> default` arm over your own enum | the compiler would name the missing case |
| a `Dict` of lists of the same type | a series, not a lookup table |
| a `Bool` parameter that switches behaviour | two functions, or a type carrying the difference |

---

## Step 2 — write the type first, and let the compiler object

Before touching the logic, write the custom type and compile it. The
compiler will then list every place that must learn the new shape — **that
list is the work**, and it is the part a Python-shaped refactor always
misses.

```gleam
pub type Series {
  Series(bars: List(Bar))
}
```

Compile. If the errors name twenty call sites, that is twenty places where
the old shape was load-bearing. Each one gets a decision: does it need the
whole series, the head, or the length?

---

## Step 3 — replace the mutation with a fold

A Python loop that appends becomes a fold or a recursive function. Do not
keep the loop shape with a `let` rebound in sequence and a helper returning
`Nil` — that spreads the data flow across statements instead of making it the
argument of one expression.

```gleam
pub fn fold(bars: List(Bar), initial: Series) -> Series {
  list.fold(bars, initial, fn(acc, b) { Series(bars: [b, ..acc.bars]) })
}
```

---

## Step 4 — put the fallible parts in the type

A Python function that raises, or returns `None` for failure, becomes
`Result(a, e)`. The error type should carry **why**, and if the reasons are
enumerable, they should be constructors — then every caller is forced to
handle each one.

---

## Step 5 — keep the pure core pure

Everything that does not touch the outside world is written once and runs on
every target. Only the boundary carries an `@external`. If a function has to
be different on Erlang and JavaScript, it is a boundary function; if it is
not, it must not be one. See `references/gleam-measured.md` §4.

---

## Step 6 — prove it

```
gleam format --check src test
gleam build --target javascript
gleam test
```

And for a change of behaviour, not just of shape, a **mutation proof**: break
the thing the check protects and watch it go red. A green check that has
never been seen to fail is not a check.

---

## The checklist

- [ ] Every `Dict` of the diff is either gone or has a reason it cannot be a type
- [ ] Every `or_empty`-style helper is gone
- [ ] Every catch-all arm over an enumerated type is gone
- [ ] The compiler's error list was read **before** the logic was rewritten
- [ ] The pure core has no target-specific branch
- [ ] `gleam test` passes, and a broken version of it was seen to fail
