+++
title = "Varyk 0.1.0: packages and interop"
description = "Milestone 3 makes Varyk code a Cargo package: Cargo dependencies through .rs facades, nested modules, use, private fields, Rust structs and enums imported from .rs files, and publishing to crates.io."
date = 2026-09-27T14:00:00+02:00
+++

Varyk 0.1.0 is on crates.io. It is milestone 3 of the [roadmap](/design/roadmap/). Milestones 1 and 2 made a single `.vr` file, with the modules it declares, into a running program. Milestone 3 makes Varyk code a Cargo package, with a `Cargo.toml`, crates from crates.io called through a `.rs` facade, modules at any depth, `use`, private fields, Rust structs and enums imported from `.rs` modules, plain `cargo build` through a `build.rs`, and publishing to crates.io as a crate whose consumers need only cargo.

The minor version moved because one rule changed. Until 1.0, a breaking change bumps the minor version, and this release has one, described below.

## What is in it

**A Varyk package is a Cargo package.** Its crate root is `src/main.vr` for a binary or `src/lib.vr` for a library, `Cargo.toml` is the only manifest, and it must say `edition = "2024"` (V0400 otherwise). `varyk check`, `build`, and `run` with no file argument find the package from the current directory. `varyk init` writes the package and a `build.rs`, so plain `cargo build` and `cargo run` work too, with `varyk` on the `PATH` (or `$VARYK` naming it), and CI for the compiler asserts that both give the same output. `build.rs` calls the new `varyk emit`, which writes the generated Rust tree to a directory without running cargo. Single-file mode, `varyk run hello.vr`, is unchanged.

**Modules at any depth.** A module may declare modules; children live in a directory named after their parent, as `shop.vr` and `shop/mod.vr` alike, and paths with `crate::`, `self::`, or `super::` resolve everywhere a path can appear. Visibility is Rust's: a module or item without `pub` is visible in its declaring module and that module's descendants, and a `pub` item may not name a type its users cannot see.

**`use`.** `use crate::shop::cart::Cart;` and `use shop::cart as c;` alias modules, structs, enums, and functions inside the package. A `use` cannot start with the name of a crate, `std` included, which brings us to dependencies.

**Cargo dependencies.** `cargo add` works unchanged. A crate is called from a Rust file in the same package, which exposes the plain functions and types your Varyk uses, imported the way Rust functions have been since milestone 1. The docs call that file a *facade*. Most crate APIs are generic, and Varyk has no generics in its surface, so the facade is where the concrete API gets written, and a package with its facade publishes as a plain crate. Whether Varyk code should ever `use` a crate directly, with no facade, is an experiment for after traits exist; it is recorded as an open question in the specification and as unscheduled on the roadmap.

**Rust structs, methods, and enums import.** A non-generic `pub struct` with named fields in a `.rs` module becomes a Varyk struct, its inherent `pub fn`s become methods, and `&self` and `&mut self` map to `self` and `mut self`. A field whose Rust type Varyk cannot map is present but unusable, with an error that names the type. Enums with unit and tuple variants import too (their methods not yet), and Varyk checks that a `match` on one covers every variant.

**Errors from rustc point at the right file.** An error or warning rustc reports in one of your own `.rs` files is shown at your file and line, unchanged, as rustc worded it. The Rust Varyk generates should never be rejected; if it is, the backend's line-level source map reports it as V0900 at the Varyk line that produced it, carrying rustc's message and asking you to report it as a bug. Warnings are allowed per generated item, so your own `.rs` files warn normally, and `--message-format=json` carries those warnings too; under `varyk run`, whose standard output is the program's own, the JSON goes to standard error.

**Publishing.** `varyk publish` runs the full check, assembles a plain Rust crate with the generated `.rs` files, the `.vr` sources beside them, and no `build.rs`, and runs `cargo publish` there, passing on anything after `--`. Binaries and libraries both publish. A consumer that only has cargo adds a published Varyk library like any crate, and `cargo install` of a published Varyk binary works like any other. `varyk publish --assemble-only` stops after the assembly and publishes nothing.

