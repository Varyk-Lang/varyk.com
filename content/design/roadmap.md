+++
title = "Roadmap"
description = "The milestones for the Varyk compiler, without dates."
weight = 1
+++

Milestones are ordered; items within a milestone are not. Nothing here is a release commitment or a date. The [live roadmap](https://github.com/Varyk-Lang/varyk/blob/main/docs/roadmap.md) in the compiler repository tracks progress item by item.

## Milestone 1: compiler skeleton and the borrow-by-default proof

**Complete.** A minimum viable compiler that validates the central idea with six small programs: the [examples](/learn/examples/). Lexer and parser, resolver, type checker and borrow analysis, the `println!` intrinsic, `mod` resolving to `.vr` or `.rs` files, import of top-level `pub fn` signatures from Rust modules, a Rust backend writing a Cargo project under `target/varyk/`, diagnostics with codes and fix-its, `--message-format=json`, and the `varyk check`, `build`, and `run` commands.

## Milestone 2: packages, nested modules, enums, and control flow

`Cargo.toml` as the package manifest, Cargo dependencies and `use`, nested modules and `mod.vr` directories, field-level `pub`, enums, `match`, `for`, `impl` blocks, using generic standard types (`Option`, `Result`, `Vec`) without declaring generics, `?`, closures, lifetime inference for borrowed returns, an explicit string copy spelling, Rust struct import, Rust-layer errors mapped to Varyk source through a source map, per-file handling of rustc warnings, `varyk init` with a `build.rs` so plain `cargo build` works, publishing to crates.io with generated `.rs` included, and `varyk fmt`.

## Milestone 3: batteries for services

`varyk-std`: JSON via serde, logging via tracing, an HTTP server on a proven Rust crate chosen at that time, and `async`/`await` on a built-in tokio runtime. Milestone 3 is gated on three open questions: how Varyk structs derive serde's traits, the async runtime shape, and ownership-transfer syntax.

## Milestone 4: tooling and beyond

A language server on top of `varyk-syntax`, and a decision on a native backend.

## Unscheduled

Declaring generics, traits, and attributes in Varyk code. Each waits on an open question in the specification.
