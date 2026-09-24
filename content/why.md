+++
title = "Why Varyk?"
description = "Rust's guarantees are worth having. Its surface area is what keeps people out. Varyk keeps the guarantees and moves the surface into the compiler."
weight = 5
+++

Rust is the best answer we have to a hard question: how to get native speed and memory safety without a garbage collector. Its guarantees are real, and Varyk changes none of them. What Varyk changes is the amount of Rust you have to hold in your head to use them.

## The cost of Rust

Writing a Rust service means making a set of decisions on almost every line, and writing each one down:

- **At every call site**, whether to pass `x`, `&x`, or `&mut x`, which depends on the callee's signature and on whether you still need `x` afterwards. Get it wrong and the error arrives several lines later, phrased in terms of borrows you did not write.
- **For every string**, which of `String`, `&str`, `&String`, `Box<str>`, or `Cow<str>` this one is, when to call `.to_string()`, `.to_owned()`, `.as_str()`, `.clone()`, and what each costs.
- **In signatures**, lifetime annotations whenever elision does not cover the case, and the meaning of `'a` when it appears in an error.
- **When a value moves**, whether you meant that, whether the type is `Copy`, and whether to `clone` instead. Cloning to make the compiler stop is the habit every Rust beginner picks up and every reviewer flags.
- **In async code**, `Send`, `Sync`, `Pin`, and `'static` bounds on anything you spawn, with errors that name types you never wrote.
- **Around every abstraction**, generics with trait bounds, `dyn Trait` behind a `Box`, `Rc` or `Arc`, `RefCell` or `Mutex`, and the borrow checker's view of each combination.

Every one of these is a real decision with a real cost, and Rust makes you write it down. That discipline is what makes Rust programs fast and safe. It is also why the first weeks are hard, why the code stays dense long after, and why teams that would benefit from Rust choose Go instead: Go has the simplicity, but pays for it with a garbage collector and a runtime.

The same list is where AI coding agents fail. A model that has read a great deal of Rust still misplaces `&`, mixes up `String` and `&str`, invents lifetimes, and cannot see a `Send` bound coming. The syntax Rust makes you write is exactly the syntax that is hardest to get right from pattern-matching alone.

## The bet

Most of that surface is the *spelling* of decisions the compiler can make. Varyk keeps Rust's ownership model inside the compiler and takes the spelling out of the language:

- **Functions borrow by default.** A parameter written `user: User` is a shared borrow. One written `mut user: User` is a mutable borrow, and the caller sees the change. Call sites never write `&` or `&mut`; the signature carries the contract, and mutation of the caller's value is visible where the function is declared. *Milestone 1.*
- **One string type.** `string` is the only one. The compiler decides the representation for each value, and the rules allow exactly one kind of allocation: a literal placed into an owned slot, converted at that line and visible in `--emit-rust`. Nothing is copied behind your back. *Milestone 1.*
- **Lifetimes are inferred** wherever the compiler can infer them. Milestone 1 rejects the cases it cannot infer, with a diagnostic that says why; borrowed returns arrive with lifetime inference in *milestone 2*.
- **Moves keep Rust's rules**, and the diagnostics for moved values are a first-class feature: the message shows where the move happened. Whether an explicit transfer syntax is needed at all is an open question, and Varyk does not add one until it is answered.
- **`Send`, `Sync`, and `Pin` stay out of the surface language.** They are still enforced by rustc, and their failures are mapped to Varyk diagnostics that talk about your code, not the bounds. Async keeps JavaScript's surface: `async fn`, `.await`, and a built-in runtime. *Milestone 3.*
- **Generics without declaring generics.** `Option`, `Result`, `Vec`, and `?` come in *milestone 2*, used without declaring type parameters. Declaring your own generics, traits, and attributes is unscheduled: each waits on an open question, because principle 9 says advanced features must justify their complexity, and these have not yet.
- **Diagnostics with codes and fix-its**, and machine-readable output. When you write `&user`, `user: &User`, `String`, or a lifetime, the compiler says exactly what to change. That closes the loop for a person learning and for an agent iterating.

## What you keep

Everything Rust is good at. The generated program is Rust, checked by rustc with the full borrow check; Varyk never uses `unsafe` to get around it. There is no garbage collector and no runtime that Rust does not already have. Passing a value to a Varyk function never allocates.

The ecosystem, without a bridge. A Varyk package is a Cargo package. `.rs` files sit next to `.vr` files in the same package and build with the same `cargo`; every Cargo crate is available; and from milestone 2 Varyk libraries publish to crates.io with their generated `.rs` included, so consumers need only cargo. This is the TypeScript relationship: adopt gradually, drop to the underlying language when you need it, and ship packages other people use without knowing what they were written in.

The escape hatch is Rust itself. Anything Varyk cannot express goes in a `.rs` file, not in new syntax.

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
