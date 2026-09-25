+++
title = "Varyk"
description = "An experimental systems programming language with Rust-like safety and Go-like simplicity. It compiles to Rust."
sort_by = "weight"

# The hero and the figure are rendered by templates/index.html.
[extra]
eyebrow = "An experimental systems programming language"
headline = ["Rust’s safety.", "Go’s *simplicity.*"]
lead = "Varyk keeps what makes Rust strong, memory safety without a garbage collector, native speed, and the Rust ecosystem, and removes the complexity that stands between people and those benefits. It compiles to Rust, the way TypeScript compiles to JavaScript."
install_label = "Install with Cargo"
install = "cargo install varyk"
figure_caption = "The Rust that `varyk build --emit-rust` generates from `borrowing.vr`. **Marked**: everything the compiler writes for you. The program prints `Alice`, then `Bob`."

[[extra.actions]]
name = "Get started"
path = "/learn/getting-started/"

[[extra.actions]]
name = "Why Varyk?"
path = "/why/"

# One entry per `##` section below, in order. The template numbers them and wraps each in a band.
# `style` picks the layout in site.css; `columns` splits a section into one column per `###`;
# `done` is the number of completed milestones in the roadmap.
[[extra.bands]]
id = "mission"
label = "Mission"
style = "mission"

[[extra.bands]]
id = "what-changes"
label = "What changes"
style = "changes"

[[extra.bands]]
id = "who"
label = "Who it’s for"
style = "who"
columns = true

[[extra.bands]]
id = "what-you-get"
label = "What you get"
style = "get"

[[extra.bands]]
id = "roadmap"
label = "Roadmap"
style = "road"
done = 1

[[extra.bands]]
id = "get-started"
label = "Get started"
style = "start"
+++

## Varyk exists to make Rust available to *everyone.*

Rust is one of the safest and fastest languages there are, and one of the hardest to learn. Its guarantees belong in every program, but its complexity keeps most people out, whether they come from another language, are writing their first program, or are an AI agent writing code. The Rust compiler checks everything Varyk generates, so the guarantees are Rust's own.

1. **`.vr`** Varyk source, with `.rs` files beside it in the same build.
2. **`varyk build`** Parses, type-checks, and runs borrow analysis. Diagnostics carry codes and fix-its.
3. **`target/varyk/`** A Cargo project of readable Rust. It is yours, so there is no lock-in.
4. **`cargo`** rustc and the full borrow checker. Varyk never uses `unsafe` to get around it.
5. **A native binary** No garbage collector, no reference counting, no runtime beyond Rust's.

## Same ownership model. Less spelling.

Most of Rust's surface is the *spelling* of decisions the compiler can make on its own. Varyk keeps Rust's ownership model inside the compiler and takes the spelling out of the language. The [borrowing example](/learn/examples/#borrowing) shows a whole program beside the Rust it becomes.

| Rule | In Rust you write | In Varyk you write |
|---|---|---|
| **Functions borrow by default.** The signature carries the contract. | `fn rename(user: &mut User)` | `fn rename(mut user: User)` |
| **Call sites never write `&`.** No choosing between `x`, `&x`, and `&mut x`. | `rename(&mut user);` | `rename(user);` |
| **One string type.** The compiler decides the representation. | `name: "Alice".to_string()` | `name: "Alice"` |

## Wherever you’re coming from.

### Coming from JavaScript, TypeScript, Go, or Python

- Native speed and memory safety without a garbage collector.
- Simple code: the compiler does the memory bookkeeping that Rust asks you to write by hand.
- `async`/`await` that looks like JavaScript, with a built-in runtime (milestone 3).
- One toolchain and one package registry, inherited from Cargo and crates.io (milestone 2).
- Adopt gradually, drop to Rust when needed, and publish packages that other people use without knowing the source language (milestone 2).

### Coming from Rust

- Rust syntax and idioms: immutability by default, `let mut`, `struct`, and from milestone 2 `impl`, `match`, `Option`, `Result`, and `?`.
- The same safety model: the generated Rust is checked by rustc, and Varyk never bypasses it.
- Less ceremony for application code.
- `.rs` files next to `.vr` files in the same package, built by the same `cargo`.
- Varyk packages are Cargo packages and publish to crates.io as ordinary crates (milestone 2).

### For AI coding agents

- Rust syntax, so what a model learned from Rust transfers, minus the parts models most often get wrong: which `&` to write at a call site, `&mut` versus `&`, lifetime annotations, `String` versus `&str`.
- No `unsafe` in the surface language, so every generated program is checked by rustc.
- Structured, machine-readable diagnostics with codes and fix-its.
- Diagnostics that recognize Rust habits and say exactly what to change.
- A language reference short enough to fit in a prompt, and one way to do each thing.

## Rust underneath. Nothing in the way.

- **Rust's guarantees, unchanged.** A Varyk program becomes a Rust program and is checked by rustc, with the full borrow checker.
- **Go's simplicity.** You write what the program does, and the compiler does the memory bookkeeping that Rust makes you spell out.
- **The whole Rust ecosystem.** `.rs` files build alongside Varyk today, and every crate on crates.io, with no bindings, from milestone 2.
- **Zero overhead.** No garbage collector, no reference counting, no runtime beyond what Rust already has. Nothing is cloned behind your back.
- **No lock-in.** The generated Rust is readable, and it is yours: `--emit-rust` shows all of it.
- **Built for code written by machines.** Diagnostics carry codes and fix-its and come in machine-readable form, so a generate-compile-fix loop has something precise to act on.

[Read why Varyk exists](/why/).

## Ordered milestones, no dates.

1. **Milestone 1, complete.** Compiler skeleton and the borrow-by-default proof: six example programs, diagnostics with codes and fix-its, and `varyk check`, `build`, and `run`.
2. **Milestone 2, next.** Packages, nested modules, enums, and control flow: Cargo dependencies, `match`, `impl`, `?`, publishing to crates.io, and `varyk fmt`.
3. **Milestone 3.** Batteries for services: JSON via serde, logging via tracing, an HTTP server, and `async`/`await` on a built-in tokio runtime.
4. **Milestone 4.** Tooling and beyond: a language server, and a decision on a native backend.

The [roadmap](/design/roadmap/) has every item; nothing there is a date or a release commitment.

## Install. Write. Run.

Varyk requires a stable Rust toolchain installed through [rustup](https://rustup.rs). Install the compiler with `cargo install varyk`, save this as `hello.vr`, and run it:

```varyk
fn main() {
    println!("Hello, world!");
}
```

```text
$ varyk run hello.vr
Hello, world!
```

Continue with [getting started](/learn/getting-started/) and the [language reference](/learn/reference/). Source and issues are at [github.com/Varyk-Lang/varyk](https://github.com/Varyk-Lang/varyk).
