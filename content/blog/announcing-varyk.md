+++
title = "Announcing Varyk 0.0.1"
description = "The first release of Varyk, a language for backend services that compiles to Rust: a compiler that proves the approach on six small programs and generates readable Rust."
date = 2026-09-25
+++

Varyk is an experimental language for APIs, workers, and microservices that compiles to Rust. Rust is what a service should run on: memory safety without a garbage collector, native speed, and an ecosystem that already has everything a service needs. It is also a lot to hold in your head when all you want is to handle a request. Varyk keeps what makes Rust strong and removes the ceremony from application code, and the Rust compiler checks everything it generates. Today the first release, 0.0.1, is on crates.io, and the [compiler repository](https://github.com/Varyk-Lang/varyk) is public.

The story of how I got here, through JavaScript, Python, TypeScript, Go, and Swift, is in [Why I built Varyk](/blog/why-i-built-varyk/).

## What is in it

This release is milestone 1: a small compiler that proves the approach. You write simple Varyk, and it becomes readable Rust that rustc checks like any other Rust code.

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

It prints `Alice`, then `Bob`. `varyk build --emit-rust` shows the generated Rust.

The milestone-1 surface is deliberately small: functions, structs, `if`/`else`, `while`, one string type, `println!`, modules that resolve to `.vr` or `.rs` files, and calls into plain Rust functions. The [language reference](/learn/reference/) describes everything the compiler accepts, and the [examples](/learn/examples/) are the six programs it must build and run. Every error has a code, a plain-word message, and, where it can, a fix-it; `--message-format=json` prints them as JSON for tools and agents.

## Try it

You need a stable Rust toolchain installed through [rustup](https://rustup.rs).

```text
cargo install varyk
varyk run hello.vr
```

The [getting started](/learn/getting-started/) page goes from there.

## What is next

Varyk is experimental and pre-1.0: syntax, diagnostic codes, and command-line flags may change, and a breaking change bumps the minor version. The next milestones add enums, `match`, `for`, methods, `Option`, `Result`, and `?`, and then packages with `Cargo.toml` and Cargo dependencies. The batteries a service needs, HTTP, JSON, databases, and `async`, come in milestone 5. The [roadmap](/design/roadmap/) has the full list, and the [design page](/design/) explains why the language is shaped this way.

If you think the bet is wrong, or right, the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place to say so.
