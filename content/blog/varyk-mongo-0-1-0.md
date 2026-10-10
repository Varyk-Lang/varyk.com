+++
title = "varyk-mongo 0.1.0: MongoDB for Varyk"
description = "varyk-mongo, the official Varyk package for MongoDB, over the official mongodb crate: typed documents from your structs, queries in MongoDB's own syntax with the values beside the text, native BSON dates, ids, and binaries, aggregation, indexes, and transactions. With it, varyk-sql 0.4.0 takes $1 on every database, Varyk 0.8.1 adds what the package needs, and 0.8.2 adds varyk add mongo."
date = 2026-10-10T16:30:00+02:00
+++

varyk-mongo 0.1.0 is on crates.io. It is the official MongoDB package for [Varyk](/), a language for backend services that compiles to Rust, over the official `mongodb` crate. It covers what an ordinary service does with MongoDB and nothing more: connect over TLS, read and write typed documents, filter with MongoDB's own operators, aggregate, index, run transactions, and test against a real server. It lives in [its own repository](https://github.com/Varyk-Lang/varyk-mongo), and its [README](https://github.com/Varyk-Lang/varyk-mongo#readme) is the full documentation. varyk-mongo is not affiliated with or endorsed by MongoDB, Inc.

Milestone 5 of the [roadmap](/design/roadmap/), the batteries for services, is complete, and varyk-mongo is the first of [the next packages](/design/roadmap/#the-next-packages) it lists after that, not a milestone of its own. It is written in Varyk, with a `.rs` facade over the driver, and a program that uses it writes no Rust. The compiler side came as two patch releases, Varyk 0.8.1 and 0.8.2, and varyk-sql 0.4.0 came in the same round; all three are below.

## Adding it

```sh
cargo install varyk --locked
varyk init users
cd users
varyk add mongo
```

`varyk add mongo` runs `cargo add varyk-mongo --rename mongo`, so the manifest gets `mongo = { version = "0.1.0", package = "varyk-mongo" }` and code names the package `mongo::`. varyk-mongo 0.1 works with Varyk 0.8.1 and later 0.8 releases, and programs that use it need Rust 1.88 or later, because the `mongodb` crate does; `rustup update` gets it. The compiler and the other packages stay at Rust 1.85.

## A first program

`src/main.vr`:

```varyk
struct Config {
    mongo_url: string,
}

struct User {
    #[rename("_id")]
    id: Uuid,
    email: string,
    name: string,
    created_at: Time,
}

async fn run() -> Result<bool, Error> {
    let config: Config = env::parse()?;
    let db = mongo::connect(config.mongo_url).await?;
    let users = db.collection("users");
    users.create_index("{ email: 1 }", "{ unique: true }").await?;

    users.delete_many("{ email: ? }", "ada@example.com").await?;   // a rerun starts clean
    let ada = User { id: Uuid::new(), email: "ada@example.com", name: "Ada", created_at: Time::now() };
    users.insert(ada).await?;

    let found: Option<User> = users.first("{ email: ? }", "ada@example.com").await?;
    let recent: Vec<User> = users.find("{ created_at: { $gte: ? } }", ada.created_at)
        .sort("{ created_at: -1 }").limit(20).all().await?;
    users.update("{ _id: ? }", "{ $set: { name: ? } }", ada.id, "Ada L.").await?;
    let gone: u64 = users.delete("{ _id: ? }", ada.id).await?;
    println!("{} {} {}", found.is_some(), recent.len(), gone);
    Ok(true)
}

async fn main() -> Result<bool, Error> {
    run().await
}
```

`.env`:

```sh
MONGO_URL=mongodb://127.0.0.1:27017/app
```

With a server running, `varyk run` prints `true 1 1`: Ada was found, she is the one recent user, and one document was deleted. The URL names the one database a service uses, and `mongo::connect` sends `ping`, so a wrong URL, a server that cannot be reached, or a refused password fails at startup rather than at the first request. `#[rename("_id")]` makes `id` the document's `_id`, and `ada` stays usable after `users.insert(ada)`: the call reads the document and does not take it. The same program is in [`demo/users`](https://github.com/Varyk-Lang/varyk-mongo/tree/main/demo/users).

## The calls

On a collection, `one`, `first`, `all`, and `count` read; `find` builds a query that `sort`, `skip`, and `limit` refine, and sends nothing until its `one`, `first`, or `all`; `aggregate` runs a pipeline. `insert` and `insert_many` write documents, `update`, `update_many`, `upsert`, and `replace` change them, `delete` and `delete_many` remove them, and `create_index` makes an index, which does nothing when it exists with the same options, so a service makes its indexes at startup. `T` comes from where the result goes, as in varyk-sql.

```varyk
let user: User = users.one("{ email: ? }", email).await?;
let adults: u64 = users.count("{ age: { $gte: ? } }", 18).await?;
let page: Vec<User> = users.find("{ city: ? }", city)
    .sort("{ name: 1 }").skip(20).limit(10).all().await?;
```

```varyk
let one: u64 = users.update("{ _id: ? }", "{ $set: { name: ? }, $inc: { age: 1 } }", id, "Ada L.").await?;
let added: bool = users.upsert("{ email: ? }", "{ $set: { name: ? }, $setOnInsert: { created_at: ? } }", email, name, Time::now()).await?;
let gone: u64 = users.delete_many("{ city: ? }", "Paris").await?;
```

## The query text

Each text in quotes is MongoDB's own query syntax, as the shell and Compass write it, with `?` where a value goes, and it is a literal string: a query built from input does not compile. The values follow the text, one per `?`, from left to right across all the texts of the call. This is the package's guard against injection: a value is always data, so input cannot become an operator (`{ "$ne": null }`) or a part of the query. The rules that keep input out of the query are each an `Error` naming the place in the text, before anything is sent:

- **A value stands only where MongoDB reads plain data**: anywhere in a filter, and in a top-level `$match` stage of a pipeline, except under `$expr` and `$jsonSchema`; as a value under `$set`, `$setOnInsert`, `$inc`, `$mul`, `$min`, `$max`, `$push`, and `$addToSet`, and in the condition of `$pull`; and as the number of a top-level `$skip` or `$limit` stage. Anywhere else MongoDB reads a string as a field path (`"$passwordHash"`), a variable, or a collection name, so a value from input could read another field or another collection.
- **A `None` cannot be matched.** In a filter, a `$match` stage, or a `$pull` condition it is an `Error`, since `{ reset_token: null }` matches every document without a reset token. Write `null` in the text to match a missing or null field; under `$set` a `None` stores null.
- **A value is never a pattern.** A `?` under `$regex` takes a `string`, and the package escapes every character with a meaning in a pattern, so `users.all("{ name: { $regex: ?, $options: 'i' } }", search)` finds every name that holds `search`, in any case, and nothing else.
- **No JavaScript on the server.** `$where`, `$function`, and `$accumulator` are an `Error` as a key anywhere in a text.
- **`?` is never a key**, a key written twice in one document is an `Error`, and the number of `?`s must be the number of values.

The collection's name is a literal too, so input cannot choose which collection is read.

## Documents and types

A document is written from a struct, and read into one, by field name; `#[rename]`, `#[skip]`, and `#[default]` work as they do for JSON. `Time`, `Uuid`, and `Bytes` are stored as real BSON types, so TTL indexes, date operators, Compass, and other drivers see dates, ids, and binary data as such:

| Varyk | Stored as |
|---|---|
| `Time` | date, in milliseconds |
| `Uuid` | binary subtype 4, which Compass shows as `UUID("…")` |
| `Bytes` | binary |
| `Option` | null for `None`, the value for `Some` |
| `Vec<T>` | array |
| a struct, a `HashMap<string, V>` | embedded document |

BSON dates hold milliseconds, so a `Time`'s microseconds are dropped when it is stored, and a `Time` beside a text is rounded the same way, so a `Time` read back matches its own value. A new collection uses `#[rename("_id")] id: Uuid` and `Uuid::new()`, a new id ordered by time, as an ObjectId is. An existing collection whose `_id`s are ObjectIds reads them into a `string` as 24 hex digits and queries them with `ObjectId(?)`.

## Transactions

```varyk
struct Order {
    #[rename("_id")]
    id: Uuid,
    item: string,
    count: i64,
}

async fn place(db: mongo::Database, order: Order) -> Result<bool, Error> {
    let mut tx = db.begin().await?;
    let orders = tx.collection("orders");
    let stock = tx.collection("stock");
    orders.insert(order).await?;
    let taken = stock.update("{ _id: ?, left: { $gte: ? } }", "{ $inc: { left: ? } }", order.item, order.count, -order.count).await?;
    if taken == 0 {
        return Err(Error::new("out of stock"));   // drops tx: rolls back the insert
    }
    tx.commit().await
}
```

A `Tx` dropped without `commit` rolls back, so an early `return` or a `?` undoes it, as in varyk-sql. When a call inside the transaction fails in MongoDB, every later call on its collections is an `Error` without reaching the server, and `commit` rolls it back. A failure MongoDB calls temporary, a write conflict or an election, ends its message with "run it again", and the README shows a loop that does. Transactions need a replica set or a sharded cluster; Atlas is one. On a single server that is not a replica set, the first call inside a transaction is an `Error` saying so. For development, the README runs [a replica set of one server](https://github.com/Varyk-Lang/varyk-mongo#a-server-for-development) in Docker; the package is tested against MongoDB 8.0.

## When something goes wrong

Every failure is an `Error` whose message the package writes, and no call panics. A connection failure says which step failed and never contains the URL, so a password cannot reach a log that way. A mistake in a text names its place, and a value or a field that cannot be read names the value's number or the field, never the value. A server error keeps the server's message and code, and MongoDB puts the duplicate value in a duplicate-key message, so treat these messages as data: log them, and give clients a message of your own. The driver's command logging stays off, since it would log every command with its values, and the package logs nothing of its own. The driver is built with rustls and the webpki root certificates, so TLS works in a minimal container with no CA bundle and no OpenSSL.

## What is not in it

A client with several databases; cursors; change streams; GridFS; bulk writes; `find_one_and_update` and the other find-and-modify calls; a projection; `distinct`; a transaction call that retries by itself; a pattern taken from input; a list beside the text (`{ _id: { $in: ? } }`: write one `?` for each element); collection names chosen at run time; and Decimal128, regex, and timestamp values beside the text; the [README](https://github.com/Varyk-Lang/varyk-mongo#not-in-this-version) has the full list. A document literal in the language, with values written inline, for MongoDB and JSON, is on the [roadmap](/design/roadmap/#unscheduled) as unscheduled, with no date; until then varyk-mongo builds its documents from structs, and the literal's shape is an open question.

## varyk-sql 0.4.0

[varyk-sql](https://github.com/Varyk-Lang/varyk-sql) 0.4.0 takes `$1`, `$2`, and so on, on every database, SQLite, Postgres, and MySQL, so the same placeholders work on all three:

```varyk
let user: Option<User> = db.first("select id, name from users where id = $1", id).await?;
```

`$2` may come before `$1`, and `$1` may be written twice; it takes the same value each time. `?` still works on SQLite and MySQL, one per value in order, so no query that bound correctly breaks. A `$` inside a string, a quoted name, or a comment is text, not a placeholder. On SQLite and MySQL a query that mixes `?` and `$1`, or numbers its placeholders other than `$1` up to the number of values, each used, is an `Error` before it runs. varyk-sql's [README](https://github.com/Varyk-Lang/varyk-sql#queries) now leads with `$1`, and so do this site's first service and the figure on the home page. No compiler change was needed.

## Varyk 0.8.1 and 0.8.2

Varyk 0.8.1 is what lets varyk-mongo store `Time`, `Uuid`, and `Bytes` as BSON dates and binaries. A facade whose serializer is not human-readable, a binary database format, now gets a `Time` as its Unix microseconds and a `Uuid` as its 16 raw bytes, each in a form named in `varyk_std::serde_names`, and a `Bytes` as raw bytes, so it can store each as a native type. A human-readable serializer, JSON included, still gets the written string, so no output of an existing program changes. The [reference](/learn/reference/#a-facade-for-a-package) has the sentence for facade authors.

Varyk 0.8.2 adds `varyk add mongo`, beside `varyk add http` and `varyk add sql`; a path starting `mongo::` that names nothing gets a note that `varyk add mongo` adds varyk-mongo. It came after varyk-mongo 0.1.0 was on crates.io, so the short name never named a crate anyone else could register first.

## Upgrading

```text
cargo install varyk --locked
```

Then run `varyk check` in a package, and it says what to change, if anything: the `varyk-std` line in `Cargo.toml`, or `cargo update -p varyk-std`. Neither patch release breaks a program. To move to varyk-sql 0.4.0, change the version on the `sql` line in `Cargo.toml` to `"0.4.0"`; `varyk add sql` again does not do it, since `cargo add` keeps the version of a dependency the manifest already lists. varyk-sql 0.3 keeps working with Varyk 0.8.

| varyk | varyk-sql | varyk-http | varyk-mongo |
|---|---|---|---|
| 0.8 | 0.4 or 0.3 | 0.2 | 0.1 (Varyk 0.8.1 or later) |

## What is next

`varyk-redis` is the next package. Milestone 6 of the [roadmap](/design/roadmap/), tooling and beyond, with `varyk fmt` and a language server, is planned but not started, and has no date. Nothing on the roadmap is a date.

Varyk and varyk-mongo are experimental and pre-1.0. Point a small service at MongoDB and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk-mongo/issues) are the place.
