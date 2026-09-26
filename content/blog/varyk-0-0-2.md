+++
title = "Varyk 0.0.2: enums, matching, methods, and collections"
description = "Milestone 2 makes Varyk able to express a real small program: enums and match, for, methods, Option, Result, Vec, ?, and format!, with the borrow-by-default rules unchanged."
date = 2026-09-26
+++

Varyk 0.0.2 is on crates.io. It is milestone 2 of the [roadmap](/design/roadmap/): the language core a small program needs. Milestone 1 proved borrow-by-default on six programs; this release adds enums and `match`, `for`, methods, `Option`, `Result`, `Vec`, `?`, `format!`, and a deliberate string copy, and it keeps every milestone-1 rule. Calls never write `&`, mutation is declared with `mut`, and the compiler adds no allocation except a string literal stored into a value you own and the copy you ask for with `.clone()`.

## What is in it

```varyk
enum Shape {
    Circle(f64),
    Rect(f64, f64),
    Point,
}

fn area(shape: Shape) -> f64 {
    match shape {
        Shape::Circle(radius) => 3.14 * radius * radius,
        Shape::Rect(w, h) => w * h,
        Shape::Point => 0.0,
    }
}

fn main() {
    let shapes = vec![Shape::Circle(1.0), Shape::Rect(2.0, 3.0), Shape::Point];
    for shape in shapes {
        println!("{}", area(shape));
    }
}
```

It prints `3.14`, `6`, and `0`. Every new construct follows the same idea as the old ones: you write what the program does, and the compiler decides how the value is passed.

- **Enums** with unit and tuple variants, and `match` on enums, `Option`, and `Result` with one-level patterns. Varyk checks the arms itself, so a `match` that forgets a variant is a plain-word error before cargo runs.
- **`for`** over integer ranges and over a `Vec`.
- **`impl` blocks** with `self` and `mut self` methods and associated functions. A method that reads `self` borrows it; one that writes `mut self` borrows it mutably, and the caller sees the change.
- **`Option`, `Result`, and `Vec`** in types, written as in Rust, with `Some`, `None`, `Ok`, `Err`, `Vec::new()`, `vec!`, `push`, `pop`, `len`, and indexing. `None`, `Vec::new()`, `Ok`, and `Err` take their type from where they go, the way an integer literal does.
- **`?`** on a `Result` whose error type is the function's own.
- **`format!`** for building strings. `+` on strings is rejected with a fix-it that says to use it, so every allocation is visible at the call.
- **`usize`** for lengths and indexes, matching rustc's types.
- **`s.clone()`** on a string: the one explicit copy, Rust's own spelling, with the cost visible where it happens. It answers an open question from milestone 1.

Matching and iterating borrow, like everything else. A `match` on a place never moves it; a name bound by a pattern, or the loop variable of a `for` over a `Vec`, is an *alias* of part of the value, and changing or giving away the whole while an alias is still in use is an error. Milestone 1 had this rule implicitly and one bug around it; milestone 2 states it and applies it everywhere.

The six milestone-2 programs are in the compiler's [examples](https://github.com/Varyk-Lang/varyk/tree/main/examples), including a small `todo` program with a `Task` struct, a `Status` enum, methods, and `format!`, spread over two files. The [language reference](/learn/reference/) describes everything the compiler accepts, and the section "Not in milestone 2" lists what it rejects and why: enum variants with named fields, nested and literal patterns, methods on `Option` and `Result`, closures, iterators, `if let`, `HashMap`, and returning part of a borrowed value, which stays a `.clone()` until milestone 4.

## Try it

You need a stable Rust toolchain installed through [rustup](https://rustup.rs).

```text
cargo install varyk
varyk run enums.vr
```

The [getting started](/learn/getting-started/) page goes from there.

## The roadmap, renumbered

The old milestone 2 covered four independent areas. This release takes the language core only, and the rest moved down the list: packages, Cargo dependencies, `use`, nested modules, field-level `pub`, Rust struct import, and publishing are now [milestone 3](/design/roadmap/); closures, iterators, `if let`, `HashMap`, and `varyk fmt` are milestone 4; the batteries for services, HTTP, JSON, logging, and `async`, are milestone 5. Nothing there is a date.

Varyk is experimental and pre-1.0: until 1.0, a breaking change bumps the minor version. Milestone 3 has one, private struct fields, so the release after it is 0.1.0.

If you think the bet is wrong, or right, the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place to say so.
