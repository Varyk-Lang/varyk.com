+++
title = "Roadmap"
description = "The milestones for the Varyk compiler, without dates."
weight = 1
+++

Milestones are ordered; items within a milestone are not. Nothing here is a release commitment or a date. The [live roadmap](https://github.com/Varyk-Lang/varyk/blob/main/docs/roadmap.md) in the compiler repository tracks progress item by item.

## Milestone 1: compiler skeleton and the borrow-by-default proof

**Complete, released as 0.0.1.** A minimum viable compiler that validates the central idea with six small programs: the [examples](/learn/examples/). Lexer and parser, resolver, type checker and borrow analysis, the `println!` intrinsic, `mod` resolving to `.vr` or `.rs` files, import of top-level `pub fn` signatures from Rust modules, a Rust backend writing a Cargo project under `target/varyk/`, diagnostics with codes and fix-its, `--message-format=json`, and the `varyk check`, `build`, and `run` commands.

## Milestone 2: enums, matching, methods, and collections

**Complete, released as 0.0.2.** The language core a small program needs: enums with unit and tuple variants, `match` on enums, `Option`, and `Result`, with a forgotten variant caught by Varyk before cargo runs, `for` over ranges and `Vec`, `impl` blocks with `self` and `mut self` methods, `Option`, `Result`, and `Vec` with a small table of methods and indexing, `usize`, `?`, `format!` and `vec!`, `s.clone()` as the one explicit string copy, and the rule that a name taken from part of a value cannot outlive a change to the whole. Six more example programs.

## Milestone 3: packages and interop

**Complete, released as 0.1.0.** Varyk code never names a crate; a dependency is used from a `.rs` facade in the same package. `Cargo.toml` as the package manifest, with `src/main.vr` or `src/lib.vr` as the root, edition 2024, and `[package.metadata.varyk]` reserved; Cargo dependencies reached from `.rs` facades, with `Cargo.lock` shared with cargo; nested modules and `mod.vr` directories, `pub mod`, and `use` for paths inside the package; field-level `pub`; import of Rust structs, their inherent methods, and enums from `.rs` modules; errors rustc finds in the generated Rust mapped to Varyk source as V0900, the user's own `.rs` errors and warnings shown at their file, and item-level lint allows on generated code; `varyk init` with a `build.rs` so plain `cargo build` works, and `varyk emit`; `varyk publish`, which publishes binaries and libraries as plain Rust crates with the generated `.rs` and the `.vr` sources included; and three example packages. This site's pitch, install page, and language reference are part of it. Its release is 0.1.0, because private fields are a breaking change.

## Milestone 4: closures, iterators, and tooling

Closures and function types, iterator adapters on `Vec` and `string`, borrowed return values inferred from the body, `if let` and `while let`, enum variants with named fields and nested and literal patterns, the `Option` and `Result` methods and the rest of the `Vec` and `string` methods, `HashMap`, `Box`, `as`, `clone` on structs and enums, `varyk fmt`, and a test asserting the language reference covers every construct the parser accepts. On the interop side: nested modules in `.rs` files, import of Rust tuple and unit structs, derives on imported Rust structs (`Clone`, `PartialEq`, `Debug`) usable from Varyk, `.rs` signatures naming Varyk-declared types, and direct import of a published Varyk library from Varyk.

## Milestone 5: batteries for services

`varyk-std`: JSON via serde, logging via tracing, an HTTP server on a proven Rust crate chosen at that time and an HTTP client on the same stack, databases through one API with sqlx as the candidate crate, configuration from the environment, `varyk test`, and `async`/`await` on a built-in tokio runtime with `spawn` as a built-in and `Send`, `Sync`, and `Pin` kept out of the surface syntax. Gated on open questions: how Varyk structs derive serde's traits, the async runtime shape, and ownership-transfer syntax.

## Milestone 6: tooling and beyond

A language server on top of `varyk-syntax`, and a decision on a native backend.

## Unscheduled

Declaring generics, traits, and attributes in Varyk code, and using a crate directly from Varyk code, with no facade `.rs` module in between. Each waits on an open question in the specification. Using a crate directly is an experiment for after traits exist, because most crate APIs are generic; the facade rule stands until that experiment says otherwise.
