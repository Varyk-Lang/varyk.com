+++
title = "varyk-sql 0.1.0: SQL databases for Varyk"
description = "varyk-sql, the official Varyk package for SQLite, Postgres, and MySQL on sqlx, ships with Varyk 0.6.0: connect, migrate, query into your structs, write in transactions, and test on in-memory SQLite, with the query text literal, so a query built from input does not compile."
date = 2026-10-04T14:00:00+02:00
+++

varyk-sql 0.1.0 is on crates.io. It is the official Varyk package for SQL databases: SQLite, Postgres, and MySQL through sqlx. It covers what an ordinary service does with a database and nothing more: connect, over TLS when the URL asks for it, run migrations, query, write inside transactions, log, and test against an in-memory SQLite database. It lives in [its own repository](https://github.com/Varyk-Lang/varyk-sql), and its [README](https://github.com/Varyk-Lang/varyk-sql#readme) is the full documentation.

varyk-sql ships with [Varyk 0.6.0](/blog/varyk-0-6-0/) because it needs that release's facade features. The package is a `.rs` facade over sqlx, with its tests written in Varyk: a query call reads its rows into whatever struct the caller names, takes the query's values after the text, and takes the text itself only as written in the program. A program that uses it writes no Rust. varyk-sql 0.1 works with Varyk 0.6, and each minor Varyk release is followed by a varyk-sql release, since a program and the package must resolve to one `varyk-std`.

## Adding it

```sh
cargo install varyk
varyk init users
cd users
varyk add sql
```

`varyk add sql` runs `cargo add varyk-sql --rename sql`, so code names the package `sql::`. The default driver is SQLite, compiled from its C source on the first build: that needs a C compiler (Xcode's command-line tools on macOS, `build-essential` on Debian and Ubuntu) and takes a few minutes, once. A server driver is a feature:

```sh
varyk add sql --features postgres                        # Postgres, and SQLite for tests
varyk add sql --no-default-features --features postgres  # Postgres only, skips the SQLite build
varyk add sql --features mysql                           # MySQL, and SQLite for tests
```

## A first service

`src/main.vr`:

```varyk
struct Config {
    database_url: string,
}

struct User {
    id: i64,
    name: string,
}

async fn load() -> Result<Vec<User>, Error> {
    let config: Config = env::parse()?;
    let db = sql::connect(config.database_url).await?;
    db.migrate("migrations").await?;
    db.run("insert into users (name) values (?)", "Ada").await?;
    db.all("select id, name from users").await
}

async fn main() {
    match load().await {
        Ok(users) => {
            for user in users {
                println!("{} {}", user.id, user.name);
            }
        }
        Err(e) => log::error("{}", e.message()),
    }
}
```

`migrations/0001_users.sql`:

```sql
create table users (
    id integer primary key,
    name text not null
);
```

`.env`:

```sh
DATABASE_URL=sqlite::memory:
```

`varyk run` prints `1 Ada`. `main` returns nothing in Varyk, so the work is in `load`, and `main` matches on its result; `all` takes its row type from `load`'s return type. The URL's scheme picks the driver. On Postgres the query writes `$1` for `?`, and the migration differs: `integer primary key` numbers new rows by itself only on SQLite; on Postgres the column is `id integer primary key generated always as identity`, and on MySQL `id integer primary key auto_increment` (see the [README](https://github.com/Varyk-Lang/varyk-sql#a-first-service)).

## The calls

- `sql::connect(url)` gives a pool of up to 10 connections, which waits up to 30 s for a free one; `sql::connect_with(url, max_connections)` sets the count. `db.clone()` is another handle to the same pool, for a started task that needs one.
- On a pool and on a transaction, `one` gives the first row as a `T` or an `Error` when there is none, `first` the first row or `None`, `all` every row, and `run` runs a statement and gives the number of rows it changed. `T` comes from where the result goes, and a struct is read by column name, a field's `#[rename("..")]` included.
- `db.begin()` starts a transaction on one connection of the pool, and `commit` commits it. A transaction dropped without `commit` rolls back, so an early `return` or a `?` undoes it; there is no `rollback` call and no nested transaction.
- `db.migrate("migrations")` applies, in order, every `.sql` file in the folder (not `.down.sql`) not yet recorded in the database's `_sqlx_migrations` table. The files use sqlx's format, so the same folder works with sqlx's own CLI.

```varyk
async fn rename(db: sql::Pool, id: i64, name: string) -> Result<bool, Error> {
    let mut tx = db.begin().await?;
    let changed = tx.run("update users set name = ? where id = ?", name, id).await?;
    if changed != 1 {
        return Err(Error::new("no such user"));
    }
    tx.run("insert into audit (user_id, action) values (?, 'rename')", id).await?;
    tx.commit().await
}
```

## Why the query is literal

The query is literal text: a query built from input does not compile. The package's guard against SQL injection is a compiler check: the query parameter of `one`, `first`, `all`, and `run` is a `&'static str`, which Varyk 0.6.0 lets take only text written in the program, and a name or a `format!` there is V0217, checked at the program's call site. The values go after the text, one per placeholder: `bool`, `string`, floats, integers up to `i64`, and an `Option` of each, where `None` is `NULL`.

```varyk
let user: Option<User> = db.first("select id, name from users where id = ?", id).await?;
```

The placeholders are the database's own, passed through: `?` on SQLite and MySQL, `$1`, `$2` on Postgres. A program that runs on two databases keeps two queries. On SQLite and MySQL the number of values is checked against the number of placeholders before the query runs, and a mismatch is an `Error` naming both, because SQLite would otherwise bind a missing value as `NULL` and ignore an extra one. On Postgres the server rejects too few values and ignores an extra one.

## When something goes wrong

Every failure is an `Error` whose message the package writes, and no call panics.

**A failed statement ends its transaction.** When a statement in a transaction fails in the database, with a duplicate key, a deadlock, or a missing table, the transaction is over: every later query on it is an `Error`, "a statement in this transaction failed; it will roll back", without reaching the database, and `commit` rolls it back and is an `Error`, "the transaction was rolled back: a statement in it failed". To try again, start a new transaction. The rule is the same on all three databases, because each would otherwise behave differently: Postgres aborts the transaction at the failure, and a MySQL deadlock and some SQLite errors end it on the server. An `Error` from reading the rows into `T` does not end the transaction, nor does the package's own count of values on SQLite and MySQL; on Postgres too few values is a database error and does.

**An error on a later row is an error.** `one` and `first` add no `limit`. On Postgres and MySQL both read the rest of the result and drop it, so a statement that fails on a later row is an `Error`, not the first row, and the connection's next statement is not handed that error.

**A failed migration lets go.** On Postgres and MySQL sqlx takes a lock while it applies migrations, so replicas starting together apply each one once. A failed migration is an `Error` naming its version and the database's message, and it releases the lock, so another replica's `migrate` does not wait on it.

**Errors carry no secrets they can avoid.** A connection failure says which step failed and never contains the URL, so a password cannot reach a log that way. A database error keeps the database's own message, which names the constraint or column where there is one, and never includes Postgres's "detail" field, which can hold the row's values. Postgres and MySQL may still quote the offending value in the message itself, a duplicate key for example, so treat these messages as data: log them, and give clients a message of your own.

## Columns and ids

sqlx's `Any` driver, which serves all three databases through one pool, reads booleans, integers, floats, and text; anything else is cast in the query, such as `id::text` for a Postgres `uuid` or `timestamptz`, and `cast(x as char)` for a MySQL `datetime`. Every selected column must be one the driver reads, whether or not `T` has a field for it, so name the columns instead of `select *`. The README has the [table for each database](https://github.com/Varyk-Lang/varyk-sql#column-types).

One case reads wrong without an `Error`: the driver reads MySQL's `smallint unsigned`, `int unsigned`, and `bigint unsigned` as signed, so a large value wraps to a negative number. Read a `smallint unsigned` or an `int unsigned` with `cast(x as signed)` into an `i64`, and a `bigint unsigned` that may reach 2^63 with `cast(x as char)` into a `string`.

Each call on a pool may run on a different connection, so a new row's id is read in the statement that makes it, with `returning` on Postgres and SQLite:

```varyk
// Postgres ($1) and SQLite (?)
let id: i64 = db.one("insert into users (name) values ($1) returning id", name).await?;
```

MySQL has no `returning`, and `select last_insert_id()` on a pool may run on another connection than the insert, so both go in one transaction, which holds one connection:

```varyk
let mut tx = db.begin().await?;
let _added = tx.run("insert into users (name) values (?)", name).await?;
let id: i64 = tx.one("select last_insert_id()").await?;
tx.commit().await?;
```

## Testing

```varyk
async fn count_users() -> Result<i64, Error> {
    let db = sql::connect_with("sqlite::memory:", 1).await?;
    db.migrate("migrations").await?;
    db.run("insert into users (name) values (?)", "Ada").await?;
    db.one("select count(*) from users").await
}

#[test]
async fn adds_a_user() {
    let counted: Result<i64, Error> = count_users().await;
    match counted {
        Ok(n) => assert_eq(n, 1),
        Err(e) => assert_eq(e.message(), "no error"),
    }
}
```

Each `sqlite::memory:` pool is a database of its own, alive while the pool is, so every test starts empty. It is a pool of one connection whatever the count, which keeps the test's queries in order; a query on the pool while a transaction is open waits for that connection and fails after 30 s, so finish the transaction first. Run `varyk test` from the package root, since `migrate("migrations")` and `.env` are read relative to the working directory.

## In production

- **TLS.** sqlx is built with rustls and the webpki root certificates, so TLS works in a minimal container with no CA bundle and no OpenSSL. The URL asks for it: `?sslmode=verify-full` on Postgres and `?ssl-mode=VERIFY_IDENTITY` on MySQL check the certificate and host name; `require` and `REQUIRED` encrypt but accept any certificate.
- **Migrations.** Call `db.migrate("migrations")` at startup, or apply the folder from CI with `sqlx migrate run`. The folder is a path relative to the working directory, so the container holds it beside the executable; the README has a [Dockerfile](https://github.com/Varyk-Lang/varyk-sql#migrations) that builds with `varyk build --release` and copies `migrations/` into a distroless image.
- **Logging.** sqlx reports each statement at debug level through `tracing`, which a Varyk program that logs already sets up: the SQL text and the time it took, never the values. `LOG=debug` turns these lines on.
- **Health.** `db.run("select 1")` is the readiness check: it takes a connection from the pool and asks the database for an answer.

## What is not in it

Pool options beyond `max_connections` (timeouts, idle, lifetime); `rollback` as a call, and savepoints; streaming rows; embedding the migration files in the executable; down migrations; date, uuid, bytes, numeric, JSON, and array columns without a cast; a query spanning two databases' placeholder styles; sqlx's compile-time checked `query!`; Postgres `listen` and `notify`, and `copy`; a `Shared` pool for HTTP handlers, which comes with milestone 5b4; and MongoDB and Redis, which are their own packages, after 5b4.

## What is next

Milestone 5b4 of the [roadmap](/design/roadmap/) is `varyk-http` and the golden path: an HTTP server with an explicit route table, a handler's parameters bound by name to the route and by type to shared state, an HTTP client, and the bar for all of milestone 5, a users API on a database that is `varyk init`, `varyk add http sql`, one file, and `varyk run` away. Nothing there is a date.

Varyk and varyk-sql are experimental and pre-1.0. Point a small service at your database and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk-sql/issues) are the place.
