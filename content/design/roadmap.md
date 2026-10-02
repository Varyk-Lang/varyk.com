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

## Milestone 4: closures, iterators, and patterns

**Complete, released as 0.2.0.** The language only; the former milestone-4 tooling and interop items moved to milestones 5 and 6. Closures as the arguments of built-in calls, with untyped parameters and shared captures, never a value of their own; iterator chains on stored values, from `iter`, `split`, `keys`, and `values` through `map` and `filter` to `collect`, `count`, `sum`, `any`, `all`, and `find`, or as the head of a `for`; borrowed return values inferred from the body, with a lifetime in the generated Rust only where elision would not name it; `if let` and `while let`; enum variants with named fields, nested, literal, and `..=` range patterns, `match` on numbers, `bool`, and strings, with exhaustiveness and reachability checked by Varyk; `?` on `Option`; the `Option` and `Result` methods and new `Vec` and `string` calls, `parse` included; `HashMap`; `as` between number types; `Clone` and `PartialEq` derived where every field allows, so `.clone()` and `==` work on structs and enums; import of Rust signatures returning `&str` or `&S` where lifetime elision names the parameter; a test asserting the language reference mentions every keyword, built-in type, table call, and diagnostic code; and six new example programs.

## Milestone 5: batteries for services

Milestone 5 is three milestones. The bar for the whole of it is one golden path: a users API on a database is `varyk init`, one file, and `varyk run` away, within fifteen minutes of `cargo install varyk`, and `varyk build --release` leaves an ordinary native executable. It is met at the end of 5b2, and promotion waits for it.

### Milestone 5a: data, configuration, logging, and tests

**Complete, released as 0.3.0.** The `varyk-std` crate, and the `varyk-std` dependency in every package, whose version and lock `varyk check` reads; `Error`, one built-in error type with a message, and `parse` returning a `Result`; the attributes `#[rename]`, `#[default]`, `#[skip]`, and `#[test]`; serde derivation for the types a `json` or `env` call reaches; JSON through `json::parse` and `json::stringify`; configuration from the environment and `.env` through `env::parse`; logging via tracing, with `log::debug`, `info`, `warn`, and `error`; `varyk test`, with `assert` and `assert_eq`; `varyk add`, a pass-through to `cargo add`; and the examples `json`, `config`, and `logging` and the `users` package. Its release is 0.3.0, because `parse` returning a `Result` is a breaking change.

### Milestone 5b1: async

**Complete, released as 0.4.0.** `async fn` and `.await` on a built-in multi-threaded tokio runtime, with `Send`, `Sync`, and `Pin` kept out of the surface syntax; started calls, where a call to an async function without `.await` starts it at once and gives a `Task<T>`; tasks cancelled when dropped, `detach` to let one run on its own, `Task::all` and `Task::all_settled` to wait on many; `Shared<T>` for a read-only struct held by many tasks; `time::sleep`; `pub async fn` imported from `.rs` modules; and the examples `tasks`, `fanout`, and `shared`. Both questions it was gated on are answered: the runtime is multi-threaded, and ownership transfer needs no syntax, because the arguments of a started call are the one place a value is handed over. Its release is 0.4.0, because `Task`, `Shared`, and `time` become reserved names.

### Milestone 5b2: HTTP and the database

An HTTP server on a proven Rust crate, chosen at that time, with application state shared by every handler as a `Shared<T>`, and an HTTP client on the same stack; databases through one API, with sqlx as the candidate crate; `.rs` signatures naming Varyk-declared types and `varyk_std::Error`, so the `varyk-std` facades can take and return Varyk structs; and an agent evaluation, the examples written by a model from the language reference alone with pass rates published, before any page claims that agents write Varyk well.

## Milestone 6: tooling and beyond

`varyk fmt`, a deterministic formatter on `varyk-syntax`; a language server on `varyk-syntax`; nested modules in `.rs` files; import of Rust tuple and unit structs; `Debug` on imported Rust structs, with a `{:?}` placeholder; direct import of a published Varyk library from Varyk; and a decision on a native backend.

## Unscheduled

Declaring generics, traits, and attributes of your own in Varyk code, and using a crate directly from Varyk code, with no facade `.rs` module in between. Each waits on an open question in the specification; the four attributes milestone 5a added are the compiler's own, and only the compiler defines attributes. Using a crate directly is an experiment for after traits exist, because most crate APIs are generic; the facade rule stands until that experiment says otherwise. TOML is unscheduled too, beside the rest of the cuts the [language reference](/learn/reference/#not-in-milestone-5b1) lists under "Not in milestone 5b1": nothing on the golden path needs it, and the same machinery adds it later. Also unscheduled: `Box`, until a program needs a recursive type that `Vec` or `HashMap` cannot hold, and the rest of the milestone-4 cut list, a character type, closures as values, tuples, `HashSet`, and the remaining iterator adapters.
