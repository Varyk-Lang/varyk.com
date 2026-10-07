+++
title = "Varyk 0.8.0: time, ids, and bytes"
description = "Milestone 5c adds three built-in types: Time, a point in time in UTC; Uuid, time-ordered by default; and Bytes, base64 in JSON. varyk-sql 0.3.0 stores them as native columns, and varyk-http 0.2.0 reads times and ids from routes and sends and receives bytes."
date = 2026-10-07
+++

Varyk 0.8.0 is on crates.io. It is milestone 5c of the [roadmap](/design/roadmap/), the last part of the batteries for services. Milestone 5b4 made the golden path: a users API on a database is `varyk init`, `varyk add http sql`, one file, and `varyk run` away. What that API could not say well was when a user was made: a `created_at` had to be a string. Milestone 5c adds three built-in types, `Time`, `Uuid`, and `Bytes`, known without a declaration, as `Error` is.

The two official packages follow it. varyk-sql 0.3.0 drops sqlx's `Any` driver for the concrete SQLite, Postgres, and MySQL pools, so the three types are native columns. varyk-http 0.2.0 reads a `Time` or a `Uuid` from a route, and sends and receives bytes: request and response bodies, uploads, binary WebSocket messages, and the client's bodies. Both need Varyk 0.8, and Varyk 0.8 needs them, since a program and its packages share one `varyk-std`. With them, milestones 5b4 and 5c are done, and milestone 5's bar is met.

## What is in it

**`Time`.** One point in time in UTC, to the microsecond, from the year 0000 to the year 9999. `Time::now()` reads the clock. `Time::from_iso(text)` and `text.parse()` read RFC 3339 text, `2026-10-07T12:00:00Z`, or one with an offset, which is taken to UTC; `Time::from_unix(seconds)` and `Time::from_unix_micros(n)` read a Unix time. `to_iso`, `to_unix`, and `to_unix_micros` go the other way, and `{}` prints what `to_iso` writes. `t.add_seconds(n)` and `t.seconds_since(u)` do the arithmetic, in whole seconds; `+` on a `Time` is an error. Times compare with `==`, `<`, and the rest, a later time being the greater, and a `Vec<Time>` sorts, earliest first. Microseconds are what a Postgres `timestamptz` and a MySQL `datetime(6)` hold, so a time read back from the database equals the one written. No call of `Time` stops the program: each one that can leave the range, `add_seconds` among them, gives a `Result`.

**`Uuid`.** A 128-bit id. `Uuid::new()` makes a version 7, time-ordered, which keeps a primary key index compact; `Uuid::v7()` is the same, and `Uuid::v4()` makes a random one. A version 7 id holds the millisecond it was made in, readable by anyone who has the id, so a service that publishes ids and does not want their creation times known makes them with `Uuid::v4()`. `text.parse()` reads the 36-character form with hyphens, in either case, and `{}` writes it in lower case. Ids compare with `==` and `!=`, and a `Uuid` is a `HashMap` key; ids have no order.

**`Bytes`.** An immutable run of bytes: like a struct, a parameter borrows it, a field owns it, and `let c = b` moves it. `Bytes::from_text` and `Bytes::from_base64` make one, `to_text` and `to_base64` read it, and `len` and `is_empty` measure it. `.clone()` gives a second `Bytes` that shares the first one's buffer, with no byte copied. Bytes have no one printed form, so `{}` on a `Bytes` is an error whose note names `to_text` and `to_base64`, and the `Err` of `from_base64` or `to_text` says what is wrong without repeating the bytes, which can be a whole request body.

**Where they go.** All three go through JSON, where a `Time` is RFC 3339 text, a `Uuid` its text with hyphens, and a `Bytes` standard base64 with padding; through `assert_eq`, and `==` and `.clone()` on a struct that holds them; as the values after a query; and in the signatures of a `.rs` facade. `Time` and `Uuid` also go through `env::parse`, `parse`, `{}`, and a route's path and query parameters, where text that does not read as the type is a 400 and the handler is not called. The compiler's new example, `records`, puts the three in one struct:

