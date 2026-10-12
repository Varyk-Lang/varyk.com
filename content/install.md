+++
title = "Install"
description = "How to install the Varyk compiler, check that it works, and set up your editor."
weight = 10
+++

Varyk requires a stable Rust toolchain, 1.88 or newer, installed through [rustup](https://rustup.rs). `varyk build`, `varyk run`, `varyk test`, `varyk add`, and `varyk publish` invoke `cargo`, and `varyk check` does too when a package lists a dependency besides `varyk-std`, to learn which packages the build uses. A Varyk package is built with `varyk`; plain `cargo build` builds a published Varyk crate, not a package's source. A service on `varyk-sql` also needs a C compiler, since its default database, SQLite, is compiled from C on the first build: Xcode's command-line tools on macOS, `build-essential` on Debian and Ubuntu.

## Install the compiler

```text
cargo install varyk --locked
```

`--locked` builds it with the dependency versions it was released with. Releases are listed on [crates.io](https://crates.io/crates/varyk). To build the compiler from source instead, clone the [repository](https://github.com/Varyk-Lang/varyk) and run `cargo build -p varyk`.

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

## Set up your editor

Install **Varyk** from the Visual Studio Marketplace in VS Code, or from Open VSX in VSCodium and the other editors that use it. The Zed extension is [submitted](https://github.com/zed-industries/extensions/pull/8007) to Zed's registry and appears in Zed's extensions panel once the Zed team merges it; until then, "zed: install dev extension" on the `zed/` folder of a checkout of `varyk-editors` installs it. The extension, from [`varyk-editors`](https://github.com/Varyk-Lang/varyk-editors), colours `.vr` files and runs `varyk lsp`, which checks your program each time you open or save a file, underlines every error where it is, and offers each fix-it as a quick fix. In a folder the editor does not trust, it only colours and runs nothing. JetBrains IDEs get the colours through their TextMate Bundles setting, pointed at the `vscode/` folder of a checkout of `varyk-editors`, as [its README](https://github.com/Varyk-Lang/varyk-editors#jetbrains) shows; the [tools page](/tools/#editors) has more, and any editor that speaks the Language Server Protocol can run `varyk lsp` itself.
