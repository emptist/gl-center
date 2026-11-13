# The type reflex

Why this file exists, in his words (2026-10-26):

> *"我让你先整理 gleam language skill 然后才有资格谈这些问题，原因就是你的训练给你
> 根深蒂固的是一种不知道什么模式的编程概念，反正不是 strict types + functional，
> 也就是说那些令人作呕的明显错误，你毫无感觉，哦不是毫无感觉，是感觉非常非常舒
> 坦，哎吆，千万不能变，千万不要给明确的Type，有了type多难混呀。"*

Read that as a symptom list, not as a scolding. The failure is **aversive**: my
hand reaches away from precision, and reaching away feels good. So a rule that
says "prefer precise types" is useless — the part of me that must be corrected
is the part that reads the rule. What works is **a mechanical question about the
wrong value**, asked before the code exists, whose answer is yes/no.

## The one question

> **Can a wrong-but-well-formed value of this type be constructed, and reach the
> consumer, without any function objecting?**

Yes → the type is wrong. There is no third answer, and "we validate it later" is
a yes.

Every entry in the table below is that same question asked about one shape.

## The itches

Each row: what my hand reaches for, why it feels comfortable, what it must be.
The right-hand column is compiled (permanent probes in
`~/.workbuddy/skills/gleam-language/probe/`, gleam 1.19.2, JavaScript target).

| The reach | Why it feels good | What it must be |
|---|---|---|
| `String` for a closed set (`"1m"`, `"buy"`, `"running"`) | no new type to write, prints nicely, JSON already has it | a custom type with one constructor per member. Parsing happens **once**, at the boundary, returning `Result`. Past that line no bad spelling exists to be checked. |
| A `tag: String` / `kind: Int` field inside a record | adding a field is easy; no case to update | **variants**. The grade belongs in the *type*, where the body is untouched — not in the data, where it can contradict itself. His two pictures: the uniform **is** the variant (*"校服就是变体…不需要改变bar到身体"*); the field is **the grade carved into the bone** (*"后者不仅污染数据而且还无济于事，完全不能阻止一年级学生混进三年级课堂，骨头里的东西谁看得到"*). Measured in `probe/src/q_uniform_or_bone.gleam`: a careful reader and a careless one over the same field-bearing record **compile side by side, 0 errors**. A field obliges nobody — it pollutes *and* fails. |
| `Option` for a value that is guaranteed there | I am thinking "maybe it isn't initialised yet" | pass the guaranteed value **as the argument**; model the two states as two types. Every `Option` that later needs `let assert` was a lie about the call site. |
| A tuple `#(Timeframe, Option, Option)` | shorter than naming things | a **record** with named fields. Positional slots carry no meaning and survive renumbering silently. |
| Two `Bool` parameters | four call shapes from two words | one type with three constructors. The impossible combination stops existing instead of being commented away. |
| `Dynamic` / `Dict(String, x)` | "flexible", no schema to maintain | **the boundary only**. A `Dict` past the boundary is a record with the names moved into strings. |
| `Float` when the quantity is a count / epoch / price-of-currency | arithmetic just works | `Int` where it is `Int`. Measured, both targets: `9007199254740993` prints `9007199254740992.0` on JS and stays exact on Erlang — arithmetic differs **silently**. |
| Runtime check + error message | "I handled it" | if the check can fail, the value should never have been that type. Validation builds a new type, or it is a leak. |
| **A record invented so `|>` has one thing to pipe** — wrapping two values that already exist | it makes the pipeline read beautifully, and it *looks* like modelling: "the subject of the fold" | **nothing at all — two arguments.** Rejected by him on sight: *"提议了几个没用的 Type，导致简洁清晰的 timeframe module 陷入一片混乱"* (2026-10-26) and *"什么狗屁Dealing又是你瞎编出来的混账东西"* (2026-10-27). Two worse facts about it: **(a)** a record that accepts **any** pair states no law about them, so the invariant it was invented to carry (`bar` is `working_databar`) is still carried by hand, at every call — measured in `probe/src/q_useless_types.gleam`, a wrong pair compiles with **0 errors** and the consumer reads the wrong bar; **(b)** the premise was false too — I claimed the pipe feeds the **last** argument, when it feeds the **first** (`1 |> sub(10)` prints `-9`). **Pipe is a syntax fact, not a reason to mint a noun.** |

The last row is the trap that looks most like skill. A new type is not itself a
virtue — it must **make an illegal value impossible**, and a container of two
existing values makes nothing impossible. Ask the one question: can a wrong pair
be constructed and reach the consumer? For a pipe-record the answer is always
yes, which means the type earns nothing and costs a name nobody asked for.

