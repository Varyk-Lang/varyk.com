+++
title = "Examples"
description = "The twelve example programs from milestones 1 and 2, and three packages from milestone 3, with their expected output."
weight = 3
+++

These are the twelve programs milestones 1 and 2 must compile and run with the shown output, and three packages from milestone 3; they are the compiler's integration tests. The first six programs are milestone 1, the rest milestone 2, and the packages are under [Packages](#packages). They are copied from the [compiler repository](https://github.com/Varyk-Lang/varyk/tree/main/examples), leaving out the `// expected output` comment that heads each file there.

## Hello

`hello.vr`

```varyk
fn main() {
    println!("Hello, world!");
}
```

Output: `Hello, world!`

## Functions

`functions.vr`

```varyk
fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn main() {
    println!("{}", add(20, 22));
}
```

Output: `42`

## Structs

`structs.vr`

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

Output: `Alice` twice. The second call must compile: read-only parameters borrow.

## Borrowing

`borrowing.vr`, beside the Rust that `varyk build` generates for it (`src/main.rs`, as the compiler writes it; `--emit-rust` prints it, passed through rustfmt when rustfmt is installed). Varyk visibility maps one to one: `pub` stays `pub`, everything else is private.

<div class="panes">
<div>

### borrowing.vr

```varyk
struct User {
    name: string,
}

fn rename(mut user: User) {
    user.name = "Bob";
}

fn print_user(user: User) {
    println!("{}", user.name);
}

fn main() {
    let mut user = User {
        name: "Alice",
    };

    print_user(user);
    rename(user);
    print_user(user);
}
```

</div>
<div>

### generated Rust

```rust
#[allow(warnings, arithmetic_overflow, unconditional_panic)]
struct User {
    name: String,
}

#[allow(warnings, arithmetic_overflow, unconditional_panic)]
fn rename(user: &mut User) {
    user.name = "Bob".to_string();
}

#[allow(warnings, arithmetic_overflow, unconditional_panic)]
fn print_user(user: &User) {
    ::std::println!("{}", user.name);
}

#[allow(warnings, arithmetic_overflow, unconditional_panic)]
fn main() {
    let mut user = User { name: "Alice".to_string() };
    print_user(&user);
    rename(&mut user);
    print_user(&user);
}
```

</div>
</div>

Output: `Alice`, then `Bob`.

## Modules

`modules/main.vr`

```varyk
mod math;

fn main() {
    println!("{}", math::square(7));
}
```

`modules/math.vr`

```varyk
pub fn square(x: i32) -> i32 {
    x * x
}
```

Output: `49`

## Rust interop

`interop/main.vr`

```varyk
mod greet;

fn main() {
    let name = "Varyk";
    println!("{}", greet::hello(name));
}
```

`interop/greet.rs`

```rust
pub fn hello(name: &str) -> String {
    format!("Hello from Rust, {}!", name)
}
```

Output: `Hello from Rust, Varyk!`

## Enums

`enums.vr`

```varyk
enum Shape {
    Circle(f64),
    Rect(f64, f64),
    Point,
}

fn area(shape: Shape) -> f64 {
    match shape {
        Shape::Circle(radius) => 3.14 * radius * radius,
        Shape::Rect(w, h) => w * h,
        Shape::Point => 0.0,
    }
}

fn main() {
    let shapes = vec![Shape::Circle(1.0), Shape::Rect(2.0, 3.0), Shape::Point];
    for shape in shapes {
        println!("{}", area(shape));
    }
}
```

Output: `3.14`, `6`, `0`.

## Errors

`errors.vr`

```varyk
fn parse_answer(text: string) -> Result<i32, string> {
    if text == "42" {
        Ok(42)
    } else {
        Err(format!("not a number: {}", text))
    }
}

fn doubled(text: string) -> Result<i32, string> {
    let value = parse_answer(text)?;
    Ok(value * 2)
}

fn describe(result: Result<i32, string>) -> string {
    match result {
        Ok(value) => format!("{}", value),
        Err(message) => message.clone(),
    }
}

fn first_even(values: Vec<i32>) -> Option<i32> {
    for value in values {
        if value % 2 == 0 {
            return Some(value);
        }
    }
    None
}

fn main() {
    println!("{}", describe(doubled("42")));
    println!("{}", describe(doubled("abc")));
    match first_even(vec![1, 3, 5]) {
        Some(value) => println!("{}", value),
        None => println!("none"),
    }
}
```

Output: `84`, `not a number: abc`, `none`.

## Collections

`collections.vr`

