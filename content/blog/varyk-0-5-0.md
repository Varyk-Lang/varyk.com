+++
title = "Varyk 0.5.0: packages"
description = "Milestone 5b2 lets Varyk code use a Varyk package by its key in Cargo.toml, to any depth, builds every package from its .vr sources without running a build script or shipped Rust, removes build.rs, the stub, and varyk emit, and redraws milestone 5 around packages."
date = 2026-10-02
+++

<!-- TODO(release): set the date to the day 0.5.0 is on crates.io. -->

Varyk 0.5.0 is on crates.io. It is milestone 5b2 of the [roadmap](/design/roadmap/), the third part of the batteries for services. Milestones 5a and 5b1 gave Varyk, a language for backend services that compiles to Rust, the data a service works with and the way it waits: JSON, configuration, logging, tests, and tasks. Milestone 5b2 adds the way Varyk code is shared: a Varyk package uses another Varyk package by name, with no Rust file in between, and every package is built from the Varyk its author wrote. It comes before HTTP and the database because they will be packages too.

## What is in it

**A package is named by its key.** Until now, Varyk code reached any other package, a Varyk library included, through a `.rs` file of its own, a facade. Now a Varyk package listed in `[dependencies]` is named in Varyk code like a module, by its key, with each `-` read as `_`. With `units = { path = "../units" }` in `Cargo.toml`:

```varyk
use units::length::Meters;

fn total(a: Meters, b: Meters) -> Meters {
    units::length::add(a, b)
}
```

There is no new syntax. You choose the key, so `sql = { package = "varyk-sql", version = "0.5" }` would be `sql::` in your code, and two packages cannot share a name. A local module of the same name wins over a package. A dependency is a Varyk package when its folder has `src/lib.vr`, whether it comes from a path, a registry, or git. A Rust crate is still never named from Varyk code: it is called from a `.rs` facade, as before, and naming one is V0110.

**Packages that use packages.** A package may use packages, to any depth: in the new examples, `trip` uses `route`, and `route` uses `units`. Each package sees only the packages its own `Cargo.toml` lists. If `route` gives you a `Meters` of `units` and your package lists `route` but not `units`, holding that value is V0115, and the help is the line to add. When cargo picks two versions of one package, they are two packages, and V0115 names both.

**What a package gives you.** Everything it marks `pub` that its users can reach: functions, structs with their `pub` fields, enums, methods, and the `pub` items of its `.rs` modules. They behave like your own: parameters borrow, `mut` parameters change the caller's value, an async function is awaited or started, and a `match` on its enum is checked for every case. A library cannot hand out a type its users could not name, so a `pub` function that returns a type of a private module is V0105 in the library itself. Two things stay inside a package: JSON and configuration conversions, so a `json` or `env` call on another package's type is V0210 (convert it in its own package), and its `#[test]` functions. And when any package in a build writes log lines, the program sets up logging, so they are not lost.

**What runs when you build.** Varyk is for services that face the network, so this release makes one promise about what runs on your machine. When `varyk build`, `varyk run`, or `varyk test` builds your program, the Rust of every Varyk package in it is exactly that package's own `.rs` files plus what your compiler generates from its `.vr` files. Nothing else in the package is compiled or run: not its `build.rs`, and not generated Rust its publisher shipped. `varyk` asks cargo which packages the build uses, checks every Varyk package from its `.vr` sources, and builds each as a crate of its own under `target/varyk/packages/`. What runs is what a reader can review. The package's own `.rs` files, the Rust crates it depends on, and their build scripts are Rust, visible as files and lines of `Cargo.toml`, and rustc's to judge, as for your own code.

The promise covers `build`, `run`, and `test`, and the reference names the one command it does not: `varyk publish`. `cargo publish` verifies a crate by building it as a plain cargo user would, so publishing compiles a Varyk dependency's shipped Rust, and any `build.rs` it was published with, on the publisher's machine. `--no-verify` after `--` skips that.

**What is refused.** Cargo would build a Varyk package on its own, outside that promise, if it were reached any other way, so V0401 refuses a Varyk package under `[dev-dependencies]`, one marked `optional` that a feature turns on, and one reached through a Rust crate, even when it is also used the supported way. It also refuses a Varyk package with the same name and version as another Varyk package of the build, or as a package that comes from a `path`. Naming a dependency marked `optional` in Varyk code is V0401 too, because cargo may leave it out of the build.

**Varyk builds Varyk.** A package's `Cargo.toml` now names its `.vr` root as cargo's target:

```toml
[[bin]]
name = "trip"
path = "src/main.vr"
```

