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

`Cargo.toml` as the package manifest, Cargo dependencies and `use`, nested modules and `mod.vr` directories, field-level `pub`, import of Rust structs, methods, and enums from `.rs` modules, Rust-layer errors mapped to Varyk source through a source map with per-file handling of rustc warnings, `varyk init` with a `build.rs` so plain `cargo build` works, publishing a Varyk library to crates.io with the generated `.rs` included, and this site's pitch, install page, and language reference. The release after it is 0.1.0, because private fields are a breaking change.

## Milestone 4: closures, iterators, and tooling

Closures and function types, iterator adapters on `Vec` and `string`, borrowed return values inferred from the body, `if let` and `while let`, enum variants with named fields and nested and literal patterns, the `Option` and `Result` methods and the rest of the `Vec` and `string` methods, `HashMap`, `Box`, `as`, `clone` on structs and enums, and `varyk fmt`.

## Milestone 5: batteries for services

`varyk-std`: JSON via serde, logging via tracing, an HTTP server on a proven Rust crate chosen at that time and an HTTP client on the same stack, databases through one API with sqlx as the candidate crate, configuration from the environment, `varyk test`, and `async`/`await` on a built-in tokio runtime with `spawn` as a built-in and `Send`, `Sync`, and `Pin` kept out of the surface syntax. Gated on open questions: how Varyk structs derive serde's traits, the async runtime shape, and ownership-transfer syntax.

## Milestone 6: tooling and beyond

A language server on top of `varyk-syntax`, and a decision on a native backend.

## Unscheduled

Declaring generics, traits, and attributes in Varyk code, and using a crate directly from Varyk code without a Rust module in between. Each waits on an open question in the specification.
