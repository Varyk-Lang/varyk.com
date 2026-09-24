+++
title = "Tools"
description = "The varyk command line, its diagnostics, and the tooling planned for later milestones."
weight = 30
+++

Varyk owns the front end, the Rust emitter, and diagnostics. Everything else comes from Cargo and rustc: the manifest, dependency resolution, the registry, lockfiles, features, workspaces, caching, cross-compilation, code generation, optimization, and the full borrow check. There is no separate package registry, package manifest, or build system.

## The `varyk` command

```text
varyk check <file.vr>                          parse and analyze; never runs cargo
varyk build <file.vr> [--release] [--emit-rust] generate and build; prints the executable path
varyk run   <file.vr> [--release] [-- args...]  build, then execute, forwarding the exit code
```

Every command accepts `--message-format=json` to emit structured diagnostics instead of the human-readable renderer. `check` is the fast loop and must stay fast. The build directory lives under `target/varyk/`, and generated Rust never lands in the source tree.

## Diagnostics

Diagnostics have codes and fix-its. A code, once assigned, is never reused for a different meaning, though it may be retired. Rust habits are recognized: `&user` at a call site, `user: &User` in a signature, `String` or `str`, and lifetime annotations each get a diagnostic that says exactly what to change.

## Planned

- **Milestone 2:** `varyk init`, which sets up a package with a `build.rs` so plain `cargo build` works; `varyk fmt`, a deterministic formatter; `Cargo.toml` as the package manifest, with Varyk-specific settings under `[package.metadata.varyk]`.
- **Milestone 4:** a language server built on the `varyk-syntax` crate.

Milestone 1 has no package manifest, formatter, or language server. The [roadmap](/design/roadmap/) has the full list.
