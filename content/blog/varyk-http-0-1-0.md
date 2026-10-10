+++
title = "varyk-http 0.1.0: HTTP for Varyk"
description = "varyk-http, the official Varyk package for HTTP, ships with Varyk 0.7.0: a server on axum and tower-http whose routes the compiler checks, safe defaults, errors that never leak, hooks, WebSockets, server-sent events, uploads, a client on reqwest, metrics, and tests without a port."
date = 2026-10-06T14:00:00+02:00
+++

varyk-http 0.1.0 is on crates.io. It is the official Varyk package for HTTP: a server on [axum](https://github.com/tokio-rs/axum) and [tower-http](https://github.com/tower-rs/tower-http), and a client on [reqwest](https://github.com/seanmonstar/reqwest). It covers what an ordinary production API needs and nothing more: routes the compiler checks, hooks, safe defaults, errors that never leak, WebSockets, server-sent events, uploads, a client, metrics, and tests without a port. It lives in [its own repository](https://github.com/Varyk-Lang/varyk-http), and its [README](https://github.com/Varyk-Lang/varyk-http#readme) is the full documentation.

varyk-http ships with [Varyk 0.7.0](/blog/varyk-0-7-0/) because it needs that release's compiler side: the compiler knows this one package by name, checks every route against its handler, and writes the small adapter that calls the package for each route. The package is a `.rs` facade over axum, tower-http, and reqwest, with its error constructors and its tests written in Varyk; the generated program never names axum, and the first service below writes no Rust. varyk-http 0.1 works with Varyk 0.7, and each minor Varyk release is followed by a varyk-http release, since a program and its packages must resolve to one `varyk-std`. [varyk-sql](https://github.com/Varyk-Lang/varyk-sql) 0.2.0 ships alongside for the same reason, with nothing else changed.

## Adding it

```sh
cargo install varyk --version '^0.7' --locked
varyk init users
cd users
varyk add http sql
```

`varyk add http sql` adds varyk-http as `http` and varyk-sql as `sql`, so code writes `http::App` and `sql::connect`. varyk-sql's default driver, SQLite, is compiled from C on the first build, which needs a C compiler; its [README](https://github.com/Varyk-Lang/varyk-sql) has the rest.

## A first service

A users API on a database, behind an API key, in one file. `src/main.vr`:

```varyk
struct Config {
    database_url: string,
    api_key: string,
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
    api_key: string,
}

async fn list_users(state: Shared<State>) -> Result<Vec<User>, Error> {
    state.db.all("select id, name from users order by id").await
}

async fn get_user(id: i64, state: Shared<State>) -> Result<Option<User>, Error> {
    state.db.first("select id, name from users where id = ?", id).await
}

async fn create_user(user: NewUser, state: Shared<State>) -> Result<http::Response, Error> {
    if user.name.is_empty() {
        return Err(http::bad_request("a user needs a name"));
    }
    let id: i64 = state.db.one("insert into users (name) values (?) returning id", user.name).await?;
    let mut r = http::Response::json(User { id: id, name: user.name.clone() });
    r.set_status(201);
    r.set_header("location", format!("/users/{}", id));
    Ok(r)
}

async fn delete_user(id: i64, state: Shared<State>) -> Result<http::Response, Error> {
    let deleted = state.db.run("delete from users where id = ?", id).await?;
    if deleted == 0 {
        return Err(http::not_found("no such user"));
    }
    Ok(http::Response::empty())
}

async fn health(state: Shared<State>) -> Result<string, Error> {
    let _ok = state.db.run("select 1").await?;
    Ok("ok")
}

async fn check_key(req: http::Request, state: Shared<State>) -> Result<bool, Error> {
    match req.header("x-api-key") {
        Some(key) => Ok(key == state.api_key),
        None => Err(http::unauthorized("an x-api-key header is needed")),
    }
}

async fn open_db(url: string) -> Result<sql::Pool, Error> {
    let db = sql::connect(url).await?;
    db.migrate("migrations").await?;
    Ok(db)
}

fn build_app(state: Shared<State>) -> http::App {
    let mut app = http::App::new(state.clone());
    app.get("/health", health);
    app.get("/users", list_users);
    app.get("/users/{id}", get_user);
    app.post("/users", create_user);
    app.delete("/users/{id}", delete_user);
    app.before_on("/users", check_key);
    app
}

async fn start() -> Result<bool, Error> {
    let config: Config = env::parse()?;
    let db = open_db(config.database_url).await?;
    let mut app = build_app(Shared::new(State { db: db, api_key: config.api_key.clone() }));
    app.set_address(config.address);
    app.serve(config.port).await
}

async fn main() {
    if let Err(e) = start().await {
        log::error("{}", e);
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
API_KEY=dev-key
```

`varyk run` serves on `127.0.0.1:3000`:

```sh
curl -i -H 'x-api-key: dev-key' -d '{"name":"Ada"}' 127.0.0.1:3000/users
# 201, location: /users/1, {"id":1,"name":"Ada"}
curl -H 'x-api-key: dev-key' 127.0.0.1:3000/users/1   # {"id":1,"name":"Ada"}
curl -H 'x-api-key: dev-key' 127.0.0.1:3000/users/2   # 404 {"error":"not found"}
curl 127.0.0.1:3000/users                             # 401
curl 127.0.0.1:3000/health                            # "ok"
```

The same program, with its tests, is the package's [`demo/users`](https://github.com/Varyk-Lang/varyk-http/tree/main/demo/users). A handler is an ordinary `async fn`. Its parameters are bound by name to the path (`{id}`) and the query string, and by type to the JSON body, the shared state, and the request; its return value is the response: a value is JSON with 200, `None` is 404, nothing is 204, and an `http::Response` is sent as built. `varyk check` checks every route against its handler before anything builds. A path or query value that does not parse as its type, a missing query value, and a body that is not JSON of its type are each a 400 naming the parameter, and the handler is not called. The [Varyk 0.7.0 post](/blog/varyk-0-7-0/#what-is-in-it) and the [language reference](/learn/reference/#http) have the rules.

## Safe defaults

The settings are calls on the app before `serve`:

| Call | Default | Meaning |
|---|---|---|
| `app.set_address(addr)` | `"127.0.0.1"` | the IP address to listen on; `"0.0.0.0"` in a container |
| `app.set_body_limit(bytes)` | 2 MiB | a larger request body is a 413 |
| `app.set_timeout(ms)` | 30 000 | a request that takes longer is a 503 |
| `app.set_shutdown_grace(ms)` | 30 000 | on SIGTERM or ctrl-c, how long requests in flight have to finish |
| `app.set_idle_timeout(ms)` | 75 000 | how long a connection may wait for a request's headers, idle between kept-alive requests or still sending them, before it is closed |
| `app.set_max_in_flight(n)` | none | beyond `n` requests at once, a 503 `{"error":"server busy"}` |
| `app.allow_origin(origin)` | none | adds one CORS origin; `"*"` allows any |
| `app.compress()` | off | gzip for responses whose client accepts it |
| `app.metrics(path)` | off | Prometheus text at `path` |

The server listens on `127.0.0.1` until the program sets an address, so a service run on a laptop is not open to its network; `serve` says so as it starts, `listening on http://127.0.0.1:3000 (set_address("0.0.0.0") to accept outside connections)`. A body limit, a request timeout, and an idle timeout are on without being asked; each bounds one request or connection, not the service as a whole, and the idle timeout means a client that sends its headers slowly or not at all cannot hold connections open. There is no limit on requests in flight unless `set_max_in_flight` sets one, since memory is the platform's to manage; that limit is load shedding, a 503 beyond a number of requests at once, for a service that wants it. CORS is off until an origin is allowed, and once on it never allows credentials. Compression is off too: compressing a secret beside text an attacker chose leaks it through the length.

A setting with a value that cannot work, a limit of 0 or an address that is not an IP address, makes `serve` an `Err` naming the setting, and every `app.request` a 500, rather than a panic. On SIGTERM or ctrl-c, `serve` stops accepting, gives requests in flight the shutdown grace, and gives `Ok(true)`.

## Nothing internal reaches a client

| Call | Status |
|---|---|
| `http::bad_request(text)` | 400 |
| `http::unauthorized(text)` | 401 |
| `http::forbidden(text)` | 403 |
| `http::not_found(text)` | 404 |
| `http::conflict(text)` | 409 |
| `http::error(status, text)` | `status` |

An `Err` from a handler or a `before` hook with a status from 400 to 599 is sent with that status and `{"error":"<text>"}`: its text is written for the client. Any other error, one passed on with `?` from a database call, say, or one with a status outside 400 to 599, is a 500 with the fixed body `{"error":"internal error"}`, and its message is logged with the method and path. A panic in a handler or a hook is the same fixed 500. So a database message, a file path, or a secret inside an error stays in the log.

The package keeps input out of places it could do harm. `Response::file(dir, name)` serves a file from a folder and refuses a name that is absolute, has an empty, `.`, or `..` part, has a part starting with `.`, or leads outside the folder through a link, as a 404, as a missing file is, so a client cannot tell them apart. A header that is not valid HTTP, and a cookie name or value that could add attributes, make the response a 500 with the reason logged. `set_cookie` writes `HttpOnly`, `Secure`, and `SameSite=Lax`. Log lines carry the path still percent-encoded and without its query string, and a name or message a client chose is written escaped, so it cannot start a log line of its own.

## Hooks and auth

```varyk
async fn check_key(req: http::Request, state: Shared<State>) -> Result<bool, Error> {
    match req.header("x-api-key") {
        Some(key) => Ok(key == state.api_key),
        None => Err(http::unauthorized("an x-api-key header is needed")),
    }
}

async fn stamp(req: http::Request, mut res: http::Response) {
    res.set_header("x-served-by", "users");
}
```

`app.before(f)` runs `f` before every route, `app.before_on("/admin", f)` before the routes whose path, as the program wrote it, is `/admin` or starts with `/admin/` (not `/administrators`), and `app.after(f)` on every response the router makes. Each hook covers every route, wherever its line is, and hooks run in the order they were added. A `before` hook gives `Ok(true)` to let the request through, `Ok(false)` for a 403 `{"error":"forbidden"}`, or an `Err`, sent as above. Because `before_on` tests the route the request matched, no spelling of a path reaches an `/admin` route without its hook. `before` hooks run after routing, so a request no route matches is a 404 without running any; a client can therefore tell a route that exists (refused by its hook, 401 or 403) from one that does not (404).

A handler that needs the user calls a function of the program, `let user = current_user(req, state)?;`. The first service compares its key with `==`, which is not constant time; a production check compares in constant time in a facade function of the program or uses bearer tokens. The README has a Rust facade of the program over [jsonwebtoken](https://crates.io/crates/jsonwebtoken) and [argon2](https://crates.io/crates/argon2) for tokens and password hashes, and the Varyk function that gives a refused token its 401. The package checks neither a body's `content-type` nor a request's `Origin`: against a cross-site request, the defence is the `SameSite=Lax` cookie `set_cookie` writes, and a service that takes cookies some other way checks `Origin` in a `before` hook.

## WebSockets, server-sent events, and uploads

A handler takes a WebSocket, an event stream, or a multipart form as a parameter, bound by type as the request is. A live handler returns nothing, or `Result<http::Response, Error>` so that `?` works on its calls; the response it returns is ignored, since the connection was already answered, and an `Err` is logged. The connection closes when the handler returns.

```varyk
async fn chat(ws: http::WebSocket) -> Result<http::Response, Error> {
    while let Some(text) = ws.recv().await? {
        ws.send(format!("you said: {}", text)).await?;
    }
    Ok(http::Response::empty())
}
```

with `app.get("/chat", chat);`. Messages are text, and the package answers pings. A client's fault, a binary message, a malformed one, or one larger than the body limit, closes the connection with its code and makes `recv` give `None`.

```varyk
async fn ticks(events: http::Sse) -> Result<http::Response, Error> {
    let mut i = 0;
    while i < 10 {
        events.send_event("tick", format!("{}", i)).await?;
        time::sleep(1000).await;
        i = i + 1;
    }
    Ok(http::Response::empty())
}
```

`events.send(text)` sends one `data:` event and `events.send_event(name, text)` one with a name; the package sends a comment every 15 seconds while the handler is quiet, so proxies keep the connection open.

```varyk
async fn upload_avatar(id: i64, form: http::Multipart) -> Result<http::Response, Error> {
    while let Some(part) = form.next().await? {
        if part.name() == "avatar" {
            let _written = part.save_to("uploads", format!("{}.png", id)).await?;
        }
    }
    Ok(http::Response::empty())
}
```

with `app.post("/users/{id}/avatar", upload_avatar);`. Save an upload under a name and extension the program chooses, as here, never under `part.file_name()`, which is whatever the client sent. `save_to` refuses a name by the rule of `Response::file` and writes to a temporary file first, so a failed upload leaves nothing behind. What the handler reads counts against the body limit, and what it leaves unread is never read. Messages and parts are text and files until milestone 5c brings a bytes type.

## The client, metrics, and tests

```varyk
struct Forecast {
    summary: string,
}

struct State {
    client: http::Client,
}

async fn forecast(state: Shared<State>) -> Result<Forecast, Error> {
    let r = state.client.get("https://weather.example/today").await?;
    if r.status() != 200 {
        return Err(http::error(502, "the weather service did not answer"));
    }
    r.read_json()
}

fn weather_client(key: string) -> http::Client {
    let mut client = http::Client::new();
    client.set_header("authorization", key);
    client
}
```

`client.get(url)` and `client.delete(url)`, and `post`, `put`, and `patch` with a body sent as JSON, each give `Result<http::Response, Error>`. A response of any status is `Ok`; an `Err` is a response that could not be had, and its message names the scheme and host, never the path or query, which may hold a token. Redirects are followed only to the same scheme, host, and port, so a default header such as an API key never goes to a host the program did not name. The client uses rustls with built-in root certificates, so it works in a minimal container, with a 30-second timeout and a 10 MiB body limit by default. Make one at startup and keep it in the state; `client.clone()` shares its connections.

`app.metrics("/metrics")` serves Prometheus text: `http_requests_total` by method, route, and status, and `http_request_duration_seconds`, a histogram by method and route. The route label is the route's pattern, `/users/{id}`, never the path a client sent. The metrics path is open to anyone who can reach the service, so a service that listens beyond `127.0.0.1` keeps it from the public at its proxy.

`app.request(req).await` runs one request through the same router, settings, and hooks as `serve`, without a port, under `varyk test`:

```varyk
async fn test_app() -> Result<http::App, Error> {
    let db = sql::connect_with("sqlite::memory:", 1).await?;
    db.migrate("migrations").await?;
    Ok(build_app(Shared::new(State { db: db, api_key: "test-key" })))
}

#[test]
async fn creates_a_user() {
    let app = match test_app().await {
        Ok(app) => app,
        Err(e) => {
            assert_eq(e.message(), "no error");
            return;
        }
    };
    let mut req = http::Request::new("POST", "/users");
    req.set_header("x-api-key", "test-key");
    req.set_body("{\"name\":\"Ada\"}");
    let r = app.request(req).await;
    assert_eq(r.status(), 201);
    assert_eq(r.header("location"), Some("/users/1"));
}
```

Each `sqlite::memory:` pool is a database of its own, so every test starts empty. An event stream's events are collected whole once its handler returns, so `r.body()` gives them; a WebSocket route answers a 400, since no request `app.request` sends is an upgrade. Run `varyk test` from the package's folder, where `migrations` and `.env` are.

## In production

- **Configuration.** The port, the address, and secrets come from the environment with `env::parse`, as the first service does: in development from `.env`, which `varyk init` keeps out of git.
- **Containers.** In a container the service listens on `0.0.0.0`: the first service reads `ADDRESS` and calls `set_address` with it. The README has a [Dockerfile](https://github.com/Varyk-Lang/varyk-http#production) that builds with `varyk build --release` on Debian 12 and copies the executable and `migrations/` into a distroless image with `ADDRESS=0.0.0.0`. On SIGTERM the service gives requests in flight the shutdown grace.
- **Idle connections.** The service closes a connection that has sent no request for 75 seconds, so a load balancer or proxy in front must close its idle connections sooner, or an occasional request fails with a 502. AWS's Application Load Balancer and nginx's upstream keep-alive default to 60 seconds, which is sooner; behind Google Cloud's Application Load Balancers, which keep idle connections for 600 seconds, set `app.set_idle_timeout(620000);`.
- **TLS** is the proxy's or the load balancer's: the package serves plain HTTP/1.1. So are security headers and rate limiting per client.
- **Health.** A `get("/health", health)` route whose handler runs `db.run("select 1")`, outside any `before_on` prefix, so the platform needs no key.
- **Logging.** One line per request after its response, `GET /users/1 200 3ms`, a 500's message at error level, and startup and shutdown at info level, through Varyk's `log`, which a program with an `http::App` starts by itself.

## What is not in it

HTTP/2 and TLS in the server, which are the proxy's; binary WebSocket messages and bytes bodies, until milestone 5c brings a bytes type; streaming request and response bodies beyond `Response::file` and `save_to`; per-request client headers and a request builder; client cookies and proxies (the client ignores `HTTP_PROXY` and always connects directly); route groups and a wrapping hook; OpenTelemetry; rate limiting per client; serving a whole folder of static files; and templates.

## What is next

Milestone 5c of the [roadmap](/design/roadmap/): a date-time type, a UUID type, and a bytes type, which lets varyk-http read uploads and binary bodies, so the users API does not send a date as a string. Milestone 5's bar, a users API on a database that is `varyk init`, `varyk add http sql`, one file, and `varyk run` away, is met when 5b4 and 5c are done. After 5b4, `varyk-mongo` and `varyk-redis` are the next packages. Nothing there is a date.

Varyk and varyk-http are experimental and pre-1.0. Put a small service behind it and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk-http/issues) are the place.
