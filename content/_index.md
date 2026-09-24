+++
title = "Varyk"
description = "An experimental systems programming language with Rust-like safety and Go-like simplicity. It compiles to Rust."
sort_by = "weight"
+++

<p class="tagline">A systems programming language with Rust-like safety and Go-like simplicity. It compiles to Rust and runs on the Rust ecosystem.</p>

<!-- TODO(release): confirm this notice against the first release (version, what changed). -->
<div class="notice" role="note">

**Experimental.** Varyk is pre-0.1: syntax, diagnostic codes, and command-line flags may change until a 0.1 release, which is not scheduled.

</div>

## The central idea

Rust-shaped source in which ordinary function calls do not require you to write borrowing. Functions borrow their parameters by default, so there is no `&` at the call site. A function that changes a parameter says so with `mut` in its signature.

Ownership, borrowing, and lifetimes still exist inside the compiler and in the safety guarantees. They rarely appear in everyday code.

## Borrowing without `&`

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
    let mut user = User { name: "Alice".to_string() };
    print_user(&user);
    rename(&mut user);
    print_user(&user);
}
```

</div>
</div>

<!-- TODO(release): once the compiler emits this Rust, change "is designed to compile to" to "compiles to". -->
<p class="note">The Varyk program is designed to compile to the Rust shown with it. It prints <code>Alice</code>, then <code>Bob</code>.</p>

## Why Varyk

<div class="cols">
<div>

### Coming from JavaScript, TypeScript, Go, or Python

- Native speed and memory safety without a garbage collector.
- One string type, no reference sigils, no lifetime annotations.
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