or `[lib]` with `path = "src/lib.vr"` for a library. That is what lets cargo's own tools, such as `cargo add`, `cargo update`, and `cargo tree`, read the package. `varyk init` writes three files, `Cargo.toml`, `.gitignore`, and `src/main.vr`, and no `build.rs` and no stub, and `varyk emit`, which the build script ran, is gone. A source package is built with `varyk build`, not with plain `cargo build`, since its root is Varyk, not Rust. A Varyk crate published with `varyk publish` still carries its generated Rust, so a Rust project uses it with plain cargo, as any crate.

**New diagnostic codes.** V0115 is a value of a package your package does not list, or of another version of one it does. V0405 is cargo failing to work out which packages the build uses, for example a `path` dependency whose folder is missing, with cargo's own message in the note. V0406 is a `Cargo.toml` that does not name its `.vr` root, with the lines to add. The [language reference](/learn/reference/#packages) has the new section, and the [error codes](/learn/reference/#error-codes) the full table.

Two new example packages show it, and the [examples](/learn/examples/#route) page has them with their output: `route`, a library whose legs have a length in `Meters` of the package `units`, and `trip`, a program that uses both. This is `trip`'s `Cargo.toml`:

```toml
[package]
name = "trip"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "trip"
path = "src/main.vr"

[dependencies]
route = { path = "../route" }
units = { path = "../units" }
varyk-std = "0.4.0"
```

<!-- TODO(release): re-copy trip's Cargo.toml once the release pull request sets its varyk-std line to 0.5.0. -->

and its `src/main.vr`:

```varyk
async fn main() {
    let legs = vec![
        route::leg("Home", "Mill", 800),
        route::leg("Mill", "Lake", 900),
    ];
    let sum = units::length::add(route::total(legs), units::length::Meters { value: 0 });
    println!("total {} meters", sum.value);
    let best = route::longest(legs);
    println!("longest {} to {}, {} meters", best.from, best.to, best.length.value);
    for text in vec!["{\"name\": \"Lake\", \"minutes\": 12}", "Lake at noon"] {
        match route::parse_stop(text) {
            Ok(stop) => println!("stop {}, {} minutes", stop.name, stop.minutes),
            Err(_) => println!("no stop"),
        }
    }
    let minutes = route::walking_minutes(sum.value).await;
    println!("about {} minutes on foot", minutes);
}
```

It prints:

```text
total 1700 meters
longest Mill to Lake, 900 meters
stop Lake, 12 minutes
no stop
about 21 minutes on foot
```

`route::longest` gives back one of the legs it was given, not a copy, as a function of your own would, and `route::walking_minutes` is an async function awaited across the package line. `trip` writes no log line itself, but `route` warns on stderr when it cannot read a stop, so the program sets up logging for it.

## The breaking changes

A package's `Cargo.toml` must name its `.vr` root, `[[bin]]` with `path = "src/main.vr"` or `[lib]` with `path = "src/lib.vr"`; without it, `varyk check` reports V0406, and its help gives the lines. `varyk emit` is removed. `varyk init` no longer writes `build.rs` or a stub, and a source package is built with `varyk build`, not plain `cargo build`. A `build.rs` or `src/main.rs` left by an earlier `varyk init` is never read, so you can delete them. `build` in `[package]` may only be left out or `false`.

The three crates, `varyk`, `varyk-syntax`, and `varyk-std`, are released together as 0.5.0. After `cargo install varyk`, run `varyk check` in a package, and it says what to change.

## Try it

You need a stable Rust toolchain installed through [rustup](https://rustup.rs).

```text
cargo install varyk
varyk init hello
cd hello
varyk run
```

The [getting started](/learn/getting-started/) page goes from there, and the [language reference](/learn/reference/) describes everything the compiler accepts.

## What is next

Milestone 5b2 also redraws the rest of milestone 5. `varyk-std` stays the small runtime every program has: `Error`, tasks, `json`, `env`, and `log`. Anything heavy, the HTTP server and client, SQL, MongoDB, Redis, is a package the writer adds, so a program that prints a line never compiles a web server or a database driver. Official packages are named `varyk-*`, such as `varyk-sql` and `varyk-http`, and packages from the community `*-varyk`. With packages in place, a battery is written once as a package, by this project or by anyone, and needs no work in the compiler.

Milestone 5b3 is facades and `varyk-sql`: what a `.rs` facade can say, such as a function that takes or returns any Varyk data type, `pub use`, and `varyk add` shorthands for official packages; then `varyk-sql` on sqlx, for SQLite, Postgres, and MySQL, where the query text is written in the program, so a query built from input is a compile error. Milestone 5b4 is `varyk-http` and the golden path: an HTTP server with an explicit route table, an HTTP client, and the bar for all of milestone 5, a users API on a database that is `varyk init`, `varyk add http sql`, one file, and `varyk run` away. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Try splitting a small service into packages and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