## The three sentences to remember

1. **Parse, don't validate.** A boundary function returns `Result(T, E)`; every
   function after it takes `T` and cannot receive anything else. If validation
   lives in the consumer, every consumer must remember it, and one will forget.
2. **Make illegal states unrepresentable.** Every shape above exists because
   some illegal value was representable and a consumer didn't check it in time.
3. **A patch cannot restore a check the type never had.** Remedying after the
   fact — a guard here, a message there — adds scrutiny at points someone chose,
   and the wrong value uses the points nobody chose. Measured in glib
   (2026-10-26): a IntervalOneMinute bar reached an IntervalOneHour chart and was drawn; a later cleanup
   changed the code around the hole and **still** cannot tell the two apart,
   because after the cleanup `SourceBar` still carried no grade. **If the type
   has no room for the fact, no amount of later diligence puts it there.**

## The test I can run instead of trusting my taste

Write the wrong value **on purpose** and try to hand it to the consumer. If the
build accepts it, the type is wrong — regardless of how it feels.

```sh
# gleam counts the objection for me; I do not have to feel it.
gleam build --target javascript 2>&1 | grep -c "^error:"
```

Four measured outcomes of exactly that test, same mistake (a IntervalOneMinute bar handed to
an IntervalOneHour consumer):

| the grade lives in | errors | what happened |
|---|---|---|
| nowhere — one record | **0** | the minute bar was read as an hour bar, silently, all the way to the picture |
| a **field** in the record | **0** | same wrong answer, and a careful reader beside a careless one changes nothing |
| the type — one custom type, one constructor per grade | **1** — `Inexhaustive patterns`, naming the missing `Min1Bar` and `Hour1Bar` | the consumer must account for every grade |
| the type — **one type per grade**, sharing one body | **1** — `Type mismatch`, `Expected Hour, Found Minute` | it is refused at the call site; it never runs |

Read the last two rows together, because together they correct something I got
wrong for days. Variants of **one** type do not stop the hand-over — all grades
are the same type, so there is no `Type mismatch`; what fails is the consumer,
which may not leave a grade unaccounted for. To stop the *hand-over* itself, each
grade needs **its own type**. Both are uniforms; they differ in how far out the
refusal is placed.

## Identity is the constructor, never the payload

The strongest form of this is the one with nothing in it at all. The official
example:

```gleam
pub type SchoolPerson {
  Teacher()
  Student()
}
```

No fields, no tag, nothing to compare — and they cannot be confused, because
nothing consults the contents. His words: *"即使都不用那些不同fields，也一样不会把学生
和老师搞乱掉，因为完全不是根据你肚子里有什么来判断你是学生还是老师，是你的类型已经
定了。"*

Measured in `probe/src/q_empty_constructors.gleam` (gleam 1.19.2):

- A zero-field constructor is **already a value**, not a function. Writing
  `This()` in an expression is `Type mismatch` — *"This value is being called as
  a function but its type is: `Nothing`"*. Values are then passed with no
  parentheses at all.
- The generated JavaScript allocates it **once**: `const Nothing$This$const = new
  This(); export const Nothing$This = () => Nothing$This$const`. There is no
  per-use allocation, so there is no cost to speak of.
- Discrimination is `value instanceof This` — a class check on the pointer, not a
  comparison of any stored datum.

Gleam's own statement of why this matters, from the official v0.20 release notes,
describing exactly this example gaining a third constructor:

> *"This goes against Gleam's philosophy of making the compiler do all the hard
> and error prone bits of programming. The programmer shouldn't have to remember
> where to make changes for the program to be valid, the compiler should be
> responsible for finding all these locations and presenting them to the
> programmer to make a decision about what the logic should be."*

And measured, adding one constructor to the union in `probe/src/q_same_body.gleam`
produced **2 errors at exactly the 2 functions** that considered every grade — the
compiler found the locations. Adding a fourth **per-grade type** produced **0
errors and 0 sites**: existing single-grade consumers were untouched.

So the answer to "what does it cost" is: **nothing, and no computation.** The
grade is either the type or nothing at all.

Kept re-runnable: `probe/broken/bug_{c,a,u2}.gleam` (one `cp` each) and
`probe/src/q_{uniform_or_bone,same_body,empty_constructors}.gleam` (run).

That table is why this is not taste. **0 errors is not the absence of a bug; it
is the absence of a checker.**
