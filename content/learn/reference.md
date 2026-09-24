+++
title = "Language reference"
description = "The milestone-1 surface of Varyk: syntax, types, ownership rules, strings, return values, and modules."
weight = 2
+++

<!-- TODO(release): replace this page with the compiler repository's docs/language.md once it exists, noting the source commit. -->

This page describes the milestone-1 language surface, taken from the [design specification](https://github.com/Varyk-Lang/varyk/blob/main/docs/specs/2026-09-23-varyk-design.md). Milestone 1 is a minimum viable compiler: only what is listed here is supported, anything else is rejected with a diagnostic that names the construct, and nothing may silently mis-compile. Before 0.1, everything may change.

## Lexical and syntactic elements

- Comments: `//` line comments.
- Keywords: `fn`, `pub`, `let`, `mut`, `struct`, `mod`, `if`, `else`, `while`, `break`, `continue`, `return`, `true`, `false`. Every other Rust keyword and reserved word, including the 2024-edition ones, is reserved and produces an "unsupported" diagnostic when used, so a Varyk identifier is always a valid Rust identifier.
- Items: `fn`, `struct`, `mod name;`, each optionally preceded by `pub`. Fields of a `pub struct` are public. Field-level `pub` is milestone 2.
- The entry file must define `fn main()` with no parameters and no return value. Modules must not define `main`.
- Types: `bool`, `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `f32`, `f64`, `string`, and user-declared structs.
- Statements: `let x = e;`, `let x: T = e;`, `let mut` forms of both, assignment to a variable or a field, `return`, `while`, `break`, `continue`, expression statements.
- Expressions: integer, float, bool, and string literals; identifiers; paths such as `greet::hello`; unary `-` and `!`; binary `+ - * / %`, comparisons `== != < <= > >=`, `&&` and `||`; calls; field access; struct literals; blocks whose tail expression is the block's value; `if`/`else`, which is an expression as in Rust.
- Arithmetic and ordering operators are defined for numeric types only, with both operands of the same type. `==` and `!=` are defined for primitives and `string`. `+` on `string` is not in milestone 1.
- String literals support the escapes `\n`, `\t`, `\\`, `\"`, and `\0`. No raw strings and no other escapes in milestone 1.
- `println!` is a compiler intrinsic, not a macro system. The format string is checked at compile time: only `{}` placeholders and the `{{` and `}}` escapes are accepted, and the number of placeholders must match the number of arguments. Arguments must be primitives or `string`; structs have no display form yet.

Type inference covers `let` bindings without annotations. Integer and float literals take the type their immediate context expects, with `i32` and `f64` as fallbacks; milestone 1 does not infer a literal's type backwards from later uses.

## Ownership rules

Every parameter carries a mode: shared borrow, mutable borrow, or owned.

- A parameter written `name: T` is a **shared borrow**. The body may read it and may not mutate it.
- A parameter written `mut name: T` is a **mutable borrow**. The body may mutate it, and the caller observes the mutation.
- Call sites never write `&` or `&mut`. The callee's contract decides the passing mode.
- An argument passed to a `mut` parameter must be a **mutable place**: a `let mut` binding that is not a shared borrowed place, a `mut` parameter, a field of a mutable place, or a temporary (a call result, a struct literal, or a literal). Passing an immutable `let` binding produces a diagnostic whose fix-it adds `mut` to the `let`. Passing a non-`mut` parameter, or a binding initialized from one, produces a diagnostic whose fix-it adds `mut` to that parameter, with a note that this changes the function's contract for its callers.
- A **borrowed place** is a non-Copy parameter, whatever its mode; any non-Copy field, whether reached through a parameter or through an owned local, because milestone 1 has no partial moves; or a `let` binding initialized from either, which inherits the shared or mutable kind of its source. Copy-typed parameters, fields, and bindings are never borrowed places: reading one yields an owned copy. A borrowed place cannot flow into an **owned slot**: a struct field, a return value, an imported Rust parameter taken by value, or a `let` binding that must be owned. The diagnostic names the parameter or the struct the field belongs to, and says milestone 2 will allow borrowed returns and field moves.
- `let b = a;` moves, as in Rust. Later use of `a` is an error, and the diagnostic shows where the move happened. `string` is never `Copy` in Varyk, whatever its representation in the generated Rust.
- Copy types (`bool`, integers, floats) are passed by value to read-only parameters. For a Copy type this is observably identical to a shared borrow, and the generated Rust takes a plain `i32`. A `mut i32` parameter is a mutable borrow like any other.
- Explicit ownership transfer syntax for Varyk-declared functions does not exist in milestone 1. It is an open question.

A note for Rust readers: in Rust, `mut name: T` declares an owned parameter that the body may rebind. Varyk reuses the keyword for the mutable-borrow contract. No Varyk-declared parameter takes ownership of a non-Copy value in milestone 1, so the Rust meaning has nothing to attach to; only imported Rust signatures produce owned parameters of non-Copy types. This is the one place a Rust keyword changes meaning, and it is deliberate: mutation of the caller's value should be visible in the signature.

## Strings

`string` is the only string type in the surface language. Writing `String` or `str` produces a diagnostic pointing at `string`.

Inside the compiler every `string` value has one of two representations, borrowed (`&str`) or owned (`String`). Sources of string values are:

- a **literal**, which is borrowed and may be converted;
- an **owned value**: a call result, or a `let` binding that is owned;
- a **borrowed place**: a `string` parameter, any `string` field, or a `let` binding initialized from either.

**Owned slots** are struct fields, return values, imported Rust parameters of type `String`, and `let` bindings that need to be owned. A `let` binding needs to be owned if any value assigned to it is owned, if it is ever passed to a `mut string` parameter, or if it ever flows into another owned slot. The representation is computed over the whole function before code generation.

What may flow into an owned slot:

- a **literal** is converted with `.to_string()` at that expression. This is the only allocation Varyk inserts, and it is visible in `--emit-rust`;
- an **owned value** moves, with no allocation, and the source is unusable afterwards, whatever its representation;
- a **borrowed place** is an error, with a diagnostic naming the parameter. Converting it would be a hidden copy of the string's bytes. Milestone 2 adds lifetime inference for borrowed returns and an explicit copy spelling.

| Situation | Generated Rust | Allocates |
|---|---|---|
| literal bound by `let`, binding stays borrowed | `let s = "x";` | no |
| literal bound by `let`, binding needs to be owned | `let s = "x".to_string();` | where the literal is written |
| literal into a field, a field assignment, or a return | `"x".to_string()` | where the literal is written |
| owned local into a field, a return, or a `String` parameter | `s` | no, moves |
| parameter or any field into an owned slot | rejected | |
| borrowed local or literal to a `string` parameter | `f(s)` | no |
| owned local to a `string` parameter | `f(&s)` | no |
| field to a `string` parameter | `f(&user.name)` | no |
| owned local to a `mut string` parameter | `f(&mut s)` | no |
| field of a mutable place to a `mut string` parameter | `f(&mut user.name)` | no |
| `let` from a field | `let n = &user.name;` | no |
| assignment through a `mut string` parameter | `*name = "x".to_string();` | where the literal is written |
| `==` between any two strings | `a.as_str() == b.as_str()` as needed | no |

Passing a borrowed string to an imported Rust parameter of type `&String` is not possible without an allocation the rules above do not cover, so such functions are not callable in milestone 1 and the diagnostic suggests `&str`.

This is the one place Varyk breaks Rust's naming convention. The rule is: lowercase names are built-in types (`i32`, `bool`, `string`), CamelCase names are library types. Go and TypeScript spell strings in lowercase.

## Return values

In milestone 1, return values are always owned. A literal return converts, an owned value moves, and returning a borrowed place, such as `fn name(user: User) -> string { user.name }`, is rejected by the ownership rules. Lifetime inference for borrowed returns is milestone 2 work.

## Modules and Rust interop

`mod greet;` in the entry file resolves to `greet.vr` or `greet.rs` in the same directory. This is Rust's module rule, extended to `.vr` files. If both files exist, that is an error, and `main` is not a valid module name. Items are referenced through their module path, as in `greet::hello(name)`, and the generated Rust spells every such path with a `crate::` prefix so it resolves the same way from any module.

A `.vr` module is compiled like the entry file, except that it must not define `main`. Its items are visible to the importer only when declared `pub`. Milestone 1 supports one level: modules declared in the entry file only, no nested `mod`, and no `mod.vr` directories. Nesting is milestone 2.

Every module, Varyk or Rust, becomes `src/<name>.rs` in the generated crate, declared by a `mod <name>;` line in the generated `main.rs`, so the generated tree mirrors the source tree.

A `.rs` module is copied verbatim into the generated crate and compiled as edition 2024. In milestone 1 it may use only the standard library, because the generated crate has no dependencies, and it may not declare nested modules, because only the one file is copied. Its top-level free `pub fn` items are parsed and imported. Methods, `pub(crate)` and `pub(super)` items, `unsafe fn`, `async fn`, `const fn`, `#[cfg]`-gated items, and macro-generated items are ignored. Imported signatures map to Varyk modes:

| Rust parameter type | Varyk mode |
|---|---|
| `bool`, integer and float types | owned, passed by value |
| `&T`, `&mut T` for Copy `T` | shared or mutable borrow of `T` |
| `&str` | shared borrow of `string` |
| `&mut String` | mutable borrow of `string` |
| `String` | owned `string`: an owned argument moves, a literal converts, a borrowed place is rejected |
| `&String` | not callable in milestone 1; the diagnostic suggests `&str` |

In milestone 1 the only known types are the primitives and `string`, because Rust structs declared in `.rs` modules are not imported yet. Return types map `String` to `string`, primitives to themselves, and `()` to no return value.

A signature using generics, explicit lifetimes, trait objects, references in return position, or any type Varyk does not know is imported as opaque. Calling it produces an "unsupported Rust signature" diagnostic that shows the signature. Opaque functions never cause a failure unless they are called.

## Not in milestone 1

Enums, `match`, `for`, closures, traits, `impl` blocks, generics, `Option`, `Result`, `?`, `Vec`, attributes and derives, `use`, Cargo dependencies, nested modules, field-level `pub`, an explicit string copy, async, threads, unsafe, raw pointers, FFI, macros beyond the `println!` intrinsic, a package manifest, a formatter, a language server, and any backend other than generated Rust. The [roadmap](/design/roadmap/) says which milestone adds what.
