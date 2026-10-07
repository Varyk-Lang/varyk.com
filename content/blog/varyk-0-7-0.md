+++
title = "Varyk 0.7.0: routes the compiler checks"
description = "Milestone 5b4 is the compiler side of the HTTP package varyk-http: routes and hooks on its app, each route checked against its handler by varyk check, an optional HTTP status on Error, app.request for tests, two new facade shapes, and varyk add http sql. varyk-http 0.1.0 and varyk-sql 0.2.0 ship with it."
date = 2026-10-06T12:00:00+02:00
+++

Varyk 0.7.0 is on crates.io. It is milestone 5b4 of the [roadmap](/design/roadmap/), the fifth part of the batteries for services. Milestone 5b3 gave a package's `.rs` facade what the database package `varyk-sql` needs. Milestone 5b4 does the same for HTTP: a handler is an ordinary `async fn`, a route names it, and `varyk check` checks the route against the handler's parameters before anything is built. With it, a users API on a database is `varyk init`, `varyk add http sql`, one file, and `varyk run` away.

The HTTP package itself, `varyk-http`, lives in [its own repository](https://github.com/Varyk-Lang/varyk-http) and is released on its own; its first release, [varyk-http 0.1.0](/blog/varyk-http-0-1-0/), ships with this one, and has the server's settings, the client, WebSockets, and the rest. This release is the compiler side. varyk-sql 0.2.0 ships with it too: it moves to `varyk-std` 0.7, with nothing else changed, because a program and its packages share one `varyk-std`.

## Why the compiler knows one package

Varyk has no function values, so a route table cannot be an ordinary call that takes a function: some part of it must be known to the compiler. A general mechanism, a facade parameter that takes a function, would need the same knowledge and a mechanism nothing else uses; attributes on handlers would scatter the route table across the program. So the compiler knows `varyk-http` by its crate name, as it knows `varyk-std`. When a build holds that package, under whatever key, the calls that add routes and hooks to its `App` are the compiler's own, and every other call on the app is an ordinary call of an imported struct. A package nobody designed with the compiler can still offer a plain function through the facade shapes every package has.

## What is in it

**Routes and handlers.** This is the language reference's example, after `varyk add http`:

```varyk
struct User {
    id: i64,
    name: string,
}

struct NewUser {
    name: string,
}

struct State {
    users: Vec<User>,
}

async fn get_user(id: i64, state: Shared<State>) -> Option<User> {
    for user in state.users {
        if user.id == id {
            return Some(user.clone());
        }
    }
    None
}

async fn create_user(user: NewUser, state: Shared<State>) -> Result<http::Response, Error> {
    if user.name.is_empty() {
        return Err(http::bad_request("a user needs a name"));
    }
    let created = User { id: state.users.len() as i64 + 1, name: user.name.clone() };
    let mut r = http::Response::json(created);
    r.set_status(201);
    Ok(r)
}

fn build_app(state: Shared<State>) -> http::App {
    let mut app = http::App::new(state.clone());
    app.get("/users/{id}", get_user);
    app.post("/users", create_user);
    app
}
```

and in `async fn main()`:

```varyk
let users = vec![User { id: 1, name: "Ada" }];
let app = build_app(Shared::new(State { users: users }));
let port: u16 = 3000;
if let Err(e) = app.serve(port).await {
    log::error("cannot serve: {}", e);
}
```

`GET /users/1` is answered with a 200 and `{"id":1,"name":"Ada"}`, `GET /users/2` with a 404, and `GET /users/abc` with a 400 saying that the path parameter `id` cannot be read from `abc`; `get_user` is not called for `abc`. `POST /users` with `{"name": "Bo"}` is answered with a 201.

A route is `get`, `post`, `put`, `patch`, or `delete`, with a path written in quotes, whose parts are either written out or a name in braces, `{id}`. Each parameter of the handler gets its value from the request by the first rule that fits: a parameter named after a `{name}` of the path is that part of the path; a `Shared` of the app's state is the state; an `http::Request` is the request itself, to read headers, cookies, or the body; on `post`, `put`, and `patch`, one parameter of a type JSON can hold is the body; and any other integer, `bool`, `string`, or `Option` of one is read by its name from the query string, so `search(prefix: Option<string>, exact: bool)` reads `/search?prefix=A&exact=true`.

Anything that fits no rule is an error at the route, one per problem: a `{name}` with no parameter, a body on `get`, two states, a parameter that gets no value from the request. So renaming a parameter cannot quietly stop it from getting its value. The request is read before the handler runs: a value that is not of its type, a missing query value, or a body that is not JSON of its type is a 400 naming the parameter, and the handler is not called, so inside a handler every parameter is a real value of its type.

**Responses.** What a handler returns is its answer: nothing is a 204, a value JSON can write a 200 with the value as JSON, an `Option` a 200 or, for `None`, a 404, and an `http::Response` is sent as built, for another status, a header, or plain text. A `Result` of one of these with `Error` gives the value's answer for `Ok` and the error's for `Err`.

**Hooks.** `app.before(f)` runs `f` before every request a route matches, `app.before_on(prefix, f)` before the routes under a prefix, and `app.after(f)` on every response the router makes. A `before` hook gives `Ok(true)` to let the request through, `Ok(false)` for a 403, or an `Err`; an `after` hook changes the response through a `mut` parameter:

```varyk
async fn check_key(req: http::Request, state: Shared<State>) -> Result<bool, Error> {
    match req.header("x-key") {
        Some(key) => Ok(key == state.key),
        None => Err(http::unauthorized("an `x-key` header is needed")),
    }
}

async fn stamp(req: http::Request, mut res: http::Response) {
    res.set_header("x-served-by", "users");
}
```

These run with `app.before_on("/admin", check_key);` and `app.after(stamp);` in `build_app`, for a `State` with a `key` field. `before_on` is matched against the path of the route the request matched, as the program wrote it, on whole parts: `"/admin"` covers `/admin/users/{id}`, not `/administrators`, and no spelling of a request's path skips it. Each hook covers every route of the app, wherever its line is. A handler that needs to know who is asking calls a function of the program, `let user = current_user(req, state)?;`; a hook hands it nothing.

**Requests in a test.** `app.request(req).await` sends one request through the app, hooks included, without a port, and gives the response the server would have sent:

```varyk
#[test]
async fn gets_a_user() {
    let users = vec![User { id: 1, name: "Ada" }];
    let app = build_app(Shared::new(State { users: users }));
    let r = app.request(http::Request::new("GET", "/users/1")).await;
    assert_eq(r.status(), 200);
    assert_eq(r.body(), "{\"id\":1,\"name\":\"Ada\"}");
}
```

`build_app` is the function `main` uses too, so a test sends its requests to the same app the service serves. A program that makes an app starts logging in `main` and in every async test, so the message of a 500 is on the screen under `varyk test` too.

**`Error` with a status.** `Error` gains an optional HTTP status. `Error::with_status(status, text)` makes one from Varyk, and `e.status()` reads it, an `Option<u16>`. `varyk-http`'s constructors are Varyk functions over it: `http::bad_request(text)` (400), `http::unauthorized(text)` (401), `http::forbidden(text)` (403), `http::not_found(text)` (404), `http::conflict(text)` (409), and `http::error(status, text)` for any other.

How an error is sent is fixed by the compiler's design, because it is the rule that keeps a service's internals from its clients. An error with a status from 400 to 599 is sent with that status and the body `{"error":"<message>"}`. Any other error, one made by `Error::new` or passed on with `?` from a database query, or one with a status outside 400 to 599, is a 500 with the fixed body `{"error":"internal error"}`, and its message is logged with the request's method and path. A status therefore means the message was written for the client, and only Varyk code sets one: no official package's Rust does. A database message, a file path, or an address inside an error stays in the log.

**Two facade shapes.** A `.rs` facade function may take a value JSON can write, as `&T` with `T: serde::Serialize + ?Sized` (or `varyk_std::serde::Serialize + ?Sized`), the half of the type parameter that milestone 5b3 left for this one. At a call it takes any type `json::stringify` writes, with the same checks, and the value is read, not given away. `varyk-http`'s `Response::json(value)` and its client's `post(url, body)` take their values this way. The reference's in-memory store gains a method of this shape:

```rust
pub fn save<T: varyk_std::serde::Serialize + ?Sized>(
    &mut self,
    key: &'static str,
    value: &T,
) -> Result<u64, varyk_std::Error> {
    // stores `value` under `key` with `serde_json::to_value`
}
```

which Varyk code calls with a struct the facade has never seen, `db.save("user/2", bo)?;`, and `bo` stays usable after the call. A facade may also return a bare `varyk_std::Error`, for a function that makes an error of its own.

**`varyk add http sql`.** `varyk add http` runs `cargo add varyk-http --rename http`, so code writes `http::App`, as `varyk add sql` does for the database. Name several and each runs its own `cargo add`, in order, stopping at the first failure; the full crate names work too (`varyk add varyk-http varyk-sql`). That form takes no other argument; with one official name, any later arguments go to cargo as written (`varyk add sql --features postgres`). A short name with `--rename` is refused, since `http` and `sql` are also names of unrelated crates: write the full name, `varyk add varyk-http --rename web`.

**New diagnostic codes.** V0219 is a route whose path and handler do not fit. V0220 is a handler or hook of the wrong shape: not an async function of the package, a return type outside the list, a hook's parameters out of order. V0221 is a route or hook added to an app that is not a local made with `http::App::new` in the same function, inside a loop, or an assignment to a name holding an app. V0222 is a path or prefix that is not valid, or a method and path already taken. V0407 is a `varyk-http` that does not match this compiler. Others gain a case: V0901 names a route whose handler, or an app whose state, holds a Rust value that cannot go to another thread, and V0214 a route or hook that leads back to the function adding it. The [reference](/learn/reference/#http) has the new HTTP section, and the [error codes](/learn/reference/#error-codes) the full table.

There is no new example program in the compiler's `examples/` this time. Its test suite proves the routes with a stub `varyk-http`, an in-memory router with no network, and a program that uses it; the real package's own tests and its `users` demo run on axum.

## For Rust readers

For each route the compiler writes one small function with concrete types, in the module of the route call. This is the one it writes for `app.get("/users/{id}", get_user)`, from the users API at the top of the home page, as it is in the generated `src/main.rs`:

```rust
#[allow(warnings, arithmetic_overflow, unconditional_panic)]
async fn varyk_route_0(varyk_req: ::http::Request) -> ::http::Response {
    let varyk_0 = match varyk_req.param::<i64>("id") {
        Ok(v) => v,
        Err(r) => return r,
    };
    let varyk_1 = match varyk_req.state::<State>() {
        Ok(v) => v,
        Err(r) => return r,
    };
    match get_user(varyk_0, &varyk_1).await {
        Ok(v) => ::http::respond_option(v),
        Err(e) => ::http::respond_error(e),
    }
}
```

and the route becomes `app.get("/users/{id}", ::http::route(varyk_route_0));`. The program names only the package's items, never axum, so axum's `Handler` trait and its errors never reach a writer; `--emit-rust` shows every adapter, and a rustc error inside one is reported at its route.

## What is not yet

From HTTP: a hook that wraps the handler and calls it itself; groups of routes as values; a handler reading a header or cookie by name without taking `http::Request`; a body read as anything but JSON or a multipart upload; headers for one client request beyond the client's defaults; adding a route to an app a function was given rather than one it made; a handler that is a method, a function of a `.rs` file, or a function of another package; TLS in the server, which is the job of the proxy in front of it; request and response bodies sent in pieces; an OpenAPI document written from the routes; and types for dates, times, UUIDs, and bytes, which come in milestone 5c. From facades: two type parameters, both kinds at once, a `where` clause, or another bound, and `varyk_std::Error` in a parameter or a field. The [reference](/learn/reference/#not-in-milestone-5b4) lists them all.

## Upgrading

The three crates, `varyk`, `varyk-syntax`, and `varyk-std`, are released together as 0.7.0; `varyk-std`'s `Error` gains its status. Nothing in 0.7.0 breaks an existing Varyk program; before 1.0, a new feature bumps the minor version, as a breaking change does. After `cargo install varyk`, run `varyk check` in a package, and it says what to change: the `varyk-std` line in `Cargo.toml`, or `cargo update -p varyk-std`.

A program that uses `varyk-sql` moves to varyk-sql 0.2 at the same time: run `varyk add sql` again, which rewrites the `sql` line to varyk-sql 0.2.0. Until it does, `varyk check` reports V0404 at varyk-sql 0.1's own manifest, not at the program's. The two releases differ only in the `varyk-std` they need: a program and its packages resolve to one `varyk-std`, so varyk-sql 0.2 works with Varyk 0.7, and varyk-sql 0.1 stays with Varyk 0.6. varyk-sql's [README](https://github.com/Varyk-Lang/varyk-sql#versions) has the table.

**Varyk 0.7.1**, on 7 October, is a patch release: `varyk init` also writes a `.dockerignore` with `target` and `.env`, so a container build copies neither, and V0219's note for a path parameter of the wrong type names the types that fit. Nothing else changed. After `cargo install varyk --locked`, `varyk check` in a package made with 0.7.0 asks for `cargo update -p varyk-std`.

**Varyk 0.7.2**, the same day, is another patch release from the same walkthrough. `main` may return a `Result` of something and `Error`: `?` then works in it, and an `Err` is logged, or printed on stderr in a program that does not log, and the program exits with code 1, so a service that cannot start says so to whatever runs it. A `main` that returns nothing works as before. A `Result` used where its value is wanted now suggests `?`; `http::` or `sql::` used before `varyk add http sql` says how to add the package; and text that is not JSON at all, such as a form sent where a JSON body is expected, is reported as "it is not JSON".

## Try it

You need a stable Rust toolchain installed through [rustup](https://rustup.rs).

```text
cargo install varyk
varyk init hello
cd hello
varyk run
```

The [getting started](/learn/getting-started/) page goes from there, and the [language reference](/learn/reference/) describes everything the compiler accepts. For a service, `varyk add http sql` and the [varyk-http post](/blog/varyk-http-0-1-0/#a-first-service) take it from there.

## What is next

First, `varyk-http` 0.1.0, which ships with this release and has [its own post](/blog/varyk-http-0-1-0/): the server on axum with safe defaults, the client, WebSockets, server-sent events, uploads, metrics, and the users API as its demo.

Then milestone 5c, time, ids, and bytes: a date-time type, a UUID type, and a bytes type, so the users API does not send a date as a string, and `varyk-http` can read binary bodies. Milestone 5's bar, the golden path, is met when 5b4 and 5c are done. Beside them, as its own work, an agent evaluation: the examples written by a model from the language reference alone, with pass rates published, before any page claims that agents write Varyk well. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Write a small service with it and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
