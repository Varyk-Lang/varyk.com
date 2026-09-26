+++
title = "Examples"
description = "The twelve example programs from milestones 1 and 2, with their expected output."
weight = 3
+++

These are the twelve programs milestones 1 and 2 must compile and run with the shown output; they are the compiler's integration tests. The first six are milestone 1, the rest milestone 2. They are copied from the [compiler repository](https://github.com/Varyk-Lang/varyk/tree/main/examples), leaving out the `// expected output` comment that heads each file there.

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

`borrowing.vr`, beside the Rust that `varyk build --emit-rust` generates for it (`src/main.rs`). Varyk visibility maps one to one: `pub` stays `pub`, everything else is private.

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
#![allow(
    dead_code,
    unused_variables,
    unused_mut,
    arithmetic_overflow,
    unconditional_panic
)]

struct User {
    name: String,
}

fn rename(user: &mut User) {
    user.name = "Bob".to_string();
}

fn print_user(user: &User) {
    println!("{}", user.name);
}

fn main() {
    let mut user = User {
        name: "Alice".to_string(),
    };
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
