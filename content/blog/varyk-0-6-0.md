+++
title = "Varyk 0.6.0: facades for packages"
description = "Milestone 5b3 lets a package's .rs facade read a result into whatever type the caller names, take any number of values, and take only text written in the program, and adds pub use and varyk add sql: the compiler side of the database package varyk-sql, whose first release ships with it."
date = 2026-10-04T12:00:00+02:00
+++

Varyk 0.6.0 is on crates.io. It is milestone 5b3 of the [roadmap](/design/roadmap/), the fourth part of the batteries for services. Milestone 5b2 let a Varyk package use another Varyk package by name, and moved the database and HTTP to packages, `varyk-sql` and `varyk-http`. Milestone 5b3 is what such a package needs from the compiler: a `.rs` facade that can say "read the result into whatever type you name" and "take these values, however many", so that `varyk-sql` can be written in Varyk with a thin layer of Rust, and a program that uses it writes no Rust at all. It also gives a facade a parameter that takes only text written in the program, which is what will make a database query built from input a compile error.

`varyk-sql` itself lives in [its own repository](https://github.com/Varyk-Lang/varyk-sql) and is released on its own; its first release, [varyk-sql 0.1.0](/blog/varyk-sql-0-1-0/), ships with this one. This release is the compiler side.

## Why facades

A facade is the `.rs` file in a package through which Varyk code reaches a Rust crate. Until now it could name only concrete types, so a package could not offer "read this row into whatever struct you name", or "take these values, however many": the two things a database package is made of. Milestone 5b3 adds four shapes a facade can declare, one thing a `.vr` file can say, and one convenience for adding a package. Apart from `pub use`, none of it is new Varyk syntax: a Varyk function still has no type parameters, no variadic parameter, and no literal-only parameter. These are shapes the compiler accepts in a `.rs` signature, and rules for calling them.

## What is in it

**A type taken from where the result goes.** A `pub fn` or method of a `.rs` module may have one type parameter, `T: serde::de::DeserializeOwned`, or `varyk_std::serde::de::DeserializeOwned`, which needs no `serde` dependency, and return `Result<T, varyk_std::Error>`, `Result<Option<T>, varyk_std::Error>`, or `Result<Vec<T>, varyk_std::Error>`. At a call, `T` is the type the result is used as, found as for `json::parse`: a `let` with a written type, an argument, a return value, or a field, through `?` and `.await`. `T` is any type `json::parse` reads, with the same attribute checks (V0209), so the facade reads into a struct it has never seen. With nothing to say the type, or for a started call, which has no `.await`, it is V0207, and a Rust type from a `.rs` module or a type of another package is V0210. The generated Rust writes `T` after the name.

**Any number of values.** The last parameter of a facade function may be `Vec<varyk_std::Value>`, which Varyk code writes as zero or more arguments after the others. Each is a `bool`, `string`, `f32`, `f64`, `i8` to `i64`, `u8` to `u32`, or an `Option` of one of those; anything else is V0218, and for a `u64` or `usize` the help writes `as i64`. `Value` holds scalars only, built by the compiler without serde, so no conversion can fail: a design that sent any data type through serde was considered and dropped, because its only ways to handle a failed conversion were a crash, an error on every call, or a silent `Null`, which in a database query is wrong data with no error. Each value is read, not given away, so a name passed stays usable after the call.

**Text written in the program.** A parameter of type `&'static str` takes only a string literal, escapes included, and nothing else. A name, a parameter, or a `format!` there is V0217, "this argument must be text written in the program", and for a `format!` a note says to pass the values after the text instead. The compiler knows nothing about SQL; it knows that this parameter takes only a literal. The check happens at the program's call site, where its input is visible to the compiler, so in `varyk-sql` no input can become part of a query: the values go after the text, and the database binds them.

**Varyk's own `Error`.** A facade may return `varyk_std::Error`, by that full path, as the error of a returned `Result`. Varyk sees it as its own `Error`, so `?` opens it in a function returning `Result<_, Error>`, and `match` reads `e.message()`.

**`pub use`.** A `.vr` file may re-export a function, struct, or enum of its own package, so a library's root can gather what its users need:

```varyk
// src/lib.vr of a package `shelf`
pub mod store;

pub use store::item;
pub use store::Book;
```

A program that uses `shelf` writes `shelf::item(3)` and `shelf::Book`, and may still write `shelf::store::item(3)`. The item must be `pub`, and so must every module on its own path from the root, so the types it names stay visible to its users.

**`varyk add sql`.** `varyk add` gains a shorthand for the official database package: `varyk add sql` runs `cargo add varyk-sql --rename sql`, so code writes `sql::connect`, and any later arguments go to cargo as written (`varyk add sql --features postgres`). One shorthand per call. A call whose first argument is not a shorthand is passed through unchanged, as before. `varyk add sql` works with varyk-sql 0.1.0, released with it.

**A second allocation, named.** Until now the compiler inserted exactly one kind of allocation: a string literal placed into an owned slot. A string passed as a trailing value is the second: the function receiving the values owns them, so `Value::from` copies the text as it hands the value over, the cost of sending it out. `--emit-rust` shows both, and nothing else copies a string's text behind your back.

**New diagnostic codes.** V0217 is an argument to a literal-text parameter that is not a string literal. V0218 is a trailing value of a type that cannot be passed as a value. The [language reference](/learn/reference/#a-facade-for-a-package) has the new section, and the [error codes](/learn/reference/#error-codes) the full table.

There is no new example program this time. The compiler's own test suite proves the facade shapes with a package whose facade is an in-memory store shaped like `varyk-sql`'s, and a program that uses it.

## A facade, worked through

This is the reference's example: a facade shaped like `varyk-sql`'s, with a map in memory in place of a database. The facade is Rust; the reference leaves out the bodies of its two methods, as here:

```rust
// src/kv.rs of a package `store`, with `serde_json` and `varyk-std` in
// its [dependencies]
pub struct Store {
    entries: std::collections::BTreeMap<String, serde_json::Value>,
}

pub fn open() -> Store {
    Store { entries: std::collections::BTreeMap::new() }
}

impl Store {
    pub fn put(
        &mut self,
        key: &'static str,
        values: Vec<varyk_std::Value>,
    ) -> Result<u64, varyk_std::Error> {
        // turns `values` into JSON and stores it under `key`
    }

    pub fn one<T: varyk_std::serde::de::DeserializeOwned>(
        &self,
        key: &'static str,
        values: Vec<varyk_std::Value>,
    ) -> Result<T, varyk_std::Error> {
        // reads the JSON under `key` with `serde_json::from_value`
    }
}
```

The package's root gives the program short names:

```varyk
// src/lib.vr of `store`
pub mod kv;

pub use kv::open;
pub use kv::Store;
```

and the program writes no Rust:

```varyk
// in a program with `store = { path = "../store" }` and `varyk-std` in
// its [dependencies]
struct User {
    id: i64,
    name: string,
}

fn add_ada() -> Result<User, Error> {
    let mut db = store::open();
    let name = "Ada";
    db.put("user/1", 1, name)?;
    db.one("user/1")
}
```

`add_ada` stores `[1, "Ada"]` and reads it back as a `User`. `"user/1"` is text written in the program; `1, name` are the values after it, read and not given away; `User` comes from the return type; and `?` works because the facade returns Varyk's own `Error`. For Rust readers, the last call is written `::store::kv::Store::one::<User>(&db, "user/1", vec![])`.

## What is not yet

A type parameter in a parameter (`&T: Serialize`, for sending a Varyk value out, planned for 5b4), two type parameters, a `where` clause, or another bound; a `u64`, a struct, a `Vec`, or a map as a trailing value. Also not yet: `varyk_std::Error` anywhere but as the error of a returned `Result`; a Varyk function with a literal-only parameter or one taking any number of values, so a `.vr` wrapper cannot pass a query through, and `varyk-sql` puts every call that takes a query in its `.rs` facade; naming `varyk_std::Value` from Varyk code; `pub use` of a module, with braces, globs, or `as`, or of an item of another package; and several shorthands in one `varyk add`. The [reference](/learn/reference/#not-in-milestone-5b3) lists them.

## Upgrading

The three crates, `varyk`, `varyk-syntax`, and `varyk-std`, are released together as 0.6.0; `varyk-std` gains `Value`. Nothing in 0.6.0 breaks an existing package: before 1.0, a new feature now bumps the minor version, as a breaking change does. After `cargo install varyk`, run `varyk check` in a package, and it says what to change: the `varyk-std` line in `Cargo.toml`, or `cargo update -p varyk-std`.

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

First, `varyk-sql` 0.1.0, which ships with this release and has [its own post](/blog/varyk-sql-0-1-0/): SQLite, Postgres, and MySQL on sqlx, with the query text a literal, so a query built from input is a compile error.

Then milestone 5b4, `varyk-http` and the golden path: an HTTP server with an explicit route table, an HTTP client, which brings the other half of the type parameter, for sending a Varyk value out, and the bar for all of milestone 5, a users API on a database that is `varyk init`, `varyk add http sql`, one file, and `varyk run` away. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Try writing a facade for a crate you use, and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
