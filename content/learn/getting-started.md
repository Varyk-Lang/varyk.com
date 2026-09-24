+++
title = "Getting started"
description = "Write, check, build, and run a first Varyk program."
weight = 1
+++

Varyk source files use the `.vr` extension and the compiler binary is `varyk`. [Install](/install/) it first.

## Hello, world

Save this as `hello.vr`:

```varyk
fn main() {
    println!("Hello, world!");
}
```

Run it:

```text
varyk run hello.vr
```

Output:

```text
Hello, world!
```

## The commands

```text
varyk check <file.vr>                          parse and analyze; never runs cargo
varyk build <file.vr> [--release] [--emit-rust] generate and build; prints the executable path
varyk run   <file.vr> [--release] [-- args...]  build, then execute, forwarding the exit code
```

`check` is the fast loop: it reports Varyk diagnostics without invoking cargo. `--release` builds with optimizations. `build` transpiles the program into a Rust crate under `target/varyk/`, builds it with cargo, and prints the path of the executable; generated Rust never lands in the source tree. `--emit-rust` prints every generated file (`Cargo.toml` and the Rust files) and then builds, so you can see the generated Rust, including the one kind of allocation Varyk inserts (a string literal placed into an owned slot). Every command accepts `--message-format=json` to emit structured diagnostics instead of the human-readable renderer.

## Functions

```varyk
fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn main() {
    println!("{}", add(20, 22));
}
```

Output: `42`. A block's tail expression is its value, as in Rust.

## Structs and borrowing

```varyk
struct User {
    name: string,
    age: i32,
}

fn print_user(user: User) {
    println!("{}", user.name);
}

fn main() {
    let user = User {
        name: "Alice",
        age: 30,
    };

    print_user(user);
    print_user(user);
}
```

Output: `Alice` twice. The second call compiles because a parameter written `user: User` is a shared borrow: `print_user` reads the value and the caller keeps it. There is no `&` at the call site. A function that changes a parameter writes `mut` in its signature; the [borrowing example](/learn/examples/#borrowing) shows that, and the [reference](/learn/reference/#functions-and-parameters) has the rules.

`string` is the only string type. Writing `String` or `str` produces a diagnostic pointing at `string`.

## Modules and Rust files

`mod name;` in the entry file resolves to `name.vr` or `name.rs` in the same directory. A `.vr` module exports its `pub` items; a `.rs` module is plain Rust, compiled as part of the same crate, and its top-level `pub fn` items are callable from Varyk. The [modules](/learn/examples/#modules) and [interop](/learn/examples/#rust-interop) examples show both.

## Diagnostics

Every diagnostic has a code (the [reference](/learn/reference/#error-codes) lists them) and, where it can, a fix-it. Rust habits are recognized and corrected: writing `&user` at a call site, `user: &User` in a signature, `String`, or a lifetime annotation each produce a diagnostic that says exactly what to change.
