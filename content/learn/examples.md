+++
title = "Examples"
description = "The six milestone-1 example programs with their expected output."
weight = 3
+++

These are the six programs milestone 1 must compile and run with the shown output; they are the compiler's integration tests. They are copied from the [compiler repository](https://github.com/Varyk-Lang/varyk/tree/main/examples), leaving out the `// expected output` comment that heads each file there.

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
#![allow(dead_code, unused_variables, unused_mut)]

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
