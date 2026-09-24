+++
title = "Design"
description = "The principles behind Varyk, in priority order, with its non-goals and stability policy."
sort_by = "weight"
weight = 40
+++

Varyk is a systems programming language with Rust-like safety and Go-like simplicity. It compiles to Rust and runs on the Rust ecosystem, in the same way TypeScript compiles to JavaScript and runs on the JavaScript ecosystem. The analogy is about the ecosystem relationship, not the grammar: Varyk is not a superset of Rust. Rust code lives in `.rs` files next to Varyk code, and the two build together.

Varyk targets services first, the space Go occupies, and standalone binaries second. The full [design specification](https://github.com/Varyk-Lang/varyk/blob/main/docs/specs/2026-09-23-varyk-design.md) is in the compiler repository; this page summarizes it.

## Principles

In priority order. When two conflict, the earlier one wins.

1. **Rust's safety model, unchanged.** No garbage collector, no implicit `Clone`, no implicit deep copy. The compiler inserts exactly one kind of allocation: a string literal placed into an owned slot is converted at that line, and `--emit-rust` shows it. The generated Rust is checked by rustc, and Varyk never works around rustc with unsafe code.
2. **Newcomer first, human or agent.** Every tie-breaker on the surface language goes toward the developer who has never written Rust. AI agents are first-class writers of Varyk; where their needs and human readability diverge, human readability wins.
3. **Rust syntax with sigils inferred.** Functions borrow their arguments by default. Mutation is declared in the function contract with `mut`. References are never written at call sites. Lifetimes are inferred wherever the compiler can infer them.
4. **One way to do each thing.** A small, regular grammar with one obvious spelling per idea is the most useful property a language can have for both a newcomer and a code generator.
5. **Predictable cost.** Passing a value to a Varyk-declared function never allocates. Storing a string literal into an owned slot allocates once, at the line where the literal is written. Moves follow Rust's rules, and the diagnostics for moved values are a first-class feature.
6. **Gradual adoption.** A Varyk package can contain Rust files and depend on Cargo crates. Escape hatches live in Rust files, not in new Varyk syntax.
7. **Reuse Cargo, build only the compiler.** The manifest, dependency resolution, registry, lockfile, features, workspaces, caching, cross-compilation, code generation, optimization, and the full borrow check all come from Cargo and rustc. Varyk owns the front end, the Rust emitter, and diagnostics.
8. **Generated Rust is the first backend, not necessarily the last.** The front end never depends on the backend.
9. **Advanced features must justify their complexity.** Go-like simplicity is the bar for anything added to the surface language.

## Non-goals

- Varyk is not a superset of Rust and does not aim to accept arbitrary Rust syntax in `.vr` files.
- No garbage collector, ever.
- No separate package registry, package manifest, or build system. Cargo and crates.io are the only ones.
- No inline Rust blocks inside `.vr` files. Rust goes in `.rs` files.
- No commitment to a native backend. The option is kept open; the roadmap does not promise it.
- Not every Rust niche. Embedded and `no_std` targets are out of scope.

## Stability

Before 0.1, everything may change. Diagnostic codes are stable in one sense from the start: a code, once assigned, is never reused for a different meaning, though it may be retired. Command-line flags and the generated Rust layout have no stability guarantee before 0.1.

## Concurrency direction

Varyk keeps Rust's async model and JavaScript's surface: `async fn` and `.await`, a built-in runtime, and `spawn` as a built-in. `Send`, `Sync`, and `Pin` are kept out of the surface syntax; they are still enforced by rustc, and their failures must be mapped to Varyk diagnostics. Whether the runtime is multi-threaded or current-thread is an open question to be decided before milestone 3. Varyk does not adopt Go-style colorless concurrency: the Rust crates it builds on are already async.