**New diagnostic codes.** V0110 is a `use` naming a crate; call it from a `.rs` module instead. V0111 is a path Varyk cannot follow, such as `super` in the entry file or a `use` ending at an enum variant. V0400 to V0403 are about `Cargo.toml`: an edition other than 2024, a workspace setting or platform-only dependencies, a `path` in a target table, and a manifest that cannot be used. V0900 is the generated-Rust error above. The [language reference](/learn/reference/#error-codes) has the full table.

The three milestone-3 example packages are in the compiler's [examples](https://github.com/Varyk-Lang/varyk/tree/main/examples/packages): `greeting`, a binary built by `varyk run` and by `cargo run`; `matcher`, a facade over a registry crate with a struct, methods, and an enum imported into Varyk; and `units`, a library assembled by `varyk publish --assemble-only` and used by a cargo-only consumer.

This is `matcher`. `Cargo.toml` names the crate:

```toml
[package]
name = "matcher"
version = "0.1.0"
edition = "2024"

[dependencies]
regex-lite = "0.1"
```

`src/text.rs` is the facade:

```rust
// A facade: Varyk code never names a crate, so this file wraps
// `regex_lite` in a struct, methods, and an enum Varyk can import.

pub struct Matcher {
    re: regex_lite::Regex,
}

impl Matcher {
    pub fn new(pattern: &str) -> Matcher {
        let re = regex_lite::Regex::new(pattern).expect("the pattern should be a valid regex");
        Matcher { re }
    }

    pub fn is_match(&self, s: &str) -> bool {
        self.re.is_match(s)
    }

    pub fn count(&self, s: &str) -> usize {
        self.re.find_iter(s).count()
    }
}

pub enum Kind {
    Word,
    Number(i32),
}

pub fn classify(s: &str) -> Kind {
    // Deliberately unused: rustc's warning about it shows through
    // `varyk build` at this file and line, as Rust warnings do.
    let trimmed = s.trim();
    match s.parse::<i32>() {
        Ok(n) => Kind::Number(n),
        Err(_) => Kind::Word,
    }
}
```

And `src/main.vr` uses it like any Varyk module:

```varyk
// expected output:
// apple: word, 0 digit runs
// 42: the number 42, 1 digit runs
// route 66 or 101: word, 2 digit runs
// 2 of 3 contain digits

mod text;

fn describe(kind: text::Kind) -> string {
    match kind {
        text::Kind::Word => "word",
        text::Kind::Number(n) => format!("the number {}", n),
    }
}

fn main() {
    let digits = text::Matcher::new("[0-9]+");
    let mut inputs: Vec<string> = Vec::new();
    inputs.push("apple");
    inputs.push("42");
    inputs.push("route 66 or 101");

    let mut with_digits: usize = 0;
    for s in inputs {
        if digits.is_match(s) {
            with_digits = with_digits + 1;
        }
        println!("{}: {}, {} digit runs", s, describe(text::classify(s)), digits.count(s));
    }
    println!("{} of {} contain digits", with_digits, inputs.len());
}
```

`varyk run` in the package prints rustc's warning that `trimmed` is unused, at `src/text.rs` line 31, which the example keeps on purpose to show a warning in your own Rust, and then the four lines of output.

## The breaking change: fields are private unless `pub`

In milestone 2 every field of a `pub struct` was public. From 0.1.0 a field follows the same rule as everything else: private unless `pub`, visible in the struct's own module and its descendants, which includes the struct's own methods.

```varyk
pub struct User {
    pub name: string,
    age: i32,
}
```

Reading, assigning, or naming a private field from another module is an error with a note offering both ways out, `pub` on the field or a `pub fn`, because making every field public is often the wrong fix. The milestone-2 examples needed no source changes when the rule landed, because none of their fields crossed a module boundary; if yours do, add `pub` to the fields other modules read.

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

Milestone 4 is closures, iterators, `if let`, `HashMap`, borrowed return values, and `varyk fmt`, and more interop: nested modules in `.rs` files, Rust tuple and unit structs, derives on imported Rust structs usable from Varyk, `.rs` signatures naming Varyk types, and importing a published Varyk library straight into Varyk code. Milestone 5 is the batteries for services: HTTP, JSON, databases, configuration, logging, tests, and `async`/`await` on a built-in runtime. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Try building one small package and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
