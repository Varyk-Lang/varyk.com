+++
title = "Varyk 0.1.0: packages and interop"
description = "Milestone 3 makes Varyk code a Cargo package: Cargo dependencies, nested modules, use, private fields, Rust structs and enums imported from .rs files, and publishing to crates.io."
date = 2026-09-27
+++

<!-- TODO(release): set the date to the 0.1.0 release day, and check every claim below against docs/roadmap.md in the compiler repository: the manifest, dependencies, the source map, `varyk init`, and publishing were still open when this was drafted. In the same change, mark milestone 3 complete across the site: `done = 3` and the roadmap band on the home page, the roadmap page, the why and tools pages, every "milestone 3" label on the home and why pages, and refresh content/learn/reference.md from the 0.1.0 tag. -->

Varyk 0.1.0 is on crates.io. It is milestone 3 of the [roadmap](/design/roadmap/): milestones 1 and 2 made a single `.vr` file, with the modules it declares, into a running program. Milestone 3 makes Varyk code a Cargo package, with a `Cargo.toml`, dependencies from crates.io, modules at any depth, `use`, private fields, Rust structs and enums imported from `.rs` modules, plain `cargo build` through a `build.rs`, and publishing to crates.io as a crate whose consumers need only cargo.

The minor version moved because one rule changed. Until 1.0, a breaking change bumps the minor version, and this release has one, described below.

## What is in it

**A Varyk package is a Cargo package.** Its crate root is `src/main.vr` for a binary or `src/lib.vr` for a library, `Cargo.toml` is the only manifest, and `varyk check`, `build`, and `run` with no file argument find the package from the current directory. `varyk init` writes the package and a `build.rs`, so plain `cargo build` and `cargo run` work too, and CI for the compiler asserts that both give the same output. Single-file mode, `varyk run hello.vr`, is unchanged.

**Modules at any depth.** A module may declare modules; children live in a directory named after their parent, as `shop.vr` and `shop/mod.vr` alike, and paths with `crate::`, `self::`, or `super::` resolve everywhere a path can appear. Visibility is Rust's: a module or item without `pub` is visible in its declaring module and that module's descendants, and a `pub` item may not name a type its users cannot see.

**`use`.** `use crate::shop::cart::Cart;` and `use shop::cart as c;` alias modules, structs, enums, and functions inside the package. A `use` cannot start with the name of a crate, `std` included, which brings us to dependencies.

**Cargo dependencies.** `cargo add` works unchanged. In 0.1.0 a crate is called from a Rust file in the same package, which exposes the plain functions and types your Varyk uses, imported the way Rust functions have been since milestone 1. The docs call that file a *facade*. Most crate APIs are generic, and Varyk has no generics in its surface, so the facade is where the concrete API gets written, and a facade can itself be published as a crate. Whether Varyk code should ever `use` a crate directly, with no facade, is an experiment for after traits exist; it is recorded as an open question in the specification and as unscheduled on the roadmap.

**Rust structs, methods, and enums import.** A non-generic `pub struct` with named fields in a `.rs` module becomes a Varyk struct, its inherent `pub fn`s become methods, and `&self` and `&mut self` map to `self` and `mut self`. A field whose Rust type Varyk cannot map is present but unusable, with an error that names the type. Enums import the same way.

**Errors from rustc point at your Varyk.** The backend records the Varyk span behind every generated line, so an error the Rust layer reports lands on the Varyk line that produced it. Warnings are allowed per generated item, so your own `.rs` files warn normally.

**Publishing.** A Varyk library publishes to crates.io with its generated `.rs` included, and a consumer that only has cargo builds it without ever knowing the source language.

The three milestone-3 example packages are in the compiler's [examples](https://github.com/Varyk-Lang/varyk/tree/main/examples/packages): `greeting`, a binary built by `varyk run` and by `cargo run`; `matcher`, a facade over a registry crate with a struct, methods, and an enum imported into Varyk; and `units`, a published library with a cargo-only consumer.

<!-- TODO(release): paste the matcher example here, copied byte for byte from examples/packages/matcher, once it exists. -->

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

Milestone 4 is closures, iterators, `if let`, `HashMap`, borrowed return values, and `varyk fmt`. Milestone 5 is the batteries for services: HTTP, JSON, databases, configuration, logging, tests, and `async`/`await` on a built-in runtime. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Try building one small package and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
