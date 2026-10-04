+++
title = "Examples"
description = "The example programs from milestones 1, 2, 4, 5a, and 5b1, and the packages from milestones 3, 5a, and 5b2, with their expected output."
weight = 3
+++

These are the twenty-four programs milestones 1, 2, 4, 5a, and 5b1 must compile and run with the shown output, and six packages from milestones 3, 5a, and 5b2; they are the compiler's integration tests. The first six programs are milestone 1, the next six milestone 2, the six from [Iterators](#iterators) on milestone 4, the three from [JSON](#json) on milestone 5a, and the three from [Tasks](#tasks) on milestone 5b1; the packages are under [Packages](#packages). Milestone 4 also updated three earlier ones: `todo` counts with a chain and reads its title through a getter, `interop` imports a Rust function that returns part of its argument, and `matcher` compares an imported Rust enum with `==`. Milestone 5a updated `readings` and `text`, because `parse` now gives a `Result`, and milestone 5b1 renamed `todo`'s `Task` struct to `Item`, because `Task` is now a built-in type. Milestone 5b2 added the packages `route` and `trip`, made `matcher`'s facade report a bad pattern instead of stopping the program, and named each package's `.vr` root in its `Cargo.toml`, in place of the `build.rs` and stub `varyk init` used to write. They are copied from the [compiler repository](https://github.com/Varyk-Lang/varyk/tree/main/examples), leaving out the `// expected output` comment that heads each file there.

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
#[derive(Clone, PartialEq)]
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
    println!("{}", greet::first_word("Hello from Rust"));
}
```

`interop/greet.rs`

```rust
pub fn hello(name: &str) -> String {
    format!("Hello from Rust, {}!", name)
}

pub fn first_word(s: &str) -> &str {
    match s.find(' ') {
        Some(i) => &s[..i],
        None => s,
    }
}
```

Output: `Hello from Rust, Varyk!`, then `Hello`.

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

fn count_done(tasks: Vec<task::Item>) -> usize {
    tasks.iter().filter(|t| t.is_done()).count()
}

fn print_all(tasks: Vec<task::Item>) {
    for t in tasks {
        println!("{}", t.label());
    }
}

fn main() {
    let mut tasks: Vec<task::Item> = Vec::new();
    tasks.push(task::Item::new("Buy milk"));
    tasks.push(task::Item::new("Write spec"));
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

pub struct Item {
    title: string,
    status: Status,
}

impl Item {
    pub fn new(title: string) -> Item {
        Item { title: title.clone(), status: Status::Open }
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

    pub fn title(self) -> string {
        self.title
    }

    pub fn label(self) -> string {
        let mark = if self.is_done() { "x" } else { " " };
        format!("[{}] {}", mark, self.title())
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

## Iterators

Chains over a `Vec` and over the pieces of a string, with closures as the arguments of `filter` and `map`.

`iterators.vr`

```varyk
fn main() {
    let numbers = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    println!("{}", numbers.iter().sum());
    println!("{}", numbers.iter().filter(|n| n % 3 == 0).count());
    println!("{}", numbers.iter().any(|n| n > 9));
    let doubled: Vec<string> = numbers.iter().filter(|n| n < 4).map(|n| format!("{}", n * 2)).collect();
    println!("{}", doubled.join(" "));
    let names = vec!["cherry", "apple", "banana"];
    let mut sorted: Vec<string> = names.iter().map(|n| n.clone()).collect();
    sorted.sort();
    println!("{}", sorted.join(", "));
    let text = "one two three";
    println!("{}", text.split(" ").count());
}
```

Output:

```text
55
3
true
2 4 6
apple, banana, cherry
3
```

## Words

Counting words in a `HashMap`, with `get` looked into by `if let` where it is made.

`words.vr`

```varyk
fn main() {
    let text = "the cat saw the dog and the cat ran";
    let mut counts: HashMap<string, i32> = HashMap::new();
    for word in text.split(" ") {
        let n = counts.get(word).unwrap_or(0) + 1;
        counts.insert(word.clone(), n);
    }
    let mut words: Vec<string> = counts.keys().map(|w| w.clone()).collect();
    words.sort();
    for word in words {
        if let Some(n) = counts.get(word) {
            println!("{} {}", word, n);
        }
    }
    println!("{} distinct words", counts.len());
}
```

Output:

```text
and 1
cat 2
dog 1
ran 1
saw 1
the 3
6 distinct words
```

## Patterns

A variant with named fields, nested, literal, and range patterns, `if let`, and `while let`.

`patterns.vr`

```varyk
enum Event {
    Click { x: i32, y: i32 },
    Key(string),
    Quit,
}

