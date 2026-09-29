+++
title = "Why Varyk?"
description = "Rust's speed and safety, Go's simplicity, and the Rust ecosystem behind it, with no runtime and no lock-in."
weight = 5
+++

Varyk is a small language for backend services: APIs, workers, and microservices. You write Go-like application code and ship a native binary with Rust's safety and speed, no garbage collector, and the Rust ecosystem behind it. Varyk exists so that ordinary backend services can be written simply and shipped as safe Rust, for teams that want what Rust delivers but cannot afford what Rust costs to learn or to hire for. It keeps every guarantee Rust makes, and it keeps the Rust ecosystem. What it removes is the part of Rust you have to hold in your head.

## Why I built it

I came to Varyk through the languages I built services in before it. JavaScript, then Python, then TypeScript: productive languages, but working with data without real types was harder than it needed to be, and TypeScript's types are only as strong as the JavaScript underneath them. I also needed performance those languages could not give me. So I went looking for a language that was fast and had a type system I could lean on.

Go is simple, and I like that. But it has a garbage collector, with the runtime and memory overhead that come with it, and a syntax I never took to. Swift is a good language whose server ecosystem is too small for the microservices I build. Rust has the ideology I believe in: ownership instead of a garbage collector, safety enforced by the compiler, native performance, and an ecosystem that already has everything a service needs. I love it. Day to day, though, it is difficult to work with, and much of the difficulty comes from quirks that have nothing to do with the service being written.

What I wanted did not exist: Rust's ecosystem, guarantees, and performance, with application code as simple as Go. Varyk is that language.

— Vlad Mickevic

## What you get

**Rust's guarantees, unchanged.** A Varyk program becomes a Rust program and is checked by rustc, with the full borrow checker. Memory safety and freedom from data races are not approximated or re-implemented; they are Rust's, because the code is Rust. Varyk never uses `unsafe` to get around the checker.

**Go's simplicity.** You write what the program does, and the compiler does the memory bookkeeping that Rust makes you spell out. One way to do each thing, and a language reference short enough to fit in a prompt. A developer arriving from Go, TypeScript, or Python reads and writes Varyk on the first day, not the first month.

**The whole Rust ecosystem, with nothing to bootstrap.** `.rs` files sit next to `.vr` files and the two build together, and since milestone 3 a Varyk package is a Cargo package. You add a crate with `cargo add` and call it from a `.rs` file in the package, a facade that wraps what your program needs in plain functions, structs, and enums, which Varyk imports like its own. There is nothing to generate and no second toolchain, because your program is Rust by the time the crate sees it. The goal is that Varyk uses a crate as easily as Rust does; the facade gets most of the way there, and the last step, using a crate straight from Varyk code, is an unscheduled experiment. Every other simpler-than-Rust language starts its library ecosystem from zero. Varyk starts with Rust's.

**Zero overhead.** No garbage collector, no reference counting, no runtime beyond what Rust already has. Passing a value to a Varyk function never allocates. The compiler inserts exactly one kind of allocation, a string literal stored into a value you own, and `--emit-rust` shows you where. Nothing is cloned behind your back.

**No lock-in.** The generated Rust is readable, and it is yours: `--emit-rust` shows all of it. `varyk publish` ships a Varyk package as a plain Rust crate, with the generated `.rs` files and the `.vr` sources beside them, so consumers need only cargo. If Varyk stops being the right choice, you keep the Rust.

**Built for teams that write code with agents.** Coding agents already write good code; the slow part is reviewing it, and Varyk is designed to keep reviews short. The language is small, with one way to do each thing, so agent output looks like the code around it. Code is concrete, with few abstractions to see through. rustc checks memory safety and data races in everything the agent writes, so a review can focus on what the service does. The language reference fits in a prompt, and diagnostics come as JSON with codes and fix-its, so the agent fixes its own mistakes before a person looks. From milestone 5, one built-in stack for HTTP, JSON, and databases means every Varyk service is written the same way, and what an agent or a reviewer learned in one applies in the next.

**Gradual adoption, in both directions.** Start in Varyk and drop to a `.rs` file for the parts that need Rust's full expressiveness, or add Varyk to an existing Rust project: run `varyk init` in an empty directory, move its `build.rs` and `src/main.vr` into your project, move the code of your `src/main.rs` into a `.rs` module, and replace `src/main.rs` with the stub `init` wrote. The project needs `edition = "2024"`, and a Rust project with nested modules cannot adopt Varyk yet, because a `.rs` module cannot declare modules of its own. Rust experts and newcomers work in one codebase, one build, one registry.

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
- **Lifetimes are inferred.** A function that returns part of a parameter writes nothing for it: the compiler works out which parameter from the body, and the generated Rust names a lifetime only where elision would not. *Milestone 4.*
- **Moves keep Rust's rules**, and the diagnostic for a moved value shows where the move happened. Whether an explicit transfer syntax is needed at all is an open question, and Varyk does not add one until it is answered.
- **`Send`, `Sync`, and `Pin` stay out of the surface.** Enforced by rustc, reported as Varyk diagnostics about your code rather than the bounds. Async keeps JavaScript's surface: `async fn`, `.await`, a built-in runtime. *Milestone 5.*
- **Generics without declaring generics.** `Option`, `Result`, `Vec`, and `?`, written as in Rust, with no generics of your own to declare. *Milestone 2.* Declaring your own generics, traits, and attributes is unscheduled: each waits on an open question, because advanced features must justify their complexity, and these have not yet.
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
- **Not for kernels, database engines, custom allocators, or borrow-heavy libraries.** Write those in Rust, in a `.rs` file beside your Varyk, in the same build. Varyk is for the application on top.

## Where it stands

Varyk is experimental and pre-1.0: until 1.0, a breaking change bumps the minor version. Milestones 1 to 4 are complete and prove the approach on the [example programs](/learn/examples/) with the [language surface](/learn/reference/) they need; the [roadmap](/design/roadmap/) lists what comes after, without dates. The [design page](/design/) has the principles in priority order, and the open questions, including ownership transfer and the async runtime shape, are recorded in the [specification](https://github.com/Varyk-Lang/varyk/blob/main/docs/specs/2026-09-23-varyk-design.md). If you think the bet is wrong, the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place to say so.
