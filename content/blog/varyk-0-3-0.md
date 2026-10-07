+++
title = "Varyk 0.3.0: data, config, logging, and tests"
description = "Milestone 5a adds varyk-std and a built-in Error, JSON with attributes, configuration from the environment and .env, logging, and varyk test, and makes parse return a Result."
date = 2026-10-01T10:00:00+02:00
+++

Varyk 0.3.0 is on crates.io. It is milestone 5a of the [roadmap](/design/roadmap/), the first part of the batteries for services. Milestone 4 made the everyday code of a service easy to write in Varyk, a language for backend services that compiles to Rust. Milestone 5a adds what a service does with data before it talks to the network: read and write JSON, take its settings from the environment, write logs, and test itself.

## What is in it

**`varyk-std` and `Error`.** A new crate, `varyk-std`, is the one crate Varyk code reaches without a facade; every other crate is still reached through a `.rs` file. It is behind `Error`, a built-in error type with a message: `Error::new("...")` makes one, `e.message()` reads it, and it prints with `{}`. Every standard call that can fail returns `Result<T, Error>`, so `?` works across all of them with no conversions.

**JSON, with attributes.** `json::parse` reads a struct from JSON text and `json::stringify` writes one. Structs, `Option`, `Vec`, `HashMap` with `string` keys, and enums whose variants carry no data all go through. Three attributes adjust the keys: `#[rename("userName")]` on a field or a variant, `#[default(18)]` for a field the text leaves out, and `#[skip]` for a field that is neither read nor written, such as a password hash. Varyk derives serde's traits only for the types a `json` or `env` call reaches, so a program that never calls `json` or `env` has no serde in it, and a type that cannot go through JSON is an error at the call.

**Configuration from the environment.** `let c: Config = env::parse()?;` fills a struct from environment variables, then from a `.env` file in the current directory, then from `#[default]`. A field `database_url` is read from `DATABASE_URL`, and `#[rename]` changes that. A variable that is not set, or does not read as its type, is an `Error` that names it.

**Logging.** `log::debug`, `log::info`, `log::warn`, and `log::error` take a format string and arguments exactly as `println!` does, and write a line to stderr. `LOG` sets the level, `info` when unset, and `LOG_FORMAT=json` writes one JSON object per line instead of text, with no change to the code.

**Tests.** A function marked `#[test]` is a test, in any module, and `assert` and `assert_eq` check results inside one. `varyk test` builds the program with its tests and runs them; `varyk build` and `varyk run` leave them out. A failing check names the Varyk file and line.

**`varyk init`, `varyk add`, and the version check.** `varyk init` now writes `varyk-std` into `Cargo.toml` at the compiler's own version, and `.env` into `.gitignore`, so a local secrets file is never committed. `varyk add` runs `cargo add` in the package with the arguments you give. `varyk check` reads the `varyk-std` line and `Cargo.lock`, and when they do not match the compiler it says so as V0404, with the line to write or `cargo update -p varyk-std` to run.

**New diagnostic codes.** V0112 is an attribute Varyk does not have, or one in a place it cannot go. V0113 is a reserved name. V0114 is a test with parameters or a return type, a call to a test, or `assert` outside a test. V0209 is an attribute value that does not fit, and V0210 a type that cannot go through JSON or the environment. V0404 is the `varyk-std` version check. The [language reference](/learn/reference/#error-codes) has the full table.

Three new example programs and a new package show it in use, and the [examples](/learn/examples/) page has them with their output. The `users` package puts them together: a store of users read from JSON, configuration from a `.env` file, logging, and three tests. This is `json.vr`:

```varyk
enum Role {
    Admin,
    #[rename("member")]
    Member,
}

struct User {
    id: u32,
    #[rename("userName")]
    user_name: string,
    role: Role,
    nickname: Option<string>,
    tags: Vec<string>,
    #[default(18)]
    age: u8,
    #[skip]
    password_hash: Option<string>,
}

fn role_name(role: Role) -> string {
    match role {
        Role::Admin => "admin",
        Role::Member => "member",
    }
}

fn load(body: string) -> Result<User, Error> {
    let u: User = json::parse(body)?;
    Ok(u)
}

fn main() {
    let text = "{\"id\": 7, \"userName\": \"ann\", \"role\": \"member\", \"tags\": [\"a\", \"b\"], \"password_hash\": \"x\"}";
    match load(text) {
        Ok(u) => {
            println!("{} {} {}", u.id, u.user_name, role_name(u.role));
            println!("{} tags, age {}, nickname: {}", u.tags.len(), u.age, u.nickname.is_some());
            println!("{}", json::stringify(u));
        }
        Err(e) => println!("error: {}", e),
    }
    let bad = "{\"id\": 1, \"userName\": \"bo\", \"role\": \"Admin\", \"tags\": [], \"age\": 300}";
    match load(bad) {
        Ok(u) => println!("{}", u.id),
        Err(e) => println!("error: {}", e),
    }
}
```

It prints:

```text
7 ann member
2 tags, age 18, nickname: false
{"id":7,"userName":"ann","role":"member","nickname":null,"tags":["a","b"],"age":18}
error: invalid value: integer `300`, expected u8 at line 1 column 67
```

## The breaking changes

`s.parse()` returns `Result<T, Error>` instead of `Option<T>`, so `?` works on it in a function that returns `Result<_, Error>`, and the error names the text. Code that wanted the old `Option` writes two statements, since the expected type does not reach a method's receiver:

```varyk
let r: Result<i32, Error> = text.parse();
let n = r.ok();
```

The new names are reserved: `json`, `env`, and `log` cannot name a module, a struct, an enum, or a `use`; `Error` cannot name a struct, an enum, a module, or a `use`; `assert` and `assert_eq` cannot name a function; and no function, method, struct, enum, module, or `use` name may start with `varyk_`, which is kept for what the compiler adds to the Rust it writes. Local variables and fields may still use any of these names.

The three crates, `varyk`, `varyk-syntax`, and `varyk-std`, are released together as 0.3.0. A package that uses `varyk-std` needs it in `[dependencies]` at the compiler's version: after `cargo install varyk`, run `varyk check`, and it says what to change.

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

Milestone 5 is now three milestones. Milestone 5b1 is `async`/`await` on a built-in runtime and `spawn`, gated on two open questions, the runtime shape and ownership-transfer syntax. Milestone 5b2 is HTTP and the database: an HTTP server and client on one stack, and databases through one API. The bar for all three is one golden path: a users API on a database is `varyk init`, one file, and `varyk run` away, within fifteen minutes of `cargo install varyk`. It is met at the end of 5b2. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Try writing one small service and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