fn describe(event: Event) -> string {
    match event {
        Event::Click { x: 0, y: 0 } => "click at the origin",
        Event::Click { x, y } => format!("click at {}, {}", x, y),
        Event::Key(key) => format!("key {}", key),
        Event::Quit => "quit",
    }
}

fn grade(score: i32) -> string {
    match score {
        90..=100 => "A",
        80..=89 => "B",
        _ => "lower",
    }
}

fn is_yes(answer: string) -> bool {
    match answer {
        "y" => true,
        "yes" => true,
        _ => false,
    }
}

fn first_click(events: Vec<Event>) -> Option<i32> {
    for event in events {
        if let Event::Click { x, y: _ } = event {
            return Some(x);
        }
    }
    None
}

fn main() {
    let events = vec![Event::Key("a"), Event::Click { x: 0, y: 0 }, Event::Click { x: 3, y: 4 }, Event::Quit];
    for event in events {
        println!("{}", describe(event));
    }
    println!("{} {} {}", grade(95), grade(85), grade(12));
    println!("{} {}", is_yes("yes"), is_yes("no"));
    match first_click(events) {
        Some(x) => println!("first click at x = {}", x),
        None => println!("no clicks"),
    }
    let mut stack = vec![1, 2, 3];
    while let Some(top) = stack.pop() {
        println!("{}", top);
    }
    let last = Some(Event::Quit);
    if let Some(Event::Quit) = last {
        println!("quit");
    }
}
```

Output:

```text
key a
click at the origin
click at 3, 4
quit
A B lower
true false
first click at x = 0
3
2
1
quit
```

## Getters

Functions that return part of what they are given, with no copy: Varyk works it out from the body, and the generated Rust returns a reference.

`getters.vr`

```varyk
struct User {
    name: string,
    nickname: string,
}

impl User {
    fn new(name: string, nickname: string) -> User {
        User { name: name.clone(), nickname: nickname.clone() }
    }

    fn display_name(self) -> string {
        if self.nickname.is_empty() { self.name } else { self.nickname }
    }
}

fn trimmed(text: string) -> string {
    text.trim()
}

fn first(users: Vec<User>) -> User {
    users[0]
}

fn name_unless(user: User, hidden: string) -> string {
    if user.name == hidden { user.nickname } else { user.name }
}

fn main() {
    let user = User::new("Alice", "");
    let friend = User::new("Robert", "Bob");
    println!("{}", user.display_name());
    println!("{}", friend.display_name());
    let padded = "  hello  ";
    println!("[{}]", trimmed(padded));
    let users = vec![user, friend];
    let leader = first(users);
    println!("{}", leader.name);
    println!("[{}]", name_unless(leader, "Alice"));
}
```

Output:

```text
Alice
Bob
[hello]
Alice
[]
```

## Readings

`parse`, `?` on the way to a `Result`, `as`, and `.clone()` and `==` on a struct and an enum.

`readings.vr`

```varyk
enum Unit {
    Celsius,
    Fahrenheit,
}

struct Reading {
    value: f64,
    unit: Unit,
}

fn parse_reading(text: string) -> Result<Reading, string> {
    let parsed: Result<f64, Error> = text.trim().parse();
    let value = parsed.ok().ok_or(format!("not a number: {}", text.trim()))?;
    Ok(Reading { value: value, unit: Unit::Celsius })
}

fn to_fahrenheit(reading: Reading) -> Reading {
    if reading.unit == Unit::Fahrenheit {
        reading.clone()
    } else {
        Reading { value: reading.value * 9.0 / 5.0 + 32.0, unit: Unit::Fahrenheit }
    }
}