```varyk
struct Upload {
    id: Uuid,
    at: Time,
    data: Bytes,
}

fn first_upload() -> Result<Upload, Error> {
    let id: Uuid = "0192F0C4-7A3E-7B5C-9D1E-2F3A4B5C6D7E".parse()?;
    let at = Time::from_iso("2026-10-07T12:00:00+02:00")?;
    Ok(Upload { id: id, at: at, data: Bytes::from_text("hello, world") })
}

// Writes `upload` as JSON, reads it back, and compares the two.
fn report(upload: Upload) -> Result<bool, Error> {
    println!("{} at {}", upload.id, upload.at);
    let expires = upload.at.add_seconds(3600)?;
    println!("expires at {}, {} seconds later", expires, expires.seconds_since(upload.at));
    let text = json::stringify(upload);
    println!("{}", text);
    let back: Upload = json::parse(text)?;
    Ok(back == upload)
}
```

The whole program, on the [examples page](/learn/examples/#records), prints:

```text
0192f0c4-7a3e-7b5c-9d1e-2f3a4b5c6d7e at 2026-10-07T10:00:00Z
expires at 2026-10-07T11:00:00Z, 3600 seconds later
{"id":"0192f0c4-7a3e-7b5c-9d1e-2f3a4b5c6d7e","at":"2026-10-07T10:00:00Z","data":"aGVsbG8sIHdvcmxk"}
read back the same: true
hello, world
aGVsbG8sIHdvcmxk
a new upload has its own id: true
`42` is not a Uuid like 01890a5d-ac96-774b-bcce-b302099a8057
`2026-10-07 12:00` is not a time like 2026-10-07T12:00:00Z
```

**Facades.** A `.rs` function, method, or `pub` field names the three by their full paths: `varyk_std::Time` and `varyk_std::Uuid`, copied as numbers are, `&varyk_std::Bytes` for bytes it only reads, and `varyk_std::Bytes` for bytes it takes. An imported enum may hold them in its variants, which is how varyk-http's WebSocket message carries a binary message.

There is no new diagnostic code: the existing ones gain cases, such as V0113 for a type named `Time`, V0200 for `<` on a `Uuid`, V0203 for `{}` on a `Bytes`, and V0219 for a `Bytes` path parameter. The [reference](/learn/reference/#time-ids-and-bytes) has every call, and the [error codes](/learn/reference/#error-codes) the full table.

## varyk-sql 0.3.0

[varyk-sql](https://github.com/Varyk-Lang/varyk-sql) 0.3.0 is on crates.io. sqlx's `Any` driver, which served the three databases through one pool, has no date or uuid kind, so 0.3 holds one of the concrete pools, chosen from the URL's scheme as before, each behind its cargo feature. `connect`, `Pool`, `Tx`, and their calls are unchanged. The README's first service now stores a time:

```varyk
struct User {
    id: i64,
    name: string,
    created_at: Time,
}

async fn load() -> Result<Vec<User>, Error> {
    let config: Config = env::parse()?;
    let db = sql::connect(config.database_url).await?;
    db.migrate("migrations").await?;
    db.run("insert into users (name, created_at) values (?, ?)", "Ada", Time::now()).await?;
    db.all("select id, name, created_at from users").await
}
```

`Config` reads `DATABASE_URL` from the environment, and `varyk run` prints `1 Ada` and the time the row was added. A `Time`, a `Uuid`, and a `Bytes` each go into a column of their own, and back, with no cast in the query:

| Database | `Time` | `Uuid` | `Bytes` |
|---|---|---|---|
| Postgres | `timestamptz` | `uuid` | `bytea` |
| MySQL | `datetime(6)` | `char(36)` | `blob` |
| SQLite | `text` | `text` | `blob` |

SQLite has no time type, so varyk-sql writes a `Time` there as text of a fixed width, always with six fraction digits, so that `order by` and `<` in SQL put times in the order Varyk does. A `Uuid` is its 36-character text on MySQL and SQLite, readable in a SQL shell as in JSON. A Postgres time is read from its raw microseconds, so `infinity` in a column is an `Error`, not a crash. On Postgres:

```varyk
// Postgres; SQLite takes `$1` as well as `?`
let id: i64 = db.one("insert into users (name, created_at) values ($1, $2) returning id", name, Time::now()).await?;
```

Two things a program had to write go. A `None` on Postgres is now a `NULL` with no type, which takes its type from where the parameter is first used, so `set done = $1` needs no cast; only a parameter first used where nothing gives it a type, as in `$1 is null`, still needs one. And MySQL's unsigned integers, `tinyint`, `mediumint`, and `boolean` columns read with no cast; under `Any`, an unsigned value at or above 2^31 in an `int unsigned` read back as a negative number. A field that refuses a column says so by the column's name, never by its value. The README's [column types](https://github.com/Varyk-Lang/varyk-sql#column-types) have the rest.

## varyk-http 0.2.0

[varyk-http](https://github.com/Varyk-Lang/varyk-http) 0.2.0 is on crates.io. Its first service, and its `users` demo, store `created_at` as a `Time`:

```varyk
async fn create_user(user: NewUser, state: Shared<State>) -> Result<http::Response, Error> {
    if user.name.is_empty() {
        return Err(http::bad_request("a user needs a name"));
    }
    let created_at = Time::now();
    let id: i64 = state.db.one("insert into users (name, created_at) values (?, ?) returning id", user.name, created_at).await?;
    let mut r = http::Response::json(User { id: id, name: user.name.clone(), created_at: created_at });
    r.set_status(201);
    r.set_header("location", format!("/users/{}", id));
    Ok(r)
}
```

with `created_at: Time` on `User` and `created_at text not null` in the migration. Every read gives the time back:

```sh
curl -i -H 'x-api-key: dev-key' -d '{"name":"Ada"}' 127.0.0.1:3000/users
# 201, location: /users/1,
# {"id":1,"name":"Ada","created_at":"2026-10-07T12:00:00.123456Z"}
curl -H 'x-api-key: dev-key' 127.0.0.1:3000/users/1
# {"id":1,"name":"Ada","created_at":"2026-10-07T12:00:00.123456Z"}
curl -H 'x-api-key: dev-key' 127.0.0.1:3000/users/2   # 404 {"error":"not found"}
curl 127.0.0.1:3000/users                             # 401
curl 127.0.0.1:3000/health                            # "ok"
```

**Times and ids in routes.** A path or query parameter may be a `Time` or a `Uuid`, and a query parameter an `Option` of one. A `Time` reads as `Time::from_iso` reads it, and a `Uuid` in its 36-character form; anything else is a 400 naming the parameter. In a query string a `+` reads as a space, as forms encode it, so an offset is sent as `%2B`: `?since=2026-10-07T12:00:00%2B02:00`.

**Bytes in and out.** Each bytes call has a name of its own, beside the text call it matches, since Varyk has no overloading and the server's `Response` is also what the client gives back:

| Call | Gives |
|---|---|
| `req.body_bytes()` | the request body as it came, with no copy |
| `http::Response::bytes(b, content_type)` | a 200 with the body `b`, that `content-type`, and `x-content-type-options: nosniff` |
| `r.body_bytes()` | a response's body with no UTF-8 check, in a test or from the client |
| `part.bytes().await`, `part.content_type()` | an uploaded part's content as it came, and the content type the client declared, not checked |
| `ws.recv_message().await`, `ws.send_bytes(b).await` | WebSocket messages, text or binary |
| `client.post_bytes(url, b, content_type)`, `client.put_bytes(url, b, content_type)` | a request with `b` as its body |
| `req.set_body_bytes(b)` | a body of bytes, for a request sent with `app.request` in a test |

A content type is always written, so no binary body goes out without a declared type. A `Bytes` given to the JSON calls, or returned by a handler, is sent as a JSON string of base64, as any value is. `ws.recv()` stays text, and still closes the connection on a binary message; a handler that takes binary messages asks for them by name:

```varyk
async fn echo(ws: http::WebSocket) -> Result<http::Response, Error> {
    while let Some(message) = ws.recv_message().await? {
        match message {
            http::live::Message::Text(text) => ws.send(text).await?,
            http::live::Message::Binary(b) => ws.send_bytes(b).await?,
        };
    }
    Ok(http::Response::empty())
}
```

The README's [live connections and uploads](https://github.com/Varyk-Lang/varyk-http#live-connections-and-uploads) section has the rest.

## For Rust readers

In the generated Rust the three are `::varyk_std::Time`, `::varyk_std::Uuid`, and `::varyk_std::Bytes`, held by `varyk-std` on the crates `time`, `uuid`, `bytes`, and `base64`. `Time` and `Uuid` are `Copy` and passed by value, as numbers are. `varyk-std` builds every `Bytes` in the `bytes` crate's shared form, so the compiler hands a `Bytes` over as a trailing value by adding one to a reference count, allocating nothing, and axum's request body reaches `req.body_bytes()` without a copy. The compiler still inserts exactly two allocations, a string literal placed into an owned slot and a string passed as a trailing value, and `--emit-rust` shows both.

## What is not yet

From the language: a calendar date, a time of day, a duration type, time zones and local time, formatting a `Time` by a pattern, and a monotonic clock; ordering `Uuid`s, the nil id, and other versions; indexing, slicing, or building `Bytes` piece by piece, and `Bytes` from a `Vec<u8>`; `Bytes` in `env::parse`; `Time` or `Bytes` as a map key; and a handler parameter bound to the raw body. From varyk-sql: `numeric`, `json`, `date`, `time` of day, interval, and array columns without a cast, a `Uuid` written as 16 bytes, and session time zones other than UTC. From varyk-http: a bytes body sent in pieces, a `patch` with a bytes body, and checking a part's declared content type against its content. The [reference](/learn/reference/#not-in-milestone-5c) lists the language's cuts, and the open questions, such as whether Varyk should have a `Date` or a `Duration`, are in the compiler's [open-questions.md](https://github.com/Varyk-Lang/varyk/blob/main/docs/open-questions.md).

## Upgrading

The three crates, `varyk`, `varyk-syntax`, and `varyk-std`, are released together as 0.8.0, and two things in it are breaking. `Time`, `Uuid`, and `Bytes` are now reserved names, as `Error` is: a program that declares a type, an enum, or a module by one of them renames it, and `varyk check` reports V0113 until it does. And `varyk_std::Value`, the type of the values after a facade's other arguments, has three new variants, so a `.rs` facade that matches on a `Value` needs arms for them. After `cargo install varyk --locked`, run `varyk check` in a package, and it says what to change: the `varyk-std` line in `Cargo.toml`, or `cargo update -p varyk-std`.

A program that uses varyk-sql or varyk-http moves to their new releases at the same time: in `Cargo.toml`, change the version on the `http` line to `"0.2.0"` and on the `sql` line to `"0.3.0"`. Running `varyk add http sql` again does not do it, since `cargo add` keeps the version of a dependency the manifest already lists. Until then, `varyk check` reports V0404, since varyk-sql 0.2 and varyk-http 0.1 need `varyk-std` 0.7. varyk-sql's calls are unchanged, and most of the casts 0.2 asked for are no longer needed.

| varyk | varyk-sql | varyk-http |
|---|---|---|
| 0.8 | 0.3 | 0.2 |
| 0.7 | 0.2 | 0.1 |

## Try it

You need a stable Rust toolchain installed through [rustup](https://rustup.rs).

```text
cargo install varyk --locked
varyk init hello
cd hello
varyk run
```

The [getting started](/learn/getting-started/) page goes from there to [a first service](/learn/getting-started/#a-first-service) on HTTP and a database, and the [language reference](/learn/reference/) describes everything the compiler accepts. The READMEs of [varyk-http](https://github.com/Varyk-Lang/varyk-http#readme) and [varyk-sql](https://github.com/Varyk-Lang/varyk-sql#readme) are the full documentation of the packages.

## What is next

Milestone 6 of the [roadmap](/design/roadmap/): tooling and beyond, `varyk fmt`, a language server, nested modules in `.rs` files, Rust tuple and unit structs imported from `.rs` files, `Debug` on imported Rust structs, and a decision on a native backend. Beside it, as their own work, `varyk-mongo` and `varyk-redis`, the next packages, and an agent evaluation: the examples written by a model from the language reference alone, with pass rates published, before any page claims that agents write Varyk well. Nothing there is a date.

Varyk is experimental and pre-1.0. Store a time, an id, or an upload with it, and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
