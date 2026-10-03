+++
title = "Design"
description = "The principles behind Varyk, in priority order, with its non-goals and stability policy."
sort_by = "weight"
weight = 40
+++

Varyk is a programming language for backend services with Rust-like safety and Go-like simplicity. It compiles to Rust and runs on the Rust ecosystem, in the same way TypeScript compiles to JavaScript and runs on the JavaScript ecosystem. The analogy is about the ecosystem relationship, not the grammar: Varyk is not a superset of Rust. Rust code lives in `.rs` files next to Varyk code, and the two build together.

Varyk targets services first, the space Go occupies, and standalone binaries second. This page summarizes the compiler repository's [design notes](https://github.com/Varyk-Lang/varyk/blob/main/docs/design.md); the [open questions](https://github.com/Varyk-Lang/varyk/blob/main/docs/open-questions.md) and the full [design specification](https://github.com/Varyk-Lang/varyk/blob/main/docs/specs/2026-09-23-varyk-design.md) are there too.

## Principles

In priority order. When two conflict, the earlier one wins.

1. **Rust's safety model, unchanged.** No garbage collector, no implicit `Clone`, no implicit deep copy. The compiler inserts exactly two kinds of allocation: a string literal placed into an owned slot is converted at that line, and a string passed as a trailing value of a facade (milestone 5b3) is copied into the value it is handed over in; `--emit-rust` shows both. The generated Rust is checked by rustc, and Varyk never works around rustc with unsafe code.
2. **The service developer first, human or agent.** Every tie-breaker on the surface language goes toward the developer building services who has never written Rust. AI agents are first-class writers of Varyk; where their needs and human readability diverge, human readability wins.
3. **Rust syntax with sigils inferred.** Functions borrow their arguments by default. Mutation is declared in the function contract with `mut`. References are never written at call sites. Lifetimes are inferred wherever the compiler can infer them.
4. **One way to do each thing.** A small, regular grammar with one obvious spelling per idea is the most useful property a language can have for both a newcomer and a code generator.
5. **Predictable cost.** Passing a value to a Varyk-declared function never allocates. Storing a string literal into an owned slot allocates once, at the line where the literal is written. Moves follow Rust's rules, and the diagnostics for moved values are a first-class feature.
6. **Gradual adoption.** A Varyk package can contain Rust files and depend on Cargo crates. Escape hatches live in Rust files, not in new Varyk syntax.
7. **Reuse Cargo, build only the compiler.** The manifest, dependency resolution, registry, lockfile, features, workspaces, caching, cross-compilation, code generation, optimization, and the full borrow check all come from Cargo and rustc. Varyk owns the front end, the Rust emitter, and diagnostics.
8. **Generated Rust is the first backend, not necessarily the last.** The front end never depends on the backend.
9. **Advanced features must justify their complexity.** Go-like simplicity is the bar for anything added to the surface language.

## Packages and batteries

`varyk-std` stays the small runtime every program has: what the language itself needs and the light things nearly every service uses, `Error`, tasks, `json`, `env`, and `log`. Anything heavy is a package the writer adds: SQL, MongoDB, Redis, the HTTP server and client. A program that prints a line never compiles a web server or a database driver. Official packages are named `varyk-*` and community packages `*-varyk`, with neither `std` nor the crate underneath in the name. The mechanism came first, in milestone 5b2: with packages in place, a battery is written once as a package, by this project or by anyone, and needs no work in the compiler. Milestone 5b3 lets a `.rs` facade take a type parameter filled from where the result goes, any number of plain values after the other arguments, and a parameter that takes only text written in the program, so a package such as `varyk-sql` is Varyk with a thin layer of Rust, and its users write no Rust.

Varyk code is built by `varyk`, as Go code is built by `go`. A package is `Cargo.toml`, its `.vr` files, and its `.rs` facades, with no `build.rs` and no stub, and `varyk` compiles every Varyk package a build uses from its `.vr` sources, never from Rust a publisher shipped, so what runs is what a reader can review. Cargo still reads the package, for `cargo add`, `cargo update`, `cargo tree`, `cargo audit`, and dependency bots, and cargo refuses a manifest with no target, so the manifest names the `.vr` root as its target. Plain `cargo build` does not build a source package, but it builds a published Varyk crate, which carries its generated Rust, so a Rust project can depend on one as on any crate.

## Non-goals

- Varyk is not a superset of Rust and does not aim to accept arbitrary Rust syntax in `.vr` files.
- No garbage collector, ever.
- No separate package registry, package manifest, or build system. Cargo and crates.io are the only ones.
- No inline Rust blocks inside `.vr` files. Rust goes in `.rs` files.
- No commitment to a native backend. The option is kept open; the roadmap does not promise it.
- Not every Rust niche. Embedded and `no_std` targets are out of scope.
- Not for kernels, database engines, or borrow-heavy libraries. Write those in Rust, in a `.rs` file beside your Varyk, in the same build; Varyk is for the application on top.

## Stability

Before 1.0, everything may change; a new feature or a breaking change bumps the minor version. Diagnostic codes are stable in one sense from the start: a code, once assigned, is never reused for a different meaning, though it may be retired. Command-line flags and the generated Rust layout have no stability guarantee before 1.0.

## Concurrency direction

Varyk keeps Rust's async model and JavaScript's surface: `async fn` and `.await` on a built-in runtime. There is no `spawn`: a call to an async function without `.await` starts it at once as a task, as calling an async function does in JavaScript, and a task that is dropped is cancelled. `Send`, `Sync`, and `Pin` are kept out of the surface syntax; they are still enforced by rustc, and their failures are mapped to Varyk diagnostics. Milestone 5b1 settled the runtime as multi-threaded, because the HTTP and database crates need `Send` either way, and ownership transfer as needing no syntax: the arguments of a started call are the one place a value is handed over. Varyk does not adopt Go-style colorless concurrency: the Rust crates it builds on are already async.