fn main() {
    let inputs = vec![" 25 ", "abc"];
    for input in inputs {
        match parse_reading(input) {
            Ok(reading) => {
                let converted = to_fahrenheit(reading);
                println!("{} -> {}", reading.value, converted.value);
            }
            Err(message) => println!("{}", message),
        }
    }
    let lengths = vec![3, 10];
    println!("{}", lengths.len() as i32 - 1);
    println!("{}", lengths.get(1).unwrap_or(0));
    let missing: Option<i32> = None;
    println!("{}", missing.unwrap_or(7));
    println!("{}", Some(4).map(|n| n * 2).is_some());
    let failed: Result<i32, string> = Err("bad");
    println!("{}", failed.is_err());
    println!("{}", failed.unwrap_or(0));
}
```

Output:

```text
25 -> 77
not a number: abc
1
10
7
true
true
0
```

## Text

A log filter: chains with `filter`, `map`, `all`, and `find`, `?` on an `Option`, `parse`, `map_err`, and a `HashMap`.

`text.vr`

```varyk
fn keep(line: string, levels: Vec<string>) -> bool {
    levels.iter().any(|level| line.starts_with(level))
}

fn first_error(lines: Vec<string>) -> Option<usize> {
    for i in 0..lines.len() {
        if lines[i].starts_with("ERROR") {
            return Some(i);
        }
    }
    None
}

fn report(lines: Vec<string>) -> Option<string> {
    let i = first_error(lines)?;
    Some(lines[i].to_uppercase())
}

fn parse_code(text: string) -> Result<i32, string> {
    let parsed: Result<i32, Error> = text.parse();
    parsed.map_err(|e| format!("bad code: {}", text))
}

fn next_port(text: string) -> Option<i32> {
    let parsed: Result<i32, Error> = text.trim().parse();
    let port = parsed.ok()?;
    Some(port + 1)
}

fn main() {
    let mut lines: Vec<string> = Vec::new();
    lines.push("ERROR disk full");
    lines.push("INFO started");
    lines.push("WARN low memory");
    lines.insert(1, "DEBUG tick");
    lines.remove(2);
    let levels = vec!["ERROR", "WARN"];
    let kept: Vec<string> = lines.iter().filter(|line| keep(line, levels)).map(|line| line.replace(" ", "_")).collect();
    println!("{}", kept.join(", "));
    println!("{} of {} lines kept", kept.len(), lines.len());
    println!("{}", lines.iter().map(|line| line.trim()).all(|line| line.contains(" ")));
    println!("{}", lines.contains("DEBUG tick"));
    println!("{}", lines.is_empty());
    if let Some(line) = lines.get(1) {
        println!("second: {}", line);
    }
    match report(lines) {
        Some(text) => println!("{}", text),
        None => println!("no errors"),
    }
    match lines.iter().find(|line| line.starts_with("WARN")) {
        Some(line) => println!("found {}", line),
        None => println!("no warnings"),
    }
    let mut codes: HashMap<string, i32> = HashMap::new();
    for i in 1..=3 {
        codes.insert(format!("e{}", i), i * 100);
    }
    println!("{}", codes.contains_key("e2"));
    println!("{}", codes.values().sum());
    println!("{}", parse_code("404").is_ok());
    let maybe = parse_code("42").ok();
    if let Some(code) = maybe {
        println!("{}", code);
    } else {
        println!("no code");
    }
    match parse_code("x").map_err(|e| format!("{}!", e)) {
        Ok(code) => println!("{}", code),
        Err(message) => println!("{}", message),
    }
    println!("{}", next_port(" 8079 ").unwrap_or(0));
    let mut greeting = "hello";
    greeting.push_str(" world");
    println!("{}", greeting);
}
```

Output:

```text
ERROR_disk_full, WARN_low_memory
2 of 3 lines kept
true
true
false
second: DEBUG tick
ERROR DISK FULL
found WARN low memory
true
600
true
42
bad code: x!
8080
hello world
```

## JSON

`json::parse` and `json::stringify`: `#[rename]` on a field and a variant, a missing `Option` read as `None`, a `#[default]` used, a `#[skip]` field neither read nor written, and a number out of range for its type an `Error` printed with `{}`, not a panic.

`json.vr`

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

Output:

```text
7 ann member
2 tags, age 18, nickname: false
{"id":7,"userName":"ann","role":"member","nickname":null,"tags":["a","b"],"age":18}
error: invalid value: integer `300`, expected u8 at line 1 column 67
```

