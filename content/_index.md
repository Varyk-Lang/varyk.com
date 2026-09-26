+++
title = "Varyk"
description = "An experimental programming language for backend services, with Rust-like safety and Go-like simplicity. It compiles to Rust."
sort_by = "weight"

# The hero and its figure are rendered by templates/index.html.
[extra]
eyebrow = "A language for backend services, compiled to Rust"
headline = ["Simple services.", "Rust’s safety and *speed.*"]
lead = "Varyk is a small language for APIs, workers, and command-line tools. You write Go-like application code. The compiler turns it into readable Rust, rustc checks it, and you ship a native binary with no garbage collector and the Rust ecosystem behind it."
install_label = "Install with Cargo"
install = "cargo install varyk"
# The hero figure (templates/partials/home-service.html) shows a service as Varyk is designed to write it.
figure_caption = "A service as Varyk is designed to write it. Coming in milestone 5: the compiler does not accept `http`, `db`, or `async` yet. See the [roadmap](/design/roadmap/)."
# The borrowing figure (templates/partials/home-figure.html) is placed in the band whose entry sets `figure = "borrowing"`.
borrowing_caption = "The Rust that `varyk build --emit-rust` generates from `borrowing.vr`. **Marked**: everything the compiler writes for you. The program prints `Alice`, then `Bob`."

[[extra.actions]]
name = "Get started"
path = "/learn/getting-started/"

[[extra.actions]]
name = "Why Varyk?"
path = "/why/"

# One entry per `##` section below, in order. The template numbers them and wraps each in a band.
# `style` picks the layout in site.css; `columns` splits a section into one column per `###`;
# `figure = "borrowing"` places the borrowing figure after the band's first paragraph;
# `done` is the number of completed milestones in the roadmap.
[[extra.bands]]
id = "mission"
label = "Mission"
style = "mission"

[[extra.bands]]
id = "what-you-get"
label = "What you get"
style = "get"

[[extra.bands]]
id = "what-changes"
label = "What changes"
style = "changes"
figure = "borrowing"

[[extra.bands]]
id = "who"
label = "Who it’s for"
style = "who"
columns = true

[[extra.bands]]
id = "roadmap"
label = "Roadmap"
style = "road"
done = 2

[[extra.bands]]
id = "get-started"
label = "Get started"
style = "start"
+++

## Varyk exists to make Rust available to *everyone.*

Rust is one of the safest and fastest languages there are, and one of the hardest to learn. Its guarantees belong in every program, but its complexity keeps most people out, whether they come from another language or are writing their first program. The Rust compiler checks everything Varyk generates, so the guarantees are Rust's own.

1. **`.vr`** Varyk source, with `.rs` files beside it in the same build.
2. **`varyk build`** Parses, type-checks, and runs borrow analysis. Diagnostics carry codes and fix-its.
3. **`target/varyk/`** A Cargo project of readable Rust. It is yours, so there is no lock-in.
4. **`cargo`** rustc and the full borrow checker. Varyk never uses `unsafe` to get around it.
5. **A native binary** No garbage collector, no reference counting, no runtime beyond Rust's.

## What a service needs. What Rust *guarantees.*

The batteries are what every service uses and what a Go or TypeScript team expects to find built in. They ship in milestone 5; the guarantees ship today.

- **HTTP server and client.** Routes, handlers, and calls to other services on one built-in stack. Coming in milestone 5.
- **Rust's guarantees, unchanged.** A Varyk program becomes a Rust program and is checked by rustc, with the full borrow checker.
- **JSON from your structs.** Every struct serializes and parses, with nothing extra to write. Coming in milestone 5.
- **No garbage collector, no runtime.** No reference counting, nothing beyond what Rust already has. Nothing is cloned behind your back.
- **Databases through one API.** Query a database and get your structs back, on a proven Rust driver. Coming in milestone 5.
- **Readable Rust, yours to keep.** The generated Rust is a normal Cargo project, `--emit-rust` shows all of it, and there is no lock-in.
- **Async built in.** `async fn` and `.await` on a runtime you never configure. Coming in milestone 5.
- **The whole Rust ecosystem.** Rust files build alongside Varyk today, and from milestone 3 you add any crate from crates.io with `cargo add`, the same way a Rust project does.
- **Configuration, logging, tests.** Settings from the environment, structured logs, and `varyk test`. Coming in milestone 5.
- **Built for code written by machines.** Diagnostics carry codes and fix-its and come in machine-readable form, so a generate-compile-fix loop has something precise to act on.

Varyk is for the application. Kernels, database engines, and borrow-heavy libraries stay in Rust, in a `.rs` file beside your Varyk, in the same build. [Read why Varyk exists](/why/).

## Same ownership model. Less *spelling.*

Most of Rust's surface is the *spelling* of decisions the compiler can make on its own. Varyk keeps Rust's ownership model inside the compiler and takes the spelling out of the language. This program runs today; everything marked is what the compiler wrote for you.

| Rule | In Rust you write | In Varyk you write |
|---|---|---|
| **Functions borrow by default.** The signature carries the contract. | `fn rename(user: &mut User)` | `fn rename(mut user: User)` |
| **Call sites never write `&`.** No choosing between `x`, `&x`, and `&mut x`. | `rename(&mut user);` | `rename(user);` |
| **One string type.** The compiler decides the representation. | `name: "Alice".to_string()` | `name: "Alice"` |

## Wherever you’re coming from.

### Building services in Go, TypeScript, or Python

- Native speed and memory safety without a garbage collector.
- Application code as simple as Go: the compiler does the memory bookkeeping that Rust asks you to write by hand.
- `async`/`await` that looks like JavaScript, with a built-in runtime (milestone 5).
- One toolchain and one package registry, inherited from Cargo and crates.io (milestone 3).
- One binary to deploy: no runtime to install and no base image to pick.

### Coming from Rust

- Rust syntax and idioms: immutability by default, `let mut`, `struct`, `impl`, `match`, `Option`, `Result`, and `?`.
- The same safety model: the generated Rust is checked by rustc, and Varyk never bypasses it.
- Less ceremony for application code.
- `.rs` files next to `.vr` files in the same package, built by the same `cargo`.
- Varyk packages are Cargo packages and publish to crates.io as ordinary crates (milestone 3).

### For AI coding agents

- Rust syntax, so what a model learned from Rust transfers, minus the parts models most often get wrong: which `&` to write at a call site, `&mut` versus `&`, lifetime annotations, `String` versus `&str`.
- No `unsafe` in the surface language, so every generated program is checked by rustc.
- Structured, machine-readable diagnostics with codes and fix-its.
- Diagnostics that recognize Rust habits and say exactly what to change.
- A language reference short enough to fit in a prompt, and one way to do each thing.

## Ordered milestones, no *dates.*

1. **Milestone 1, complete.** Compiler skeleton and the borrow-by-default proof: six example programs, diagnostics with codes and fix-its, and `varyk check`, `build`, and `run`.
2. **Milestone 2, complete.** Enums, `match`, `for`, methods, `Option`, `Result`, `Vec`, `?`, and `format!`.
3. **Milestone 3, next.** Packages and interop: `Cargo.toml`, Cargo dependencies, nested modules, `use`, Rust structs and enums imported from `.rs` files, and publishing to crates.io.
4. **Milestone 4.** Closures, iterators, `HashMap`, borrowed return values, and `varyk fmt`.
5. **Milestone 5.** Batteries for services: HTTP, JSON, databases, logging, tests, and `async`/`await` on a built-in runtime.
6. **Milestone 6.** Tooling and beyond: a language server, and a decision on a native backend.

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