```varyk
fn sum(values: Vec<i32>) -> i32 {
    let mut total = 0;
    for value in values {
        total = total + value;
    }
    total
}

fn main() {
    let mut values: Vec<i32> = Vec::new();
    values.push(10);
    values.push(20);
    values.push(30);
    println!("{}", values.len());
    for i in 0..values.len() {
        println!("{}", values[i]);
    }
    println!("{}", sum(values));
    values.pop();
    println!("{}", values.len());
}
```

Output: `3`, `10`, `20`, `30`, `60`, `2`.

## Methods

`methods.vr`

```varyk
struct Counter {
    count: i32,
}

impl Counter {
    fn new() -> Counter {
        Counter { count: 0 }
    }

    fn add(mut self, by: i32) {
        self.count = self.count + by;
    }

    fn value(self) -> i32 {
        self.count
    }
}

fn main() {
    let mut counter = Counter::new();
    println!("{}", counter.value());
    counter.add(3);
    println!("{}", counter.value());
}
```

Output: `0`, `3`.

## Strings

`strings.vr`

```varyk
struct User {
    name: string,
}

fn name_of(user: User) -> string {
    user.name.clone()
}

fn main() {
    let user = User { name: "Alice" };
    let name = name_of(user);
    println!("{}", name);
    let copy = name.clone();
    println!("{}", copy);
    println!("{}", format!("Hello, {}!", name));
    println!("{}", name.len());
    println!("{}", name == "Alice");
}
```

Output: `Alice`, `Alice`, `Hello, Alice!`, `5`, `true`.

## Todo

`todo/main.vr`

```varyk
mod task;

fn count_done(tasks: Vec<task::Task>) -> usize {
    let mut done: usize = 0;
    for t in tasks {
        if t.is_done() {
            done = done + 1;
        }
    }
    done
}

fn print_all(tasks: Vec<task::Task>) {
    for t in tasks {
        println!("{}", t.label());
    }
}

fn main() {
    let mut tasks: Vec<task::Task> = Vec::new();
    tasks.push(task::Task::new("Buy milk"));
    tasks.push(task::Task::new("Write spec"));
    print_all(tasks);
    tasks[0].complete();
    print_all(tasks);
    println!("{} of {} done", count_done(tasks), tasks.len());
}
```

`todo/task.vr`

```varyk
pub enum Status {
    Open,
    Done,
}

pub struct Task {
    title: string,
    status: Status,
}

impl Task {
    pub fn new(title: string) -> Task {
        Task { title: title.clone(), status: Status::Open }
    }

    pub fn complete(mut self) {
        self.status = Status::Done;
    }

    pub fn is_done(self) -> bool {
        match self.status {
            Status::Done => true,
            Status::Open => false,
        }
    }

    pub fn label(self) -> string {
        let mark = if self.is_done() { "x" } else { " " };
        format!("[{}] {}", mark, self.title)
    }
}
```

Output:

```text
[ ] Buy milk
[ ] Write spec
[x] Buy milk
[ ] Write spec
1 of 2 done
```

## Packages

