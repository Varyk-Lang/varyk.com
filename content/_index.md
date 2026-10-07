+++
title = "Varyk"
description = "Build backend services simply. Ship Rust binaries. Varyk is an experimental language for APIs, workers, and microservices that compiles to Rust, with Rust's safety and Go's simplicity."
sort_by = "weight"

# The hero and its figure are rendered by templates/index.html.
[extra]
eyebrow = "Simple services. Rust underneath."
headline = ["Build backend services simply.", "Ship Rust *binaries.*"]
lead = "Varyk is a small language for APIs, workers, and microservices. No garbage collector, no lifetime annotations, no borrow ceremony, and Rust and crates.io underneath. You write Go-like application code and ship one native binary, checked by the Rust compiler."
install_label = "Install with Cargo"
install = "cargo install varyk --locked"
# The hero figure (templates/partials/home-service.html) shows the users API of milestone 5b4, as it runs with varyk-http.
figure_caption = "A users API on a database in one file, the service of milestone 5b4's [design](https://github.com/Varyk-Lang/varyk/blob/main/docs/specs/2026-10-05-milestone-5b4-design.md); it runs with the `varyk-http` package, and `varyk check` checks each route against its handler. `http` and `sql` are the keys `varyk add http sql` gives the [`varyk-http`](https://github.com/Varyk-Lang/varyk-http) and `varyk-sql` packages, named as any Varyk package is since milestone 5b2; `varyk-sql` arrived with milestone 5b3, and `varyk-http` with milestone 5b4. `Error` and `log` are here since milestone 5a, and `async` and `Shared` since milestone 5b1. See the [roadmap](/design/roadmap/)."
# The borrowing figure (templates/partials/home-figure.html) is placed in the band whose entry sets `figure = "borrowing"`.
borrowing_caption = "The Rust that `varyk build` generates from `borrowing.vr`, as the compiler writes `src/main.rs`. **Marked**: everything the compiler writes for you. The program prints `Alice`, then `Bob`."

[[extra.actions]]
name = "Get started"
path = "/learn/getting-started/"

[[extra.actions]]
name = "Why Varyk?"
path = "/why/"

# One entry per `##` section below, in order. The template numbers them and wraps each in a band.
# `style` picks the layout in site.css; `columns` splits a section into one column per `###`;
# `figure = "borrowing"` places the borrowing figure after the band's first paragraph;
# `done` is the number of completed milestones in the roadmap.
[[extra.bands]]
id = "what-you-get"
label = "What you get"
style = "get"

[[extra.bands]]
id = "cargo"
label = "Cargo underneath"
style = "flow"

[[extra.bands]]
id = "how-it-works"
label = "How it works"
style = "changes"
figure = "borrowing"

[[extra.bands]]
id = "who"
label = "Who it’s for"
style = "who"
columns = true

[[extra.bands]]
id = "roadmap"
label = "Roadmap"
style = "road"
done = 9

[[extra.bands]]
id = "get-started"
label = "Get started"
style = "start"
+++

## What a service needs. What Rust *guarantees.*

Rust underneath gives you all of this today. The batteries that make a service, what a Go or TypeScript team expects to find built in, are listed below them: JSON, configuration, logging, and tests arrived in milestone 5a, `async` in milestone 5b1, packages that use packages in milestone 5b2, facades for packages in milestone 5b3, and routes checked against their handlers in milestone 5b4; databases and HTTP come as packages, `varyk-sql` since milestone 5b3 and `varyk-http` since milestone 5b4.

<!-- Size, memory, and start time: examples/todo built with `varyk build --release` (compiler commits 84509f6 and 5675863) on an Apple Silicon Mac, September 2026: 435 KB as built, 342 KB stripped, 1.5 MB peak resident memory, about 4 ms wall clock to start (examples/hello.vr: 434 KB, 342 KB stripped, 1.5 MB, 4 ms). Refresh these when the figures in the list change. -->

