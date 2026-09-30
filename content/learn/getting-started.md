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
varyk check [file.vr]                            check for errors; never runs cargo
varyk build [file.vr] [--release] [--emit-rust]  generate and build; print the executable's path
varyk run [file.vr] [--release] [-- args...]     build, then run with the given arguments
varyk test [file.vr]                             build the tests and run them
varyk emit [file.vr] --out-dir DIR               check, then write the generated tree to DIR;
                                                  never runs cargo
varyk init [dir] [--lib]                         write a package that plain cargo build compiles
varyk add [cargo add args]                       run cargo add in the package
varyk publish [--assemble-only] [-- cargo args]  check, assemble a plain Rust crate, and run
                                                  cargo publish there
```

Without a file, a command works on the package around the current directory (see [a package](#a-package) below). `check` is the fast loop: it reports Varyk diagnostics without invoking cargo. `--release` builds with optimizations. `build` transpiles the program into a Rust crate, builds it with cargo, and prints the path of the executable; generated Rust goes under `target/varyk/`, never next to your `.vr` files. `--emit-rust` prints every generated file (`Cargo.toml` and the Rust files) and then builds, so you can see the generated Rust, including the one kind of allocation Varyk inserts (a string literal placed into an owned slot). `emit` writes the generated tree to a directory, for a file or a package; `init` and `publish` are for packages; the [tools page](/tools/#packages) describes them. Every command accepts `--message-format=json` to emit structured diagnostics instead of the human-readable renderer, including the warnings rustc gives about your `.rs` modules; under `run` and `test`, they go to standard error, since standard output is the program's or the test runner's own. `test` builds the program with its tests and runs them, and `add` runs `cargo add` in the package; the [reference](/learn/reference/#tests) describes tests.

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

`mod name;` loads the module `name` from `name.vr` or `name.rs` beside the file, or from `name/mod.vr`. Any `.vr` file can declare modules of its own, to any depth: `mod cart;` in `shop.vr` loads `shop/cart.vr`. A module is private to the module that declares it unless it is declared `pub mod`, and a `.vr` module exports its `pub` items. `use crate::shop::cart::Cart;` makes a shorter local name for a module, struct, enum, or function of the package. A `.rs` module is plain Rust, compiled as part of the same crate; Varyk imports its `pub fn`s, its `pub struct`s with their inherent methods, and its `pub enum`s. The [modules](/learn/examples/#modules), [interop](/learn/examples/#rust-interop), and [package](/learn/examples/#packages) examples show all of these.

## A package

A program with dependencies, or one you want to publish, is a package. `varyk init` writes one:

```text
varyk init hello
cd hello
varyk run
```

It prints `Hello, world!`. `init` wrote `Cargo.toml` (the manifest, with `edition = "2024"` and `varyk-std`, the crate behind `Error`, `json`, `env`, and `log`, under `[dependencies]`), `.gitignore`, `build.rs`, a one-line `src/main.rs` stub, and `src/main.vr`, the program. Inside the package, commands need no file name. `cargo run` works too, with `varyk` on the `PATH`, because `build.rs` calls it to generate the Rust. To use a crate, add it with `varyk add` or `cargo add` and call it from a `.rs` file in the package, a facade that wraps what the program needs; the [matcher](/learn/examples/#matcher) example wraps `regex-lite` this way.

## Diagnostics

Every diagnostic has a code (the [reference](/learn/reference/#error-codes) lists them) and, where it can, a fix-it. Rust habits are recognized and corrected: writing `&user` at a call site, `user: &User` in a signature, `String`, or a lifetime annotation each produce a diagnostic that says exactly what to change.