## Config

`env::parse` fills a struct from the environment, then from a `.env` file in the current directory, then from `#[default]`: `#[rename]` on a field and a variant, an `Option` left unset, and a default used.

`config.vr`

```varyk
enum Mode {
    Dev,
    #[rename("live")]
    Live,
}

struct Config {
    port: u16,
    #[rename("db_url")]
    database_url: string,
    mode: Mode,
    token: Option<string>,
    #[default(30)]
    timeout_secs: u32,
}

fn mode_name(mode: Mode) -> string {
    match mode {
        Mode::Dev => "dev",
        Mode::Live => "live",
    }
}

fn load() -> Result<Config, Error> {
    let c: Config = env::parse()?;
    Ok(c)
}

fn main() {
    match load() {
        Ok(c) => {
            println!("port {}", c.port);
            println!("database {}", c.database_url);
            println!("mode {}", mode_name(c.mode));
            println!("token set: {}", c.token.is_some());
            println!("timeout {}s", c.timeout_secs);
        }
        Err(e) => println!("error: {}", e),
    }
}
```

Output, with `PORT=8080`, `DB_URL=postgres://h/db?sslmode=require`, and `MODE=live` set, and `TOKEN` and `TIMEOUT_SECS` not set:

```text
port 8080
database postgres://h/db?sslmode=require
mode live
token set: false
timeout 30s
```

With `PORT` not set, it prints ``error: `PORT` is not set``; with `PORT=abc`, ``error: `PORT` is not a number: `abc` ``.

## Logging

The four `log` calls, each writing a line to stderr.

`logging.vr`

```varyk
fn main() {
    let workers = 3;
    let port = 8080;
    let cause = Error::new("connection refused");
    log::debug("starting with {} workers", workers);
    log::info("listening on port {}", port);
    log::warn("queue is {} percent full", 90);
    log::error("request failed: {}", cause);
}
```

Nothing is printed on stdout. With `LOG=debug`, stderr holds these lines, each after the time:

```text
DEBUG starting with 3 workers
INFO listening on port 8080
WARN queue is 90 percent full
ERROR request failed: connection refused
```

## Tasks

Async functions awaited in place and started as tasks: two calls that overlap, ten squares waited on with `Task::all`, an async method, a detached task, and two async tests.

`tasks.vr`

```varyk
struct Counter {
    step: i64,
}

impl Counter {
    async fn next(self, from: i64) -> i64 {
        time::sleep(5).await;
        from + self.step
    }
}

async fn fetch_user(id: i64) -> string {
    time::sleep(30).await;
    format!("user {}", id)
}

async fn send_receipt(to: string) -> string {
    time::sleep(30).await;
    format!("receipt to {}", to)
}

async fn square(n: i64) -> i64 {
    time::sleep(5).await;
    n * n
}

async fn slow(n: i64) -> i64 {
    time::sleep(40).await;
    n
}

async fn double(n: i64) -> i64 {
    time::sleep(5).await;
    n * 2
}

async fn main() {
    // Both start at once, so together they take as long as the slower one.
    let user = fetch_user(7);
    let receipt = send_receipt("ann".clone());
    println!("fetched {}", user.await);
    println!("sent {}", receipt.await);

    let late = slow(2);
    let early = Counter { step: 1 }.next(6);
    println!("fast then slow: {} and {}", early.await, late.await);

    let ids: Vec<i64> = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let squares = Task::all(ids.iter().map(|id| square(id)).collect()).await;
    let mut total: i64 = 0;
    for s in squares.iter() {
        total = total + s;
    }
    println!("total of ten squares: {}", total);

    println!("doubled 21 is {}", double(21).await);
    slow(1).detach();
    time::sleep(100).await;
    println!("slow task done");
}

#[test]
async fn doubles() {
    assert_eq(double(4).await, 8);
}

#[test]
async fn counts() {
    let c = Counter { step: 3 };
    assert_eq(c.next(1).await, 4);
}
```

Output:

```text
fetched user 7
sent receipt to ann
fast then slow: 7 and 2
total of ten squares: 385
doubled 21 is 42
slow task done
```

`varyk test tasks.vr` runs the two tests, and both pass.

## Fanout

`Task::all` over calls that can fail stops at the first error and cancels the rest; `Task::all_settled` waits for every call and keeps each outcome.

