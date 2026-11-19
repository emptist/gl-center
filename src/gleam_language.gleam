//// Plan item: .planning/phases/01-knowledge-core/01-01-PLAN.md
////
//// WHO READS THIS MODULE, AND WHAT IT WRITES. `gleam docs build` reads every
//// `////` / `///` line below and writes HTML into build/dev/docs;
//// `gleam export package-interface` reads the same lines and writes them
//// into the `documentation` list of `modules["gleam_language"]`. A consuming
//// project declares `gleam_language = { path = "../../../gl-center" }`
//// in its `[dependencies]` and reads `Stage` / `to_string` through
//// `import gleam_language`. Measured 2026-11-13: a path dependency compiles
//// and is importable, but the consumer's own `gleam docs build` does NOT
//// render this dependency's `////` text — the documentation is produced by
//// THIS package, in THIS directory. `to_string` below reads one `Stage`
//// value and writes its boundary spelling; that is the only value this
//// module computes.
////
//// 1. THE TWO SHAPES ARE ONE GLEAM SYSTEM (owner verbatim, 2026-11-13):
//// "protocol 在 Swift 里面弄的很神秘复杂，其实不就是 gleam 一个体系两个用法
//// 吗？虚体的types functions 就是protocol想要做的事情，虚体的编译完全可以
//// 成功的，如果编译错误就可发现设计错误，跟Swift protocol错误一样。实体的
//// types 和 functions 就是 实现呀。一个gleam 虚实两用，完美。"
//// There is no protocol, trait or type class in Gleam (gleam-core.md §1).
//// A fully annotated `pub fn` signature plus its types IS the requirement:
//// it compiles with an empty or `todo` body, and a wrong parameter order,
//// a wrong subject position or a wrong return type is a compile error.
////
//// 2. THE ORDER (owner verbatim, 2026-11-13): "unit test这一步在框架初步
//// 建完，复查没问题之后。下一步是填充具体实现。" and "框架搭建和测试不就是
//// 设计阶段吗". So framework and tests BOTH belong to the design stage;
//// filling bodies is a LATER stage. A skeleton that compiles is not an
//// unfinished program, it is the design artifact.
////
//// 3. THE METHOD (owner verbatim, 2026-11-13): "从任何一个点切入，跟着逻辑
//// 走，必然发现缺环，然后就去设计补上，等所有的通路都没有缺环，设计不就是
//// 完工了？" Every sentence in a design must name the source, the type,
//// the destination and how the value travels. Owner's counterexample:
//// "比如你说一根bar到来，这句简短的话，已经说错了好多部分" — what bar,
//// from which data source, of which external type, to where, by which
//// function. That one sentence exposed an entire missing layer: a data
//// source's OWN raw bar, which is neither the standard `SourceBar` nor the
//// internal `DataBar`.
////
//// 4. THE DIVISION OF WORK (owner verbatim, 2026-11-13): "关键是，你这次是
//// 把type搞对，也就是那一个type的对应模块做什么工作，这个分工搞清楚，不要
//// 搞得乱七八糟越俎代庖". glibe/docs/RULINGS.md R50 records the owner's
//// English ruling verbatim: "even if it is called, it should be defined in
//// its belonging to module". The call site is not the owner. Functions
//// follow the value they read and write, and R47 forbids the self-exempting
//// phrase "the reader lives elsewhere" — a `////` line must translate into
//// who reads and writes WHICH concrete value. R47 §2: one type, zero
//// fields and zero functions is not simplicity, it is emptiness.
////
//// 5. A TYPE CARRIES THE FACT, A FIELD DOES NOT. Owner (verbatim): "你的左手
//// 根本不知道他是左还是右" and "Type就是用来做这件事情的，我甚至给了命名
//// 规范 SourceBarOneHour". A grade is a constructor (`SourceBarOneHour`),
//// not an `interval: Interval` field; `Timeframe` may hold a
//// `growing_target_sourcebar` and STILL not know its own period, because
//// the period lives in the `SourceBar` variant it holds. Owner verbatim on
//// the other side of that boundary: "DataBar不需要变体的原因是，不需要转换，
//// 转换周期的工作是在SourceBar层面完成的". No variant exists to carry a
//// change that never happens after `to_databar`.
////
//// 6. A STREAM IS NOT A LIST. Owner verbatim: "合成不能用list走，想清楚，
//// 要用stream单bar累计" and, on the accumulating design, "就是这个思路，
//// 思路是对的". Owner verbatim on the naming round: "如果是你就需要
//// IbSourceBarFiveSecond 然后再 ib sourcebar 的模块里面， 定义 pub fn
//// five_second_to_one_minute, etc. 这些都是设计思维，不需要落到实体层面".
//// So one arriving bar calls one function once: state in, state out,
//// `None -> Some -> None`, and only a UTC period boundary emits a finished
//// bar. seib is OOP and is evidence of the idea only, never of the shape.
////
//// 7. THE COMPILER HAS A DIFFERENT JOB IN EACH STAGE. In the virtual stage
//// it checks the design: `gleam check`, `gleam docs build` and
//// `package-interface.json` are anti-drift checks on the signatures and
//// their documentation. `gleam build --warnings-as-errors` is a FIXED gate
//// from the first skeleton (glibe R48): its red output is the itemised
//// to-implement list, never a failure to be exempted by category and never
//// silenced with `_` discard names. In the entity stage the same command
//// turns green one body at a time. A clean build is NOT proof that a design
//// is right: three different layer shapes for source-bar composition all
//// compiled with 0 errors on 2026-11-13, and the choice between them was
//// decided by who was forced to carry a value it does not own.
////
//// 8. THE LAYER PROBE, AND ITS RESULT (owner verbatim, 2026-11-13):
//// "why growing_target_sourcebar, since this field is in timeframe, and
//// what timeframe will get what kind of target (interval), this is KNOWN
//// to Instument, and the composing work seems ought to be at instument
//// layer, you can try it in different layers to see which one can make
//// types satisfied in the most natural simplest way." Three shapes were
//// compiled in a throwaway package: Instrument layer
//// `fn(Instrument, Interval, IbSourceBar) -> #(Option(SourceBar), Instrument)`;
//// Timeframe layer `fn(Timeframe, Interval, IbSourceBar) -> Timeframe`;
//// input boundary `fn(Option(SourceBar), Interval, IbSourceBar) -> ...`.
//// All three: 0 errors. Instrument won because it holds the
//// `Dict(Interval, Timeframe)` key; the other two must be handed an
//// `Interval` that belongs to someone else.
////
//// 9. PROVENANCE. Rulings R19 / R37 / R39 / R40-A / R41 / R47 / R48 / R50
//// above are project-specific rulings in glibe/docs/RULINGS.md, cited as
//// the place they were recorded — they are not universal Gleam law, and an
//// AI's own record of a ruling is not owner vocabulary. The language facts
//// come from the single-source `gleam-thinking-core.md` at the root of this
//// repo — ONE inode shared by the skill's authoritative copy, the glibe
//// mirror and the speak_engl mirror, so there are no longer several
//// versions of the card. The rest of the skill's documents sit one level
//// deep in `knowledge/`, each a single-file hard link: in Unix a link is
//// always one file, never a directory. Nothing in this module is an
//// implementation of a business rule.

/// The two shapes of one Gleam system. `gleam_language.to_string` reads this
/// value in its `case`; a consuming project reads the type through
/// `import gleam_language.{type Stage, Virtual, Entity}`.
pub type Stage {
  /// The design stage: modules, types, annotated signatures, `////` / `///`
  /// documentation and the tests that pin them. `to_string` reads this
  /// constructor and writes `"virtual"`.
  Virtual
  /// The development stage: the bodies behind those signatures.
  /// `to_string` reads this constructor and writes `"entity"`.
  Entity
}

/// Boundary spelling of a `Stage`. The model stays the closed set above;
/// the `String` exists only where the stage crosses out of the type.
pub fn to_string(stage: Stage) -> String {
  case stage {
    Virtual -> "virtual"
    Entity -> "entity"
  }
}
