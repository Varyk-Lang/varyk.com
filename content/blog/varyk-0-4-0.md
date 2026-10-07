+++
title = "Varyk 0.4.0: async functions and tasks"
description = "Milestone 5b1 adds async fn and .await on a built-in multi-threaded runtime, calls that start tasks without a spawn, Task::all and Task::all_settled, Shared for a value many tasks read, and time::sleep."
date = 2026-10-01T19:00:00+02:00
+++

Varyk 0.4.0 is on crates.io. It is milestone 5b1 of the [roadmap](/design/roadmap/), the second part of the batteries for services. Milestone 5a gave Varyk, a language for backend services that compiles to Rust, the data a service works with: JSON, configuration, logging, and tests. Milestone 5b1 adds the way a service waits: `async` and `.await` on a built-in runtime, and tasks that run alongside each other, so that a handler can fetch three things at once instead of one after another.

## What is in it

**`async fn` and `.await`.** `async` before `fn`, on a top-level function or a method, makes a function that can wait, and `.await` after a call runs it and gives its result. Parameters still borrow by default, exactly as in any other function. `async fn main()` runs on a built-in runtime, multi-threaded with one worker per core, and `#[test] async fn` is a test that runs on a runtime of its own. Calling an async function from an ordinary one is an error, with a fix-it that adds `async`.

**Calls that start tasks.** There is no `spawn`. A call to an async function followed by `.await` runs in place; the same call without `.await` starts the function at once and gives a task, a `Task<T>` whose type is worked out from the call and never written, as calling an async function does in JavaScript. Two calls started one after the other really do overlap, and each is waited on later with `.await`:

```varyk
let late = slow(2);
let early = Counter { step: 1 }.next(6);
println!("fast then slow: {} and {}", early.await, late.await);
```

It prints `fast then slow: 7 and 2`: the call started second finishes first.

A task that is dropped is cancelled, so no work outlives the code that started it unless you ask: a `?` that returns early stops the tasks the function had started. `.detach()` lets a task run on with nobody waiting for it. A started call whose task is thrown away, such as a bare `fetch_user(7);`, is an error, so a forgotten `.await` is caught by the compiler instead of turning into background work.

**Waiting on many.** `Task::all` waits for a list of tasks and gives their results in order. When the tasks can fail, it gives the first error to arrive, as JavaScript's `Promise.all` does, and, unlike it, cancels the tasks still running; `Task::all_settled` waits for every task and keeps each outcome, as `Promise.allSettled` does. A list of tasks comes from `vec!` or from a chain: `ids.iter().map(|id| fetch(id)).collect()` starts one task per id.

**Ownership without new syntax.** A started call may outlive the function that made it, so its arguments are given to the task: a number is copied, a value the function owns moves in, and a parameter, which belongs to the caller, needs `.clone()`. That is the one place a value is handed over, so Varyk still has no ownership-transfer syntax, and the function itself still borrows.

**`Shared`.** `Shared::new(config)` puts one struct where many tasks can read it, and `s.clone()` gives each task a handle, not a copy. Fields and methods are reached straight through it, and nothing reached through it can be changed. Underneath it is Rust's `Arc`; ten thousand tasks reading one configuration take ten thousand handles and one value.

**`time::sleep` and async Rust.** `time::sleep(ms)` waits without holding up other tasks. `pub async fn` and async methods in `.rs` modules are imported like any other, and are awaited or started the same way.

**No `Send` or `Pin` to write.** Every type Varyk declares can move between threads, so the bounds Rust needs for a multi-threaded runtime never appear in Varyk code. A value from a `.rs` module that cannot move to or be shared with another thread, such as one holding an `Rc` or a `RefCell`, is reported at the Varyk line that starts the task, as V0901, naming the Rust type.

**New diagnostic codes.** V0211 is `.await` or an async call outside an `async fn`, V0212 an `.await` on something that cannot wait, V0213 a task that would be thrown away, V0214 async functions that call each other in a cycle, V0215 a task used anywhere but where it is made, and V0216 a `Shared` that is not a struct or is written where it cannot go. V0309 is a started call that would change a value the caller can never see, V0310 a change through a `Shared`, V0311 an async function that returns part of a parameter, and V0901 the thread rule above. The [language reference](/learn/reference/#async-functions-and-tasks) has the section, and the [error codes](/learn/reference/#error-codes) the full table.

Three new example programs show it in use, and the [examples](/learn/examples/#tasks) page has them with their output: `tasks`, with calls that overlap, an async method, a detached task, and async tests; `fanout`, which waits on calls that can fail with `Task::all` and `Task::all_settled`; and `shared`, which gives one `Shared` value to ten thousand tasks. This is `fanout.vr`:

```varyk
async fn price(item: i64) -> Result<i64, Error> {
    time::sleep(10 * item as u64).await;
    if item == 3 {
        return Err(Error::new(format!("no price for item {}", item)));
    }
    Ok(item * 12)
}

async fn prices(items: Vec<i64>) -> Result<Vec<i64>, Error> {
    let found = Task::all(items.iter().map(|item| price(item)).collect()).await?;
    Ok(found)
}

async fn main() {
    let good: Vec<i64> = vec![1, 2, 4];
    let bad: Vec<i64> = vec![1, 2, 3];
    match prices(good).await {
        Ok(found) => println!("prices: {} + {} + {}", found[0], found[1], found[2]),
        Err(e) => println!("failed: {}", e.message()),
    }
    match prices(bad).await {
        Ok(found) => println!("prices: {}", found.len()),
        Err(e) => println!("failed: {}", e.message()),
    }

    let items: Vec<i64> = vec![1, 2, 3, 4];
    let outcomes = Task::all_settled(items.iter().map(|item| price(item)).collect()).await;
    let mut n: i64 = 1;
    for outcome in outcomes.iter() {
        match outcome {
            Ok(value) => println!("item {}: {}", n, value),
            Err(e) => println!("item {} failed: {}", n, e.message()),
        }
        n = n + 1;
    }
}
```

It prints:

```text
prices: 12 + 24 + 48
failed: no price for item 3
item 1: 12
item 2: 24
item 3 failed: no price for item 3
item 4: 48
```

## The breaking changes

`async` and `await` were already reserved words, and now they are keywords. `Task` and `Shared` are reserved as `Error` is: they cannot name a struct, an enum, a module, or a `use`, nor a `pub` struct or enum of a `.rs` module. `time` is reserved as `json`, `env`, and `log` are: it cannot name a module, a struct, or an enum, or be brought in with `use`. A program with its own struct named `Task` renames it; the compiler's own `todo` example now calls its struct `Item`.

The three crates, `varyk`, `varyk-syntax`, and `varyk-std`, are released together as 0.4.0. `varyk-std` now holds the runtime too, so a program with an async `main` needs it at the compiler's version: after `cargo install varyk`, run `varyk check`, and it says what to change.

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

Milestone 5b2 is HTTP and the database: an HTTP server on a proven Rust crate, with the application state every handler shares held in a `Shared`, an HTTP client on the same stack, and databases through one API. It meets the bar for all of milestone 5: a users API on a database is `varyk init`, one file, and `varyk run` away, within fifteen minutes of `cargo install varyk`. The [roadmap](/design/roadmap/) has every item, and nothing there is a date.

Varyk is experimental and pre-1.0. Try starting a few tasks in a small service and tell us where it hurts: the [issues](https://github.com/Varyk-Lang/varyk/issues) are the place.
