+++
title = "Varyk 0.2.0: closures, iterators, and patterns"
description = "Milestone 4 adds closures as the arguments of built-in calls, iterator chains, if let and while let, nested, literal, and range patterns, HashMap, as, derived clone and ==, and getters that return part of their value with no copy."
date = 2026-09-29
+++

Varyk 0.2.0 is on crates.io. It is milestone 4 of the [roadmap](/design/roadmap/), and it is about the language: the everyday code of a service that milestone 3 made awkward. Milestone 3 connected Varyk, a language for backend services that compiles to Rust, to Cargo and the Rust ecosystem. Milestone 4 adds closures, chains over collections, richer patterns, `HashMap`, and functions that return part of what they are given without a copy.

## What is in it

**Closures, as the argument of a call.** `|n| n * 2` works as the argument of `map`, `map_err`, `filter`, `any`, `all`, and `find`. A closure has one parameter with no type written, reads the names around it, and never changes them. It is never a value of its own: a closure in a `let`, passed to a Varyk function, or returned is an error.

**Chains.** A chain starts at `v.iter()`, `s.split(sep)`, `m.keys()`, or `m.values()`, passes through any number of `map`s and `filter`s, and ends at `collect`, `count`, `sum`, `any`, `all`, or `find`, or as the head of a `for`. In the generated Rust it is written as it is.

```varyk
let evens = numbers.iter().filter(|n| n % 2 == 0).count();
let names: Vec<string> = users.iter().map(|u| u.name.clone()).collect();
```

**Patterns.** `if let` and `while let`; variants with named fields, `Event::Click { x: 0, y }`; nested patterns, `Some(Shape::Circle(r))`; literals and `..=` ranges, `90..=100`; and `match` on numbers, `bool`, and strings. Varyk checks that every value fits an arm (V0204) and that every arm can run (V0205), and the error names a value no arm fits.

**`HashMap`, `?` on `Option`, `as`, and `parse`.** `HashMap` has `insert`, `get`, `contains_key`, `len`, `keys`, and `values`. `?` now works on an `Option` in a function returning one. `as` converts between number types with Rust's rules, `s.parse()` gives an `Option`, and `Option` and `Result` get their first methods: `is_some`, `is_ok`, `is_err`, `unwrap_or`, `map`, `ok_or`, `ok`, and `map_err`. There is still no `unwrap` or `expect`: a value that is absent is something to handle, not a reason to stop the program.

**`.clone()` and `==` on your own types.** A struct or enum whose fields allow it gets `Clone` and `PartialEq` derived, so `.clone()` and `==` work on it, and derives read from an imported Rust type count too.

**Getters without copies.** A function may return part of one of its parameters, and nothing is written for it: Varyk sees from the body that every return is part of the same parameter. `display_name` needed a `.clone()` in milestone 3; now the generated Rust returns a reference into `self`:

```varyk
fn display_name(self) -> string {
    if self.nickname.is_empty() { self.name } else { self.nickname }
}
```

```rust
fn display_name(&self) -> &str {
    if self.nickname.is_empty() {
        &self.name
    } else {
        &self.nickname
    }
}
```

The result is another name for part of the value passed in, like a field, so that value cannot change while the result is used. A Rust function in a `.rs` file whose elided lifetime ties its result to one parameter, such as `fn first_word(s: &str) -> &str`, imports the same way.

**New diagnostic codes.** V0208 is a value that must be used where it is made: the `Option` of `get` on a stored value, which is looked into right there with `match` or `if let`, or a chain left unfinished. V0308 is a function returning part of one parameter in one place and part of another in another. The [language reference](/learn/reference/#error-codes) has the full table.

Six new example programs show it in use, and the [examples](/learn/examples/) page has them with their output. This is `words.vr`:

```varyk
fn main() {
    let text = "the cat saw the dog and the cat ran";
    let mut counts: HashMap<string, i32> = HashMap::new();
    for word in text.split(" ") {
        let n = counts.get(word).unwrap_or(0) + 1;
        counts.insert(word.clone(), n);
    }
    let mut words: Vec<string> = counts.keys().map(|w| w.clone()).collect();
    words.sort();
    for word in words {
        if let Some(n) = counts.get(word) {
            println!("{} {}", word, n);
        }
    }
    println!("{} distinct words", counts.len());
}
```

## The breaking change

The breaking change is in the `varyk-syntax` crate, not in Varyk: its syntax tree gained new expressions, statements, and patterns, and Rust code that matches on that tree must handle them. Every program in the compiler's examples and tests that 0.1.0 accepted is still accepted.

## Try it

You need a stable Rust toolchain installed through [rustup](https://rustup.rs).

```text
cargo install varyk
varyk init hello
cd hello
varyk run
```

The [getting started](/learn/getting-started/) page goes from there, and the [language reference](/learn/reference/) describes everything the compiler accepts.

## What is next

Milestone 5 is the batteries for services: HTTP, JSON, databases, configuration, logging, `varyk test`, and `async`/`await` on a built-in runtime, with one golden path as the bar, a users API on a database that is `varyk init`, one file, and `varyk run` away. `varyk fmt` and the interop items once planned for milestone 4 moved to milestones 5 and 6. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Try writing one small service and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
