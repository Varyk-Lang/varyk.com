+++
title = "Install"
description = "How to install the Varyk compiler and check that it works."
weight = 10
+++

<!-- TODO(release): publish varyk-syntax and varyk 0.0.1 to crates.io before launch, then confirm this command on a clean machine. -->

Varyk requires a stable Rust toolchain installed through [rustup](https://rustup.rs). `varyk build` and `varyk run` invoke `cargo`.

## Install the compiler

```text
cargo install varyk
```

The current release is 0.0.1. To build the compiler from source instead, clone the [repository](https://github.com/Varyk-Lang/varyk) and run `cargo build -p varyk`.

## Check that it works

Save this as `hello.vr`:

```varyk
fn main() {
    println!("Hello, world!");
}
```

Then run it:

```text
varyk run hello.vr
```

It prints `Hello, world!`. The [getting started](/learn/getting-started/) page continues from here.

Varyk is pre-0.1. Command-line flags and the generated Rust layout have no stability guarantee before 0.1.
