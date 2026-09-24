+++
title = "Why Varyk?"
description = "Rust's speed and safety, Go's simplicity, and the whole Rust ecosystem on day one, with no runtime and no lock-in."
weight = 5
+++

Varyk is for teams that want what Rust delivers, native speed and memory safety without a garbage collector, but cannot afford what Rust costs to learn, to hire for, or to have written by a machine. It keeps every guarantee Rust makes, and it keeps the Rust ecosystem. What it removes is the part of Rust you have to hold in your head.

## What you get

**Rust's guarantees, unchanged.** A Varyk program becomes a Rust program and is checked by rustc, with the full borrow checker. Memory safety and freedom from data races are not approximated or re-implemented; they are Rust's, because the code is Rust. Varyk never uses `unsafe` to get around the checker.

**Go's simplicity.** One string type. No `&` at call sites. No lifetime annotations. No `Send`, `Sync`, or `Pin` in your code. One way to do each thing, and a language reference short enough to fit in a prompt. A developer arriving from Go, TypeScript, or Python writes a service on the first day, not the first month.

**The whole Rust ecosystem, on day one.** Every crate on crates.io, with no bindings, no FFI, and no ecosystem to bootstrap. A Varyk package is a Cargo package: `cargo add` works unchanged, `.rs` files sit next to `.vr` files in the same package, and the two build together. Every other simpler-than-Rust language starts its library ecosystem from zero. Varyk starts with Rust's.

**Zero overhead.** No garbage collector, no reference counting, no runtime beyond what Rust already has. Passing a value to a Varyk function never allocates. The compiler inserts exactly one kind of allocation, a string literal placed into an owned slot, and `--emit-rust` shows you where. Nothing is cloned behind your back.

**No lock-in.** The generated Rust is readable, and it is yours. Published Varyk libraries ship with their `.rs` files, so consumers need only cargo and never know the source language. If Varyk stops being the right choice, you keep the Rust.

**Built for code that is written by machines.** AI agents are first-class writers of Varyk. The syntax Varyk removes, `&` at call sites, `&mut` versus `&`, lifetimes, `String` versus `&str`, is exactly where models that have read a great deal of Rust still fail. Diagnostics carry codes and fix-its and come in machine-readable form, so a generate-compile-fix loop has something precise to act on. Rust knowledge transfers; Rust's failure modes do not.

**Gradual adoption, in both directions.** Add a `.vr` file to an existing Rust project, or start in Varyk and drop to a `.rs` file for the parts that need Rust's full expressiveness. Rust experts and newcomers work in one codebase, one build, one registry.

## The cost of Rust

Rust earns its guarantees by making you write down a decision on almost every line:

- **At every call site**, whether to pass `x`, `&x`, or `&mut x`, depending on the callee and on whether you still need `x` afterwards.
- **For every string**, which of `String`, `&str`, `&String`, `Box<str>`, or `Cow<str>` this one is, and when to `.to_string()`, `.as_str()`, or `.clone()`.
- **In signatures**, lifetime annotations whenever elision does not cover the case.
- **When a value moves**, whether you meant that, whether the type is `Copy`, and whether to clone instead. Cloning to make the compiler stop is the habit every Rust beginner picks up and every reviewer flags.
- **In async code**, `Send`, `Sync`, `Pin`, and `'static` bounds on anything you spawn, with errors that name types you never wrote.
- **Around every abstraction**, generics with trait bounds, `dyn Trait` behind a `Box`, `Rc` or `Arc`, `RefCell` or `Mutex`, and the borrow checker's view of each combination.

That discipline is what makes Rust programs fast and safe. It is also why the first weeks are hard, why the code stays dense long after, why hiring for Rust is hard, and why teams that would benefit from Rust choose Go and accept the garbage collector.

## How Varyk removes it

Most of that surface is the *spelling* of decisions the compiler can make on its own. Varyk keeps Rust's ownership model inside the compiler and takes the spelling out of the language:

- **Functions borrow by default.** `user: User` is a shared borrow; `mut user: User` is a mutable borrow, and the caller sees the change. The signature carries the contract, so mutation of the caller's value is visible where the function is declared, and call sites never write `&`. *Milestone 1.*
- **One string type.** The compiler decides the representation for each value, with one visible allocation rule. *Milestone 1.*
- **Lifetimes are inferred** wherever the compiler can infer them; borrowed returns arrive with lifetime inference in *milestone 2*.
- **Moves keep Rust's rules**, and the diagnostic for a moved value shows where the move happened. Whether an explicit transfer syntax is needed at all is an open question, and Varyk does not add one until it is answered.
- **`Send`, `Sync`, and `Pin` stay out of the surface.** Enforced by rustc, reported as Varyk diagnostics about your code rather than the bounds. Async keeps JavaScript's surface: `async fn`, `.await`, a built-in runtime. *Milestone 3.*
- **Generics without declaring generics.** `Option`, `Result`, `Vec`, and `?`, used without type parameters. *Milestone 2.* Declaring your own generics, traits, and attributes is unscheduled: each waits on an open question, because advanced features must justify their complexity, and these have not yet.
- **Diagnostics that recognize Rust habits.** Write `&user`, `user: &User`, `String`, or a lifetime, and the compiler says exactly what to change.

## Compared with others

Declaring a parameter's passing convention in the signature and inferring the rest is not a new idea. The closest relatives, and the one-line difference from each:

- **Rust with lints.** A lint cannot remove `&` from a call site, because the sigils are semantics, not style. Varyk moves that decision into the compiler.
- **Go.** Has the simplicity and the same target space, services, but pays for it with a garbage collector and a runtime. Varyk has neither.
- **TypeScript.** The model for the ecosystem relationship, not the grammar: TypeScript is a superset of JavaScript and compiles to it; Varyk compiles to Rust but is not a superset of it.
- **Mojo** has `read`, `mut`, and `owned` argument conventions with the same shape as Varyk's parameter modes, on its own compiler and runtime with Python syntax. Varyk targets the Rust ecosystem and Rust syntax.
- **Hylo** (formerly Val) is built on mutable value semantics with `let`, `inout`, and `sink` conventions and no first-class references in the surface language. It is the closest philosophical relative, with its own compiler. Varyk keeps Rust's references underneath and only hides their spelling.
- **Swift** has `inout`, `borrowing`, and `consuming` modifiers, on top of reference counting. Varyk has no reference counting.
- **Vale** removes borrow-checker friction with generational references, a different runtime model. Varyk changes nothing about the runtime model.
- **Rune** has Rust-like syntax with dynamic typing and reference counting. Varyk is statically typed and compiles to native code.

## What it is not

- **Not a superset of Rust.** Varyk does not accept arbitrary Rust in `.vr` files, and one Rust keyword changes meaning: `mut` on a parameter means "mutable borrow", not "owned and rebindable".
- **Not a new runtime.** No garbage collector, no reference counting, nothing between your program and the Rust it becomes.
- **Not for every Rust niche.** Varyk targets services first, the space Go occupies, and standalone binaries second. Embedded and `no_std` are out of scope.

## Where it stands

Varyk is pre-0.1. Milestone 1 proves the borrow-by-default idea with [six programs](/learn/examples/) and the [language surface](/learn/reference/) needed to run them; the [roadmap](/design/roadmap/) lists what comes after, without dates. The [design page](/design/) has the principles in priority order, and the open questions, including ownership transfer and the async runtime shape, are recorded in the [specification](https://github.com/Varyk-Lang/varyk/blob/main/docs/specs/2026-09-23-varyk-design.md). If you think the bet is wrong, the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place to say so.
