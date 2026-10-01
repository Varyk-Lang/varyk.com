+++
title = "Tools"
description = "The varyk command line, packages and publishing, diagnostics, and the tooling planned for later milestones."
weight = 30
+++

Varyk owns the front end, the Rust emitter, and diagnostics. Everything else comes from Cargo and rustc: the manifest, dependency resolution, the registry, lockfiles, features, workspaces, caching, cross-compilation, code generation, optimization, and the full borrow check. There is no separate package registry, package manifest, or build system: a Varyk package is a Cargo package.

## The `varyk` command

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

Without a file, each command works on the package found by looking for `Cargo.toml` in the current directory and then upward. `--release` builds with optimizations. `--emit-rust` prints every generated file, `Cargo.toml` and the Rust files, each after a line naming it, and then builds. Every command accepts `--message-format=json`, which prints errors, and the warnings rustc gives about your `.rs` modules, as JSON on standard output, one object per line, with file, line, and byte column for the error, each label, and the fix-it; under `varyk run` and `varyk test`, whose standard output is the program's or the test runner's own, they go to standard error instead. `check` is the fast loop and must stay fast. `varyk test` builds the program with its `#[test]` functions and runs them, showing the Rust test runner's report; `varyk build` and `varyk run` leave the tests out. Generated Rust goes under `target/varyk/`, never next to your `.vr` files. An error or warning rustc reports in a `.rs` module you wrote is shown at your file and line, unchanged; a rustc error in the code Varyk generated, which should not happen, is reported as V0900 at the Varyk line responsible. Another exception is a started task that holds a value from a `.rs` module that cannot move to another thread: that is your Rust code's choice, reported as V0901 naming the Rust type.

## Packages

A package is a directory with a `Cargo.toml` and a `src/main.vr` (a program) or `src/lib.vr` (a library). `Cargo.toml` is the manifest, as in any Rust project, and needs `edition = "2024"`; `[package.metadata.varyk]` is reserved for Varyk and has no keys yet. `[dependencies]` names Rust crates that the package's `.rs` modules call, and a `Cargo.lock` beside `Cargo.toml` is used when building, so Varyk builds the same crate versions cargo would. Varyk code never names a crate itself: a `.rs` file in the package, a facade, wraps what the program needs, and Varyk imports that.

`varyk init [dir]` writes a new package named after the directory: `Cargo.toml`, which lists `varyk-std` at the compiler's own version under `[dependencies]`, `.gitignore`, which leaves out `/target` and `.env`, `build.rs`, `src/main.rs`, and `src/main.vr`, a hello-world program (`--lib` writes `src/lib.rs` and `src/lib.vr` instead). It refuses to overwrite any of them. The package builds with `varyk build` and `varyk run`, and with plain `cargo build`: `build.rs` runs `varyk emit` to generate the Rust, and the one-line stub `src/main.rs` includes it, so plain `cargo build` needs `varyk` on the `PATH`, or the `VARYK` environment variable naming its path.

`varyk add` runs `cargo add` in the package with exactly the arguments you give, and passes cargo's output and exit code through. `varyk-std` is the one crate Varyk code reaches without a facade: it is behind `Error`, `json`, `env`, and `log`, and since milestone 5b1 the async runtime: an async `main` or test, a started call, `Task::all` or `Task::all_settled`, and `time::sleep`. A program that uses it needs `varyk-std` in `[dependencies]` at the compiler's version, and `Cargo.lock`, if it locks `varyk-std`, no older; `varyk check` says which of these fails (V0404) and the line to write. To upgrade, run `cargo install varyk`, then whatever `varyk check` asks for: change the line, or run `cargo update -p varyk-std`.

`varyk publish` runs the full check, assembles a plain Rust crate at `target/varyk/package/<name>/` with the generated `.rs` files and every `.vr` source beside the file it produced, and no `build.rs`, then runs `cargo publish` there, passing on every argument after `--`. The crate needs no `varyk`: a consumer adds it to `[dependencies]` like any crate, and `cargo install` of a published Varyk binary works the same way. `varyk publish --assemble-only` stops after the assembly, prints the crate's directory, and publishes nothing.

## Diagnostics

Diagnostics have codes and fix-its; the [reference](/learn/reference/#error-codes) lists every code. A code, once assigned, is never reused for a different meaning, though it may be retired. Rust habits are recognized: `&user` at a call site, `user: &User` in a signature, `String` or `str`, and lifetime annotations each get a diagnostic that says exactly what to change.

## Planned

- **Milestone 6:** `varyk fmt`, a deterministic formatter, and a language server, both built on the `varyk-syntax` crate.

Milestone 3 added `Cargo.toml`; there is no formatter or language server yet. The [roadmap](/design/roadmap/) has the full list.
