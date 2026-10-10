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
varyk check [file.vr]                            check for errors
varyk build [file.vr] [--release] [--emit-rust]  generate and build; print the executable's path
varyk run [file.vr] [--release] [-- args...]     build, then run with the given arguments
varyk test [file.vr]                             build the tests and run them
varyk init [dir] [--lib]                         write a new package
varyk add [cargo add args]                       run cargo add in the package
varyk add http sql mongo                         add the official packages as `http`, `sql`, and `mongo`
varyk add sql [cargo add args]                   add one official package under its short name (`http`, `sql`, `mongo`)
varyk publish [--assemble-only] [-- cargo args]  check, assemble a plain Rust crate, and run
                                                  cargo publish there
```

Without a file, a command works on the package around the current directory (see [a package](#a-package) below). `check` is the fast loop: it reports Varyk diagnostics without building anything, and it runs cargo only to learn which packages the build uses, when a package lists a dependency besides `varyk-std`. `--release` builds with optimizations. `build` transpiles the program into a Rust crate, builds it with cargo, and prints the path of the executable; generated Rust goes under `target/varyk/`, never next to your `.vr` files. `--emit-rust` prints every generated file (`Cargo.toml` and the Rust files) and then builds, so you can see the generated Rust, including the two kinds of allocation Varyk inserts (a string literal placed into an owned slot, and a string passed as a trailing value to a Rust facade function, copied as it is handed over). `init` and `publish` are for packages; the [tools page](/tools/#packages) describes them. Every command accepts `--message-format=json` to emit structured diagnostics instead of the human-readable renderer, including the warnings rustc gives about your `.rs` modules; under `run` and `test`, they go to standard error, since standard output is the program's or the test runner's own. `test` builds the program with its tests and runs them, and `add` runs `cargo add` in the package, with `add http` and `add sql` as the shorthands for the official packages `varyk-http` and `varyk-sql`, and `add http sql` for both; the [reference](/learn/reference/#tests) describes tests.

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

It prints `Hello, world!`. `init` wrote four files: `Cargo.toml` (the manifest, with `edition = "2024"`, a `[[bin]]` table naming `src/main.vr` as the package's root, and `varyk-std`, the crate behind `Error`, `json`, `env`, `log`, tasks, and `Time`, `Uuid`, and `Bytes`, under `[dependencies]`), `.gitignore` and `.dockerignore`, which keep the build folder and `.env` out of git and out of a container build, and `src/main.vr`, the program. Inside the package, commands need no file name. A Varyk package is built by `varyk`, not by plain `cargo build`, since its root is Varyk, not Rust; cargo's other tools, such as `cargo add` and `cargo tree`, still read it. To use another Varyk package, list it under `[dependencies]` and name it by its key: with `units = { path = "../units" }`, Varyk code calls `units::length::add(a, b)`; the [trip](/learn/examples/#trip) example uses two packages this way. To use a Rust crate, add it with `varyk add` or `cargo add` and call it from a `.rs` file in the package, a facade that wraps what the program needs; the [matcher](/learn/examples/#matcher) example wraps `regex-lite` this way. To serve HTTP and use a database, the official packages `varyk-http` and `varyk-sql` do it, as the next section shows; for MongoDB, `varyk add mongo` adds the official [`varyk-mongo`](https://github.com/Varyk-Lang/varyk-mongo#readme) package.

## A first service

A service is a package with the official packages added:

```text
varyk init users
cd users
varyk add http sql
```

`varyk add http sql` adds `varyk-http` as `http` and `varyk-sql` as `sql`. Replace `src/main.vr` with:

```varyk
struct Config {
    #[default(3000)]
    port: u16,
    #[default("127.0.0.1")]
    address: string,
}

struct User {
    id: i64,
    name: string,
}

struct NewUser {
    name: string,
}

struct State {
    db: sql::Pool,
}

async fn list_users(state: Shared<State>) -> Result<Vec<User>, Error> {
    state.db.all("select id, name from users order by id").await
}

async fn create_user(user: NewUser, state: Shared<State>) -> Result<User, Error> {
    let id: i64 = state.db.one("insert into users (name) values ($1) returning id", user.name).await?;
    Ok(User { id: id, name: user.name.clone() })
}

async fn main() -> Result<bool, Error> {
    let config: Config = env::parse()?;
    let db = sql::connect("sqlite::memory:").await?;
    db.migrate("migrations").await?;
    let mut app = http::App::new(Shared::new(State { db: db }));
    app.get("/users", list_users);
    app.post("/users", create_user);
    app.set_address(config.address);
    app.serve(config.port).await
}
```

and add the database's first migration, `migrations/0001_users.sql`:

```sql
create table users (
    id integer primary key,
    name text not null
);
```

`varyk run` builds it and serves on `127.0.0.1:3000`. The first build compiles SQLite from C, which needs a C compiler and takes a few minutes, once:

```text
curl -d '{"name":"Ada"}' 127.0.0.1:3000/users   # {"id":1,"name":"Ada"}
curl 127.0.0.1:3000/users                      # [{"id":1,"name":"Ada"}]
```

`app.get` and `app.post` add the routes, and `varyk check` checks each against its handler before anything builds. A handler's parameters are filled by type: `create_user` takes the JSON body as a `NewUser`, and both handlers read the shared `State`. What a handler returns is the response, here JSON, and an `Err` is an error response whose message is logged, never sent. A body that is not a `NewUser` is a 400 naming the parameter, and the handler never runs. `migrate` applies the files in `migrations` in order, each once; the database is in memory, so it starts empty on every run. `main` returns a `Result`, so `?` works in it: a service that cannot start, on a port already in use say, logs why and exits with code 1, which tells a supervisor or a container platform it failed. `env::parse` reads `PORT` and `ADDRESS` from the environment, or from a `.env` file, with the defaults written on `Config`. In a container, `ADDRESS=0.0.0.0` lets connections from outside it reach the service, and the [Dockerfile in varyk-http's README](https://github.com/Varyk-Lang/varyk-http#production) builds this package as it is. The [varyk-http post](/blog/varyk-http-0-1-0/#a-first-service) grows it into a users API with an API key and a database URL from the environment, and the READMEs of [varyk-http](https://github.com/Varyk-Lang/varyk-http#readme) and [varyk-sql](https://github.com/Varyk-Lang/varyk-sql#readme) have the full documentation, tests included.

## Diagnostics

Every diagnostic has a code (the [reference](/learn/reference/#error-codes) lists them) and, where it can, a fix-it. Rust habits are recognized and corrected: writing `&user` at a call site, `user: &User` in a signature, `String`, or a lifetime annotation each produce a diagnostic that says exactly what to change.
