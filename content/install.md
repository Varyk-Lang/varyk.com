+++
title = "Install"
description = "How to install the Varyk compiler and check that it works."
weight = 10
+++

Varyk requires a stable Rust toolchain installed through [rustup](https://rustup.rs). `varyk build`, `varyk run`, `varyk test`, `varyk add`, and `varyk publish` invoke `cargo`, and a plain `cargo build` of a package that `varyk init` wrote invokes `varyk`.

## Install the compiler

```text
cargo install varyk
```

Releases are listed on [crates.io](https://crates.io/crates/varyk). To build the compiler from source instead, clone the [repository](https://github.com/Varyk-Lang/varyk) and run `cargo build -p varyk`.

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

Varyk is experimental and pre-1.0. Command-line flags and the generated Rust layout have no stability guarantee before 1.0.
