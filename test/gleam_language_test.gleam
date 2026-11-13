//// Plan item: .planning/phases/01-knowledge-core/01-01-PLAN.md
////
//// WHO READS THIS FILE: `gleam test` calls `main` and reads the two `assert`
//// expressions. Each one reads a `Stage` constructor through
//// `gleam_language.to_string` and compares the written boundary spelling.
//// Nothing else in this package is computed yet.

import gleam_language

pub fn main() {
  assert gleam_language.to_string(gleam_language.Virtual) == "virtual"
    as "the Virtual stage must spell as virtual at the boundary"
  assert gleam_language.to_string(gleam_language.Entity) == "entity"
    as "the Entity stage must spell as entity at the boundary"
}