- **One file to deploy.** A whole program is one executable, under half a megabyte for the [`todo` example](/learn/examples/#todo) built on an Apple Silicon Mac, with no language runtime to install.
- **Starts instantly, stays small.** The `todo` example starts in a few milliseconds and uses about a megabyte and a half of memory on an Apple Silicon Mac. There is no garbage collector, so no pauses and no memory ceiling to tune.
- **Bugs caught before the program runs.** No null: a value that can be missing is an `Option`, and you must handle it. Errors are values, not exceptions: a function that can fail says so in its return type, and there is nothing to catch. Two threads cannot touch the same data unsafely. All of it is rustc checking your program, not Varyk approximating it.
- **As fast as Rust, because it is Rust.** Native code, no interpreter, no just-in-time compiler, nothing cloned behind your back.
- **No ownership ceremony.** No lifetime annotations, no choosing between `x`, `&x`, and `&mut x` at a call site, and one string type. The compiler makes those decisions, and rustc checks every one of them.
- **Readable Rust, yours to keep.** The generated Rust is a normal Cargo project, `--emit-rust` shows all of it, and there is no lock-in.
- **The whole Rust ecosystem.** A Varyk package is a Cargo package: since milestone 3 you add a crate with `cargo add`, or `varyk add` since milestone 5a, and call it from a `.rs` file in the package, and the next section shows how.
- **Drop into Rust when you need it.** A `.rs` file beside your `.vr`, in the same package and the same build. Write the borrow-heavy part in Rust and the rest in Varyk. Use Varyk until you actually need Rust.

### The batteries, milestone 5

JSON, configuration, logging, and tests are in the compiler since milestone 5a, and `async` since milestone 5b1; the [examples](/learn/examples/#json) show them. Databases and HTTP come as packages you add, `varyk-sql` and `varyk-http`, so a program that prints a line never compiles a web server or a database driver. Milestone 5b3 gave the compiler what `varyk-sql` needs, and milestone 5b4 what `varyk-http` needs; each package lives in its own repository and is released with them. The figure at the top of the page is a service with both.

- **JSON from your structs.** Turn your structs into JSON and back with `json::parse` and `json::stringify`, and rename, default, or skip a field with an attribute. *Milestone 5a.*
- **Configuration, logging, tests.** A struct filled from the environment and a `.env` file with `env::parse`, log lines on stderr as text or JSON, and `varyk test`. *Milestone 5a.*
- **Async built in.** `async fn` and `.await` on a built-in runtime; call a function without `.await` to start it as a task, and wait on many with `Task::all`. *Milestone 5b1.*
- **Databases through one API.** Query SQLite, Postgres, or MySQL and get your structs back, in the [`varyk-sql`](https://github.com/Varyk-Lang/varyk-sql) package on sqlx; the query text is written in the program, so a query built from input is a compile error. *Milestone 5b3.*
- **HTTP server and client.** An explicit route table that `varyk check` checks against each handler, handlers whose return value is the response, errors whose internal message never reaches a client, and calls to other services, in the [`varyk-http`](https://github.com/Varyk-Lang/varyk-http) package on axum and reqwest. *Milestone 5b4.*

Varyk exists so that ordinary backend services can be written simply and shipped as safe Rust. It is for the application: kernels, database engines, and borrow-heavy libraries stay in Rust, in a `.rs` file beside your Varyk, in the same build. [Read why Varyk exists](/why/).

## Varyk packages are Cargo *packages.*

A Varyk package is a `Cargo.toml` and a `src/main.vr`. `varyk init` writes one, `varyk run` builds it, and `varyk publish` ships it to crates.io as an ordinary Rust crate that needs no Varyk to use. Since milestone 5b2, a Varyk package uses another Varyk package by its key in `Cargo.toml`, with no facade, and `varyk` builds every one of them from its `.vr` sources, never from Rust its publisher shipped. There is nothing to bootstrap: every crate on crates.io was Varyk's ecosystem from the first day, and every Varyk package joins it.

1. **`main.vr`** Your service, in Varyk. It never names a Rust crate, and it never writes a reference.
2. **`text.rs`** A Rust file beside it: a facade that wraps what the program needs in plain functions, structs, and enums, which Varyk imports like a module of its own. Since milestone 5b3, a facade can also read its result into whatever type the caller names and take any number of values, and since milestone 5b4 take any value JSON can write, so a package such as `varyk-sql` is Varyk with a thin layer of Rust.
3. **crates.io** Any crate, added with `varyk add` or `cargo add`. Need Stripe, AWS, or Kafka? Use the Rust crate.

Need something Varyk doesn't provide? Use the Rust crate. Need Rust itself, for the one hot loop or the borrow-heavy library? Write it in the `.rs` file, in the same build, and call it from Varyk. The [matcher](/learn/examples/#matcher) example wraps `regex-lite` this way, and the [tools page](/tools/#packages) describes `init` and `publish`.

## How it *works.*

Most of Rust's surface is the *spelling* of decisions the compiler can make on its own. Varyk keeps Rust's ownership model inside the compiler and takes the spelling out of the language. This program runs today; everything marked is what the compiler wrote for you.

| Rule | In Rust you write | In Varyk you write |
|---|---|---|
| **Functions borrow by default.** The signature carries the contract. | `fn rename(user: &mut User)` | `fn rename(mut user: User)` |
| **Call sites never write `&`.** No choosing between `x`, `&x`, and `&mut x`. | `rename(&mut user);` | `rename(user);` |
| **One string type.** The compiler decides the representation. | `name: "Alice".to_string()` | `name: "Alice"` |

From your source to the binary:

1. **`.vr`** Varyk source, with `.rs` files beside it in the same build.
2. **`varyk build`** Parses, type-checks, and runs borrow analysis. Diagnostics carry codes and fix-its.
3. **`target/varyk/`** A Cargo project of readable Rust. It is yours, so there is no lock-in.
4. **`cargo`** rustc and the full borrow checker. Varyk never uses `unsafe` to get around it.
5. **A native binary** No garbage collector, no reference counting, no runtime beyond Rust's.

## Wherever you’re coming from.

### Building services in Go, TypeScript, or Python

- Application code as simple as Go: the compiler does the memory bookkeeping that Rust asks you to write by hand.
- Native speed and memory safety with no garbage collector: no pauses, no memory ceiling to tune, and one small binary to deploy with no language runtime to install.
- The bugs Go and TypeScript compile, a missing value, an unhandled error, two threads on one piece of data, rustc rejects.
- `async`/`await` that looks like JavaScript, with a built-in runtime, since milestone 5b1.
- One toolchain and one package registry, inherited from Cargo and crates.io, since milestone 3.

### Coming from Rust

- Rust syntax and idioms: immutability by default, `let mut`, `struct`, `impl`, `match`, `Option`, `Result`, and `?`.
- The same safety model: the generated Rust is checked by rustc, and Varyk never bypasses it.
- Less ceremony for application code.
- `.rs` files next to `.vr` files in the same package, built by the same `cargo`.
- Varyk packages are Cargo packages and publish to crates.io as ordinary crates, since milestone 3.

### Written with a coding agent

- Agents already write good code; the slow part is reviewing it. Varyk is designed to keep reviews short.
- A small language with one way to do each thing, so agent output looks like the code around it.
- Concrete code, with few abstractions to see through.
- rustc checks memory safety and data races, so a review can focus on what the service does.
- A reference that fits in a prompt, and JSON diagnostics with codes and fix-its, so the agent fixes its own mistakes first.
- One official stack for HTTP, JSON, and databases, the same in every Varyk service (JSON since milestone 5a; databases and HTTP as the packages `varyk-sql`, since milestone 5b3, and `varyk-http`, since milestone 5b4).

## Ordered milestones, no *dates.*

1. **Milestone 1, complete.** Compiler skeleton and the borrow-by-default proof: six example programs, diagnostics with codes and fix-its, and `varyk check`, `build`, and `run`.
2. **Milestone 2, complete.** Enums, `match`, `for`, methods, `Option`, `Result`, `Vec`, `?`, and `format!`.
3. **Milestone 3, complete.** Packages and interop: `Cargo.toml`, Cargo dependencies through `.rs` facades, nested modules, `use`, private fields, Rust structs and enums imported from `.rs` files, `varyk init`, and publishing to crates.io. Released as 0.1.0.
4. **Milestone 4, complete.** Closures, iterators, and patterns: chains such as `filter` and `map`, `if let` and `while let`, nested, literal, and range patterns, `HashMap`, `as`, `.clone()` and `==` on structs and enums, and getters that return part of their value with no copy. Released as 0.2.0.
5. **Milestone 5a, complete.** Data, configuration, logging, and tests: a built-in `Error`, `json::parse` and `json::stringify`, `env::parse` with `.env`, `log` calls, the attributes `#[rename]`, `#[default]`, `#[skip]`, and `#[test]`, and `varyk test` and `varyk add`. Released as 0.3.0.
6. **Milestone 5b1, complete.** Async: `async fn` and `.await` on a built-in runtime, calls started as tasks, `Task::all` and `Task::all_settled`, and `Shared` for a value many tasks read. Released as 0.4.0.
7. **Milestone 5b2, complete.** Packages: Varyk code uses a Varyk package by its key in `Cargo.toml`, to any depth, and `varyk` builds every package from its `.vr` sources, never running Rust a publisher shipped or a build script. Released as 0.5.0.
8. **Milestone 5b3, complete.** Facades for packages: a `.rs` facade function that reads its result into whatever type the caller names, takes any number of values after its other arguments, or takes only text written in the program, plus `pub use` and `varyk add sql`. Released as 0.6.0, with the database package `varyk-sql`, in [its own repository](https://github.com/Varyk-Lang/varyk-sql), released as 0.1.0.
9. **Milestone 5b4, complete.** HTTP: routes and hooks on an app of the `varyk-http` package, each route checked against its handler by `varyk check`, an optional status on `Error`, `app.request` for tests, and `varyk add http sql`. Released as 0.7.0, with the HTTP package `varyk-http`, in [its own repository](https://github.com/Varyk-Lang/varyk-http), released as 0.1.0: a users API on a database is `varyk init`, `varyk add http sql`, one file, and `varyk run` away.
10. **Milestone 5c, next.** Time, ids, and bytes: a date-time type, a UUID type, and a bytes type, so the users API does not send a date as a string. With it, milestone 5 is met.
11. **Milestone 6.** Tooling and beyond: `varyk fmt`, a language server, more of Rust imported from `.rs` files, and a decision on a native backend.

The [roadmap](/design/roadmap/) has every item; nothing there is a date or a release commitment.

## Install. Write. Run.

Varyk requires a stable Rust toolchain installed through [rustup](https://rustup.rs). Install the compiler, write a package, and run it:

```text
$ cargo install varyk --locked
$ varyk init hello
$ cd hello
$ varyk run
Hello, world!
```

`init` wrote `Cargo.toml`, `.gitignore`, `.dockerignore`, and `src/main.vr`, the program. Continue with [getting started](/learn/getting-started/), which ends with [a first service](/learn/getting-started/#a-first-service) on HTTP and a database, and the [language reference](/learn/reference/). Source and issues are at [github.com/Varyk-Lang/varyk](https://github.com/Varyk-Lang/varyk).