`fanout.vr`

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

Output:

```text
prices: 12 + 24 + 48
failed: no price for item 3
item 1: 12
item 2: 24
item 3 failed: no price for item 3
item 4: 48
```

## Shared

One `Shared` value read by ten thousand tasks, each given a handle with `.clone()` rather than a copy of the value.

`shared.vr`

```varyk
struct Config {
    factor: i64,
}

async fn weigh(id: i64, config: Shared<Config>) -> i64 {
    id + config.factor
}

async fn main() {
    let config = Shared::new(Config { factor: 3 });
    let mut ids: Vec<i64> = Vec::new();
    let mut i: i64 = 0;
    while i < 10000 {
        ids.push(i);
        i = i + 1;
    }
    let weights = Task::all(ids.iter().map(|id| weigh(id, config.clone())).collect()).await;
    let mut total: i64 = 0;
    for w in weights.iter() {
        total = total + w;
    }
    println!("{} tasks, total {}", weights.len(), total);
}
```

Output: `10000 tasks, total 50025000`.

## Packages

A package is a directory with a `Cargo.toml` and a `src/main.vr` or `src/lib.vr`, which `Cargo.toml` names as its target. These six are in [`examples/packages/`](https://github.com/Varyk-Lang/varyk/tree/main/examples/packages); each is run from its own directory, with no file named.

<!-- TODO(release): re-copy the Cargo.toml of greeting, users, route, and trip once the 0.6.0 release pull request sets their varyk-std line to 0.6.0. -->

### matcher

A program that uses the crate `regex-lite` through a facade: Varyk code never names a Rust crate, so `src/text.rs` wraps it in a struct, methods, and an enum that Varyk imports like its own. Since milestone 5b2, `Matcher::new` gives a `Result`, and the program says when the pattern is not valid instead of stopping.

`packages/matcher/Cargo.toml`

```toml
[package]
name = "matcher"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "matcher"
path = "src/main.vr"

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
    let digits = match text::Matcher::new("[0-9]+") {
        Ok(m) => m,
        Err(e) => {
            println!("not a pattern: {}", e);
            return;
        }
    };
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
    println!("{}", text::classify("apple") == text::Kind::Word);
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
    /// A matcher for `pattern`, or why it is not a valid pattern.
    pub fn new(pattern: &str) -> Result<Matcher, String> {
        match regex_lite::Regex::new(pattern) {
            Ok(re) => Ok(Matcher { re }),
            Err(e) => Err(e.to_string()),
        }
    }

    pub fn is_match(&self, s: &str) -> bool {
        self.re.is_match(s)
    }

    pub fn count(&self, s: &str) -> usize {
        self.re.find_iter(s).count()
    }
}

#[derive(Clone, PartialEq)]
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
true
```

### greeting

A program with a nested module, `use`, and a private field, laid out as `varyk init` writes a package: `Cargo.toml` names `src/main.vr` as its `[[bin]]` target, and there is no `build.rs` and no stub.

`packages/greeting/Cargo.toml`

```toml
[package]
name = "greeting"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "greeting"
path = "src/main.vr"

[dependencies]
varyk-std = "0.5.0"
```

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

Output:

```text
== Greetings ==
Hello, Ada!
Hello, Grace!
== 2 greeted ==
```

### units

A library, used by the `route` package below, and a plain Rust program that uses it. Its `Cargo.toml` names `src/lib.vr` as its `[lib]` target. `varyk publish --assemble-only` assembles `units` into a plain Rust crate at `target/varyk/package/units/`, with the generated `.rs` files, the `.vr` sources beside them, and no `build.rs`, and publishes nothing. The consumer depends on that crate by path and builds with plain `cargo`, with no `varyk` involved.

`packages/units/Cargo.toml`

```toml
[package]
name = "units"
version = "0.1.0"
edition = "2024"
description = "A Varyk example library: lengths in meters"
license = "MIT OR Apache-2.0"

[lib]
path = "src/lib.vr"

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

### users

Milestone 5a together: a store of users read from JSON, with `#[rename]` and `#[default]`, configuration from the environment and a `.env` file, logging, and three tests. It is laid out as `varyk init` writes a package: `Cargo.toml` names `src/main.vr` as its target and depends on `varyk-std`.

`packages/users/Cargo.toml`

```toml
[package]
name = "users"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "users"
path = "src/main.vr"

[dependencies]
varyk-std = "0.5.0"
```

`packages/users/.env`

```text
# Committed on purpose: the defaults `varyk run` and the tests read.
PORT=8080
DB_URL=postgres://localhost/users?sslmode=disable
LOG=info
```

`packages/users/src/main.vr`

```varyk
mod store;

struct Config {
    port: u16,
    #[rename("db_url")]
    database_url: string,
}

fn add_user(mut users: store::Store, body: string) {
    match users.add_json(body) {
        Ok(n) => {
            log::info("now {} users", n);
            println!("added, {} in the store", n);
        }
        Err(e) => {
            log::warn("rejected a user: {}", e);
            println!("rejected: {}", e);
        }
    }
}

fn load_config() -> Result<Config, Error> {
    let c: Config = env::parse()?;
    Ok(c)
}

fn main() {
    let config = match load_config() {
        Ok(c) => c,
        Err(e) => {
            log::error("bad configuration: {}", e);
            return;
        }
    };
    log::info("serving on port {} with {}", config.port, config.database_url);
    let mut users = store::Store::new();
    add_user(users, "{\"id\": 1, \"name\": \"ann\", \"role\": \"member\"}");
    add_user(users, "{\"id\": 2, \"name\": \"bo\", \"role\": \"Admin\", \"email\": \"bo@example.com\", \"age\": 41}");
    add_user(users, "{\"id\": 3, \"name\": \"\", \"role\": \"member\"}");
    add_user(users, "{\"id\": 4, \"name\": \"cy\", \"role\": \"Root\"}");
    println!("{}", json::stringify(users.users()));
}
```

`packages/users/src/store.vr`

```varyk
pub enum Role {
    Admin,
    #[rename("member")]
    Member,
}

pub struct User {
    pub id: u32,
    pub name: string,
    pub role: Role,
    pub email: Option<string>,
    #[default(18)]
    pub age: u8,
}

pub struct Store {
    users: Vec<User>,
}

impl Store {
    pub fn new() -> Store {
        Store { users: Vec::new() }
    }

    /// Parses a user from JSON and keeps it, giving the new count, or says
    /// why it was refused.
    pub fn add_json(mut self, body: string) -> Result<usize, Error> {
        let user = parse_user(body)?;
        self.users.push(user);
        Ok(self.users.len())
    }

    pub fn len(self) -> usize {
        self.users.len()
    }

    pub fn users(self) -> Vec<User> {
        self.users
    }
}

/// Parses one user from JSON and rejects one with no name.
pub fn parse_user(body: string) -> Result<User, Error> {
    let user: User = json::parse(body)?;
    if user.name.is_empty() {
        return Err(Error::new("a user needs a name"));
    }
    Ok(user)
}

#[test]
fn parses_a_user_and_fills_the_default_age() {
    match parse_user("{\"id\": 1, \"name\": \"ann\", \"role\": \"member\"}") {
        Ok(u) => {
            assert_eq(u.age, 18);
            assert_eq(u.email.is_some(), false);
        }
        Err(e) => assert_eq(e.message(), "unexpected"),
    }
}

#[test]
fn rejects_a_user_with_no_name() {
    match parse_user("{\"id\": 2, \"name\": \"\", \"role\": \"Admin\"}") {
        Ok(u) => assert_eq(u.id, 0),
        Err(e) => assert_eq(e.message(), "a user needs a name"),
    }
}

#[test]
fn a_store_counts_its_users() {
    let mut store = Store::new();
    assert_eq(store.len(), 0);
    match store.add_json("{\"id\": 3, \"name\": \"bo\", \"role\": \"member\", \"age\": 30}") {
        Ok(n) => assert_eq(n, 1),
        Err(e) => assert_eq(e.message(), "unexpected"),
    }
}
```

Output of `varyk run`, in this directory, with its `.env`:

```text
added, 1 in the store
added, 2 in the store
rejected: a user needs a name
rejected: unknown variant `Root`, expected `Admin` or `member` at line 1 column 38
[{"id":1,"name":"ann","role":"member","email":null,"age":18},{"id":2,"name":"bo","role":"Admin","email":"bo@example.com","age":41}]
```

The log goes to stderr, each line after the time:

```text
INFO serving on port 8080 with postgres://localhost/users?sslmode=disable
INFO now 1 users
INFO now 2 users
WARN rejected a user: a user needs a name
WARN rejected a user: unknown variant `Root`, expected `Admin` or `member` at line 1 column 38
```

`varyk test` runs the three tests in `store.vr`, and all three pass.

### route

A library that uses another: each leg of a trip has a length that is a `Meters` of the package `units`, which `route` names by its key in `Cargo.toml`. It also reads a stop from JSON and logs when it cannot, and has an async function.

`packages/route/Cargo.toml`

```toml
[package]
name = "route"
version = "0.1.0"
edition = "2024"
description = "A Varyk example library: the legs of a trip, in meters"
license = "MIT OR Apache-2.0"

[lib]
path = "src/lib.vr"

[dependencies]
units = { version = "0.1.0", path = "../units" }
varyk-std = "0.5.0"
```

`packages/route/src/lib.vr`

```varyk
// A library that uses another: each leg's length is a `Meters` of the
// package `units`.

pub struct Leg {
    pub from: string,
    pub to: string,
    pub length: units::length::Meters,
}

pub struct Stop {
    pub name: string,
    pub minutes: u32,
}

pub fn leg(from: string, to: string, meters: i32) -> Leg {
    Leg {
        from: from.clone(),
        to: to.clone(),
        length: units::length::Meters { value: meters },
    }
}

pub fn total(legs: Vec<Leg>) -> units::length::Meters {
    let mut sum = units::length::Meters { value: 0 };
    for leg in legs {
        sum = units::length::add(sum, leg.length);
    }
    sum
}

// Returns one of the legs it is given, not a copy.
pub fn longest(legs: Vec<Leg>) -> Leg {
    let mut best: usize = 0;
    let mut index: usize = 0;
    for leg in legs {
        if leg.length.value > legs[best].length.value {
            best = index;
        }
        index = index + 1;
    }
    legs[best]
}

pub fn parse_stop(text: string) -> Result<Stop, Error> {
    let parsed: Result<Stop, Error> = json::parse(text);
    if let Err(problem) = parsed {
        log::warn("cannot read a stop: {}", problem);
    }
    parsed
}

pub async fn walking_minutes(meters: i32) -> i32 {
    time::sleep(5).await;
    meters / 80
}
```

### trip

A program that uses `route` and `units`, both named by their keys in its `Cargo.toml`. `route` returns a `Meters` of `units`, and `trip` lists `units` too, so it can hold one. `varyk run` checks all three packages from their `.vr` sources and builds `route` and `units` each as a crate of its own; `trip` writes no log line, but `route` does, so its warning reaches stderr.

`packages/trip/Cargo.toml`

```toml
[package]
name = "trip"
version = "0.1.0"
edition = "2024"

[[bin]]
name = "trip"
path = "src/main.vr"

[dependencies]
route = { path = "../route" }
units = { path = "../units" }
varyk-std = "0.5.0"
```

`packages/trip/src/main.vr`

```varyk
async fn main() {
    let legs = vec![
        route::leg("Home", "Mill", 800),
        route::leg("Mill", "Lake", 900),
    ];
    let sum = units::length::add(route::total(legs), units::length::Meters { value: 0 });
    println!("total {} meters", sum.value);
    let best = route::longest(legs);
    println!("longest {} to {}, {} meters", best.from, best.to, best.length.value);
    for text in vec!["{\"name\": \"Lake\", \"minutes\": 12}", "Lake at noon"] {
        match route::parse_stop(text) {
            Ok(stop) => println!("stop {}, {} minutes", stop.name, stop.minutes),
            Err(_) => println!("no stop"),
        }
    }
    let minutes = route::walking_minutes(sum.value).await;
    println!("about {} minutes on foot", minutes);
}
```

Output of `varyk run`, in this directory, with `route` and `units` beside it:

```text
total 1700 meters
longest Mill to Lake, 900 meters
stop Lake, 12 minutes
no stop
about 21 minutes on foot
```

On stderr, after the time, `route`'s log line:

```text
WARN cannot read a stop: expected value at line 1 column 1
```