A package is a directory with a `Cargo.toml` and a `src/main.vr` or `src/lib.vr`. These three are in [`examples/packages/`](https://github.com/Varyk-Lang/varyk/tree/main/examples/packages); each is run from its own directory, with no file named.

### matcher

A program that uses the crate `regex-lite` through a facade: Varyk code never names a crate, so `src/text.rs` wraps it in a struct, methods, and an enum that Varyk imports like its own.

`packages/matcher/Cargo.toml`

```toml
[package]
name = "matcher"
version = "0.1.0"
edition = "2024"

[dependencies]
regex-lite = "0.1"
```

`packages/matcher/src/main.vr`

```varyk
mod text;

fn describe(kind: text::Kind) -> string {
    match kind {
        text::Kind::Word => "word",
        text::Kind::Number(n) => format!("the number {}", n),
    }
}

fn main() {
    let digits = text::Matcher::new("[0-9]+");
    let mut inputs: Vec<string> = Vec::new();
    inputs.push("apple");
    inputs.push("42");
    inputs.push("route 66 or 101");

    let mut with_digits: usize = 0;
    for s in inputs {
        if digits.is_match(s) {
            with_digits = with_digits + 1;
        }
        println!("{}: {}, {} digit runs", s, describe(text::classify(s)), digits.count(s));
    }
    println!("{} of {} contain digits", with_digits, inputs.len());
}
```

`packages/matcher/src/text.rs`

```rust
// A facade: Varyk code never names a crate, so this file wraps
// `regex_lite` in a struct, methods, and an enum Varyk can import.

pub struct Matcher {
    re: regex_lite::Regex,
}

impl Matcher {
    pub fn new(pattern: &str) -> Matcher {
        let re = regex_lite::Regex::new(pattern).expect("the pattern should be a valid regex");
        Matcher { re }
    }

    pub fn is_match(&self, s: &str) -> bool {
        self.re.is_match(s)
    }

    pub fn count(&self, s: &str) -> usize {
        self.re.find_iter(s).count()
    }
}

pub enum Kind {
    Word,
    Number(i32),
}

pub fn classify(s: &str) -> Kind {
    // Deliberately unused: rustc's warning about it shows through
    // `varyk build` at this file and line, as Rust warnings do.
    let trimmed = s.trim();
    match s.parse::<i32>() {
        Ok(n) => Kind::Number(n),
        Err(_) => Kind::Word,
    }
}
```

Output of `varyk run`, after rustc's warning that `trimmed` is unused, which the example does on purpose: a warning in your own `.rs` file shows at your file and line, as rustc words it.

```text
apple: word, 0 digit runs
42: the number 42, 1 digit runs
route 66 or 101: word, 2 digit runs
2 of 3 contain digits
```

### greeting

A program with a nested module, `use`, and a private field, laid out as `varyk init` writes a package. It prints the same under `varyk run` and under plain `cargo run`, which calls `varyk` from `build.rs`, so it needs `varyk` on the `PATH`. `src/main.rs` is the one-line stub `init` writes, and `build.rs` is `init`'s too.

`packages/greeting/src/main.vr`

```varyk
mod text;

use crate::text::case::title;

fn main() {
    let mut greeter = text::Greeter::new("Greetings");
    // `heading` is `pub`; `count` is private to `text`, so reading
    // `greeter.count` here would be an error. `total` reads it instead.
    println!("{}", greeter.heading);
    println!("{}", greeter.greet("Ada"));
    println!("{}", greeter.greet("Grace"));
    println!("{}", title(format!("{} greeted", greeter.total())));
}
```

`packages/greeting/src/text/mod.vr`

```varyk
pub mod case;

pub struct Greeter {
    pub heading: string,
    count: i32,
}

impl Greeter {
    pub fn new(word: string) -> Greeter {
        Greeter { heading: case::title(word), count: 0 }
    }

    pub fn greet(mut self, name: string) -> string {
        self.count = self.count + 1;
        greeting(name)
    }

    pub fn total(self) -> i32 {
        self.count
    }
}

pub fn greeting(name: string) -> string {
    format!("Hello, {}!", name)
}
```

`packages/greeting/src/text/case.vr`

```varyk
// Varyk strings have no case conversion yet, so a title is a word set
// between rules.
pub fn title(word: string) -> string {
    format!("== {} ==", word)
}
```

`packages/greeting/src/main.rs`

```rust
::std::include!(::std::concat!(::std::env!("OUT_DIR"), "/varyk/src/main.rs"));
```

Output:

```text
== Greetings ==
Hello, Ada!
Hello, Grace!
== 2 greeted ==
```

### units

A library, and a plain Rust program that uses it. `varyk publish --assemble-only` assembles `units` into a plain Rust crate at `target/varyk/package/units/`, with the generated `.rs` files, the `.vr` sources beside them, and no `build.rs`, and publishes nothing. The consumer depends on that crate by path and builds with plain `cargo`, with no `varyk` involved.

`packages/units/Cargo.toml`

```toml
[package]
name = "units"
version = "0.1.0"
edition = "2024"
description = "A Varyk example library: lengths in meters"
license = "MIT OR Apache-2.0"

[dependencies]
```

`packages/units/src/lib.vr`

```varyk
pub mod length;
```

`packages/units/src/length.vr`

```varyk
pub struct Meters {
    pub value: i32,
}

pub fn add(a: Meters, b: Meters) -> Meters {
    Meters { value: a.value + b.value }
}
```

`packages/units/consumer/Cargo.toml`

```toml
[package]
name = "consumer"
version = "0.1.0"
edition = "2024"
publish = false

[dependencies]
units = { path = "../target/varyk/package/units" }
```

`packages/units/consumer/src/main.rs`

```rust
// Plain Rust, built with plain cargo: no `varyk` is involved. Varyk
// parameters borrow by default, so `add` takes `&Meters`.
use units::length::{Meters, add};

fn main() {
    let a = Meters { value: 3 };
    let b = Meters { value: 4 };
    println!("{} meters", add(&a, &b).value);
}
```

Output of `cargo run` in `consumer/`, after `varyk publish --assemble-only` in `units/`: `7 meters`.
