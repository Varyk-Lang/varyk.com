+++
title = "Varyk"
description = "An experimental systems programming language with Rust-like safety and Go-like simplicity. It compiles to Rust."
sort_by = "weight"
+++

<p class="tagline">A systems programming language with Rust-like safety and Go-like simplicity. It compiles to Rust and runs on the Rust ecosystem.</p>

<div class="notice" role="note">

**Experimental.** Varyk is pre-0.1: syntax, diagnostic codes, and command-line flags may change until a 0.1 release, which is not scheduled.

</div>

## The mission

Varyk exists to make Rust available to everyone.

Rust is one of the safest and fastest languages there are, and one of the hardest to learn. Its guarantees belong in every program, but its complexity keeps most people out. Varyk keeps what makes Rust strong: memory safety without a garbage collector, native speed, and the Rust ecosystem. It removes the complexity that stands between people and those benefits, whether they come from another language, are writing their first program, or are an AI agent writing code.

Varyk compiles to Rust, the way TypeScript compiles to JavaScript. The Rust compiler checks everything Varyk generates, so the guarantees are Rust's own.

## What it looks like

<div class="panes">
<div>

### borrowing.vr

```varyk
struct User {
    name: string,
}

fn rename(mut user: User) {
    user.name = "Bob";
}

fn print_user(user: User) {
    println!("{}", user.name);
}

fn main() {
    let mut user = User {
        name: "Alice",
    };

    print_user(user);
    rename(user);
    print_user(user);
}
```

</div>
<div>

### generated Rust

```rust
#![allow(dead_code, unused_variables, unused_mut)]

struct User {
    name: String,
}

fn rename(user: &mut User) {
    user.name = "Bob".to_string();
}

fn print_user(user: &User) {
    println!("{}", user.name);
}

fn main() {
    let mut user = User {
        name: "Alice".to_string(),
    };
    print_user(&user);
    rename(&mut user);
    print_user(&user);
}
```

</div>
</div>

<p class="note">This is the Rust that <code>varyk build --emit-rust</code> generates for it. The program prints <code>Alice</code>, then <code>Bob</code>.</p>

## Why?

Rust's speed and safety, without a garbage collector. Go's simplicity, without a runtime. And the whole Rust ecosystem, with nothing to bootstrap: `.rs` files build alongside Varyk today, and every crate on crates.io, with no bindings, from milestone 2. The generated Rust is readable and yours, so there is no lock-in, and the syntax Varyk removes is exactly where AI models writing Rust fail. [Read why](/why/).

## Who it's for

<div class="cols">
<div>

### Coming from JavaScript, TypeScript, Go, or Python

- Native speed and memory safety without a garbage collector.
- Simple code: the compiler does the memory bookkeeping that Rust asks you to write by hand.
- `async`/`await` that looks like JavaScript, with a built-in runtime (milestone 3).
- One toolchain and one package registry, inherited from Cargo and crates.io (milestone 2).
- Adopt gradually, drop to Rust when needed, and publish packages that other people use without knowing the source language (milestone 2).

</div>
<div>

### Coming from Rust

- Rust syntax and idioms: immutability by default, `let mut`, `struct`, and from milestone 2 `impl`, `match`, `Option`, `Result`, and `?`.
- The same safety model: the generated Rust is checked by rustc, and Varyk never bypasses it.
- Less ceremony for application code.
- `.rs` files next to `.vr` files in the same package, built by the same `cargo`.
- Varyk packages are Cargo packages and publish to crates.io as ordinary crates (milestone 2).

</div>
<div>

### For AI coding agents

- Rust syntax, so what a model learned from Rust transfers, minus the parts models most often get wrong: which `&` to write at a call site, `&mut` versus `&`, lifetime annotations, `String` versus `&str`.
- No `unsafe` in the surface language, so every generated program is checked by rustc.
- Structured, machine-readable diagnostics with codes and fix-its.
- Diagnostics that recognize Rust habits and say exactly what to change.
- A language reference short enough to fit in a prompt, and one way to do each thing.

</div>
</div>

## Get involved

- Source and issues: [github.com/Varyk-Lang/varyk](https://github.com/Varyk-Lang/varyk). Discussion happens in the issues.
- Contact: [hello@varyk.com](mailto:hello@varyk.com). Security reports: [security@varyk.com](mailto:security@varyk.com), see the [security page](/security/).
- More on the [community page](/community/).
