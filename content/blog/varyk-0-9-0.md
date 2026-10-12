+++
title = "Varyk 0.9.0: errors in your editor"
description = "varyk lsp brings the compiler's errors and fixes into VS Code, Zed, and any editor that speaks the Language Server Protocol. A package's varyk-std line now names the oldest varyk it needs, so a new varyk no longer breaks published packages. Rust 1.88 is the minimum."
date = 2026-10-12
+++

Varyk 0.9.0 is on crates.io. It is the first release of milestone 6 on the [roadmap](/design/roadmap/): tooling. It brings three things:

- `varyk lsp`, a language server, so the errors and fixes of `varyk check` show up in your editor;
- a `varyk-std` line that names the oldest varyk a package needs, so a new varyk no longer breaks published packages;
- Rust 1.88 as the minimum.

## Errors in your editor

Until now, you saw Varyk's errors when you ran `varyk check`. Now your editor shows them. Each time you open or save a `.vr` file, `varyk lsp` checks the program the file belongs to, exactly as `varyk check` would. The editor underlines every error where it is, with its message, notes, and code. When an error has a suggested fix, the editor offers it as a quick fix. A fix can change another file: a missing `pub` is added where the item is declared.

The server checks what is on disk, so a fixed error disappears once you save. You never run `varyk lsp` yourself. The editor starts it. The [reference](/learn/reference/#editors) explains which program a file belongs to.

The editor support lives in a new repository, [`varyk-editors`](https://github.com/Varyk-Lang/varyk-editors):

- **VS Code**, and the editors built on it: install **Varyk** from the Visual Studio Marketplace, or from Open VSX in VSCodium and the others that use it. It colours `.vr` files, toggles comments, matches brackets, indents, and starts `varyk lsp`. In a folder VS Code does not trust, it only highlights and runs nothing.
- **Zed**: the **Varyk** extension is [submitted](https://github.com/zed-industries/extensions/pull/8007) to Zed's extension registry. It will be in the extensions panel as soon as the Zed team merges it. Until then, run "zed: install dev extension" and choose the `zed/` folder of a checkout of `varyk-editors`. It is built on a Tree-sitter grammar, [`tree-sitter-varyk`](https://github.com/Varyk-Lang/tree-sitter-varyk). It colours `.vr` files, gives you the outline panel, and starts `varyk lsp`. In a folder Zed does not trust, it only highlights and runs nothing.
- **JetBrains IDEs**: colours, comment toggling, and bracket matching, through the TextMate Bundles setting pointed at the `vscode/` folder of a checkout of `varyk-editors`. [Its README](https://github.com/Varyk-Lang/varyk-editors#jetbrains) has the steps. No diagnostics there yet: those need a plugin on the IDE's own language server API.
- **Any other editor** that speaks the Language Server Protocol can run `varyk lsp` itself.

With `varyk` 0.9 on your `PATH`, there is nothing to set up. If it lives somewhere else, VS Code has a `varyk.path` setting. Highlighting never depends on the language server, so with an older `varyk`, or none, you still get colours.

## Packages keep building

Up to 0.8, a program and every Varyk package in its build had to name the compiler's own minor version of `varyk-std`. So every minor release of the compiler, even one that changed nothing in `varyk-std`, broke every published package until that package released again. I did not want every varyk release to force a release of every package.

From 0.9, `varyk-std = "0.8"` means "needs varyk 0.8 or later". This varyk and every later one accept it, and the build always uses the compiler's own `varyk-std`, in the program and in every package. A compiler older than the line refuses it with V0404. From 0.9 on, that error says "this package needs varyk X.Y or later" and tells you to run `cargo install varyk`. When a package written for an older varyk does not pass the check, every error it shows gets one more note, here for a package called `units`: "`units` was written for varyk 0.8; a newer release of it may build with this compiler".

So [varyk-http](https://github.com/Varyk-Lang/varyk-http) 0.2, [varyk-sql](https://github.com/Varyk-Lang/varyk-sql) 0.4, and [varyk-mongo](https://github.com/Varyk-Lang/varyk-mongo) 0.1, all written for varyk 0.8, build with 0.9 as they are. No new releases needed.

`varyk publish` keeps the old, strict rule. A published crate is built by plain cargo from its own `Cargo.toml` and lock. Nothing rewrites them there. So you publish with a varyk on the minor your line names.

## Rust 1.88

The compiler now needs Rust 1.88 or newer, up from 1.85, and CI checks it. varyk-mongo needed 1.88 from the start, for its MongoDB driver.

## For Rust readers

Before 1.0, cargo treats `varyk-std` 0.8 and 0.9 as two different crates whose types do not mix. An open requirement like `>=0.8` does not help either: cargo picks the newest release, which can be yet another minor. So I did not loosen the requirement. varyk already writes every manifest of the build under `target/varyk/`. Now it also puts its own `varyk-std` version in each one, so every Varyk crate of the build uses the same `varyk-std`. Your own `Cargo.toml` and `Cargo.lock` are left alone.

A package's Varyk code is generated by your compiler against that `varyk-std`, so it always matches. Only a package's own `.rs` files were written against an older one. If a newer `varyk-std` removed something they call, rustc says so at that file.

`varyk lsp` adds no dependency to the compiler. The protocol is JSON-RPC with `Content-Length` framing, read and written with the `serde_json` the compiler already uses, and positions are in UTF-16, the protocol's default.

## What is not there yet

Hover, go-to-definition, and completion need a parser that recovers from an error and keeps going, and Varyk's does not yet. Checking as you type needs the server to read unsaved files and a checker fast enough to run on every keystroke. For now it checks on open and save. A file that no `mod` line reaches yet gets no errors until one does. The [roadmap](/design/roadmap/) has the rest of milestone 6.

## Upgrading

The three crates, `varyk`, `varyk-syntax`, and `varyk-std`, are released together as 0.9.0. One thing is breaking: the compiler needs Rust 1.88, so run `rustup update` first if yours is older. Then `cargo install varyk --locked`.

A program written for 0.8 builds as it is, but move its `varyk-std` line anyway, and do it again after each new minor varyk. The build uses varyk-std 0.9. It never touches your `Cargo.toml` or `Cargo.lock`. So while the line says 0.8, the lock has no varyk-std 0.9, and every build asks crates.io for it again. Online, that is a bit slower. Offline, or in a CI job or container build without network access, the build fails. In the program's folder:

1. change the line to `varyk-std = "0.9.0"`;
2. run `cargo update -p varyk-std`. Cargo may say the name is ambiguous. That happens when the lock also holds the varyk-std 0.8 that a package like varyk-http was written for. Then run `cargo update -p varyk-std@0.9.0` instead.

Commit both files, and builds work offline again. A program made with `varyk init` 0.9 starts on the new line. The [reference](/learn/reference/#varyk-add-and-upgrading) has the details.

To publish with varyk 0.9, move the line to 0.9 first: `varyk publish` wants the compiler's own minor and no older `varyk-std` anywhere in the build. A package that uses varyk-http, varyk-sql, or varyk-mongo is published with varyk 0.8 until the packages it uses have a release written for varyk 0.9. That goes for a library and for a program.

## Try it

You need a stable Rust toolchain, 1.88 or newer, installed through [rustup](https://rustup.rs).

```text
cargo install varyk --locked
varyk init hello
cd hello
varyk run
```

Then install the Varyk extension in VS Code, or in Zed once it is listed, open the folder, break something in `src/main.vr`, and save. [Getting started](/learn/getting-started/) goes on to [a first service](/learn/getting-started/#a-first-service), and the [language reference](/learn/reference/) describes everything the compiler accepts.

## What is next

The rest of milestone 6: `varyk fmt`, the rest of the language server, nested modules in `.rs` files, Rust tuple and unit structs imported from `.rs` files, `Debug` on imported Rust structs, and a decision on a native backend. Next to it, `varyk-redis`, the next package. None of it has a date.

Varyk is experimental and pre-1.0. Open a `.vr` file, save it with a mistake in it, and tell me where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
