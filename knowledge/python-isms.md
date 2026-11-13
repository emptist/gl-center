# Python-isms in Gleam — the ugly ones, and what they cost

**Why this file exists.** The owner said the codebase is *"full of python-ish
implementations, which are ugly and stupidly complex and difficult to
maintain"*, and that the cause is fluency: *"This cannot be changed until you
are very good at Gleam."* So this is not a list of style nits. Each entry is a
shape that **compiles** in Gleam — that is what makes it dangerous — and what
it costs.

The rule underneath all of them: **in Gleam, a type is cheaper than a
convention.** Python reaches for a dict, a flag, a `None`, and a comment
because the type system will not make the case impossible. Gleam can make it
impossible, and then the compiler does the remembering.

---

## 1. The dict-of-lists, and the hand-written `or_empty`

**The Python shape:** a dict keyed by an id, each holding a list, built by
mutating it in a loop, with a helper that turns a missing key into an empty
list.

```gleam
pub fn python_ish(bars: List(Bar)) -> Dict(Int, List(Float)) {
  let out = dict.new()
  list.each(bars, fn(b) {
    let existing = dict.get(out, b.idx) |> result_or_empty
    dict.insert(out, b.idx, [b.close, ..existing])
  })
  out
}

fn result_or_empty(r: Result(a, e)) -> List(a) {
  case r {
    Ok(v) -> v
    Error(_) -> []
  }
}
```

**What it costs.** Three things, all measured:

1. **A helper that exists only to paper over the type.** `dict.get` returns
   `Result(a, e)`, so the absence of a key became an *error*, and the error
   had to be swallowed by a hand-written function. That function is a bug
   factory: it silently converts "no such key" into "an empty list", and the
   difference between "no bars yet" and "bars that happen to be empty"
   disappears. In Python the same code is `d.get(k, [])` — one line, same
   hole.
2. **The compiler cannot help.** Nothing checks that every reader of the dict
   handles the empty-list case, because the type does not say there is one.
3. **It is not the shape the data has.** The data is a *series of bars*; the
   dict says "a lookup table of lists", which is a different thing, and every
   reader has to know it.

**The Gleam shape:** say what the thing is.

```gleam
pub type Series {
  Series(bars: List(Bar))
}
```

Now there is no absent key, no helper, and no `Result` to swallow — and a
reader who wants the bars writes `series.bars`.

**The general move:** when you find yourself writing `or_empty`, `unwrap_or`,
`get_or(default)`, or a `Dict` where the keys are a type you control, the
type is missing a constructor. Add the constructor.

---

## 2. The `None` sentinel, and the flag

**The Python shape:** `None` means "no bar yet", and a separate boolean means
"the engine has started". Two values, one fact, and a reader must check both.

**What it costs.** The two can disagree — the flag says started, the value
says empty — and nothing in the type system objects. Every reader re-checks.

**The Gleam shape:** `Option(a)` for "there may be one", and if "started" is a
separate fact, it is a separate field of a record. In this project the
kernel is exactly this: `working_databar: Option(DataBar)` beside
`databar_list: List(DataBar)` — *"the list is the history, and the
working_databar, and growing_things are the present"* (his words). The
absence is a **value**, and a reader cannot forget it because the type forces
the match.

---

## 3. The `catch-all` arm standing in for a missing constructor

**The Python shape:** a `match` with `_ -> default`, added so the code runs
even when the case was not thought through.

**What it costs.** The default is published as if it were a legitimate
answer. This project has the recorded instance: the old `BarState` carried
six boolean verdicts (`kdj_cross_up`, `kdj_bearish_left`, …) that the engine
**never computed**, so every reader of them got `False` — and the chart
printed them as if they were measurements.

**The Gleam shape:** when the type enumerates the cases, the compiler names
the missing arm:

```gleam
error: Inexhaustive patterns
The missing patterns are:

    Square(side:)
```

A catch-all over your own enumerated type is not defensive programming; it is
the compiler's job, done by hand and done wrong.

**The exception is real:** a case that is genuinely rare but genuinely
possible (bar one, where σ is undefined) deserves an explicit arm with an
honest value — and the comment should say why it is not a fallback. The
distinction is: *the type says this is possible* versus *I could not think of
the cases*.

---

## 4. The class, and the method that wanted to be a function

**The Python shape:** `class Account` with `def deposit(self, amount)`.

**The Gleam shape:** a type plus module-level functions. From the official
sheet: *"There is no OOP in Gleam. Methods can not be added to types."*

**What it costs.** A Python class hides its fields behind a name and invites
fields that only make sense in one method. In Gleam, a type's fields are all
there are, and a function taking the type says what it needs.

**The general move:** when a type grows a field that only one function reads,
the function wants to be a separate type.

---

## 5. The `None` return that means two different things

**The Python shape:** a function returns `None` for "failed" and also `None`
for "succeeded with no value".

**What it costs:** the caller cannot tell success from failure without a
second channel (a flag, an exception, a sentinel). This is why Python code
grows `try/except` everywhere.

**The Gleam shape:** `Result(a, e)` when failure is possible, `Option(a)`
when absence is the only other case. Never both, never neither. And the
error type carries **why** — a `String` here, but it could be a typed reason,
and the compiler would then force every caller to handle each reason.

---

## 6. The dict literal, and the tuple dictionary

**The Python shape:** `{"a": 1, "b": 2}`.

**The Gleam shape:** `dict.from_list([#("a", 1), #("b", 2)])` — and from the
official sheet: *"There is no dict literal syntax in Gleam, and you cannot
pattern match on a dict."*

**What that costs you, and why it is a gift:** you cannot pattern-match a
dict, so if you need to match on the *shape* of a lookup table, a dict cannot
express it — and a custom type can, and then the compiler forces every arm.

---

## 7. The `if x is not None` chain, and the boolean parameter

**The Python shape:** `def process(data, force=False)` — a flag that switches
behaviour, plus a chain of `is not None` checks.

**The Gleam shape:** two functions, or a type that carries the difference.

**What it costs:** a boolean parameter means the function has two behaviours
and the type does not say which. A caller passes `True` and the reader of the
signature cannot tell what happens.

---

## 8. The mutable accumulator

**The Python shape:** a list built by `append` in a loop.

**The Gleam shape:** `list.fold`, or a recursive function returning the new
value. Immutability means a "loop" is a function that returns its own next
state.

**What it costs in Python terms:** in Gleam it costs **nothing** — the fold
*is* the loop, and it is pure. The Python-ish version that appears in Gleam
is usually a `let` rebound in sequence with a helper that returns `Nil`, and
that is strictly worse: the data flow is spread across statements instead of
being the argument of one expression.

---

## 9. The checklist before writing a Gleam function

Ask, in this order:

1. **Could a custom type say this?** If the answer mentions a dict, a flag, a
   `None`, or an empty list meaning "absent" — the type is missing a
   constructor.
2. **Is the compiler already forcing something I am working around?** An
   exhaustive `case` means a catch-all is unnecessary; a `Result` means the
   failure is already in the type.
3. **Am I writing a helper that only exists to swallow an error?** That helper
   is a missing constructor.
4. **Is this the pure core or the boundary?** The pure core is written once
   and runs on every target (`references/gleam-measured.md` §4). Only the
   boundary needs an `@external`.
5. **Would a Python reader understand this in one pass?** If it needs a
   comment to explain what a helper is for, the type should have said it.
