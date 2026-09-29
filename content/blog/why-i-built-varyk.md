+++
title = "Why I built Varyk"
description = "The languages I built backend services in before Varyk, what each of them got right, and the one thing none of them gave me."
date = 2026-09-24T14:31:00+02:00
+++

Varyk is an experimental language for backend services: you write simple, Go-like application code, and you ship a native Rust binary. This post is the story of why I started building it.

I came to Varyk through the languages I built services in before it. JavaScript, then Python, then TypeScript: productive languages, but working with data without real types was harder than it needed to be, and TypeScript's types are only as strong as the JavaScript underneath them. I also needed performance those languages could not give me. So I went looking for a language that was fast and had a type system I could lean on.

Go is simple, and I like that. But it has a garbage collector, with the runtime and memory overhead that come with it, and a syntax I never took to. Swift is a good language whose server ecosystem is too small for the microservices I build. Rust has the ideology I believe in: ownership instead of a garbage collector, safety enforced by the compiler, native performance, and an ecosystem that already has everything a service needs. I love it. Day to day, though, it is difficult to work with, and much of the difficulty comes from quirks that have nothing to do with the service being written.

What I wanted did not exist: Rust's ecosystem, guarantees, and performance, with application code as simple as Go. Varyk is that language. It is for the application: kernels, database engines, and borrow-heavy libraries stay in Rust, in a `.rs` file beside your Varyk, in the same build.

## What that means in practice

Varyk compiles to Rust. Every program becomes ordinary Rust that the Rust compiler checks, so the safety and the speed are Rust's own, and what you deploy is one native binary with no garbage collector. A Varyk package is a Cargo package: any crate on crates.io is available through a small `.rs` file in the package, a facade, with no bindings to generate. What Varyk removes is the part of Rust you have to hold in your head. The [Why page](/why/) lays out what that costs in Rust and how Varyk takes it out; the [examples](/learn/examples/) show what the code looks like.

Varyk is experimental and pre-1.0, and the batteries a service needs, HTTP, JSON, databases, and `async`, are [milestone 5](/design/roadmap/). If the bet sounds wrong to you, I would like to hear why: [hello@varyk.com](mailto:hello@varyk.com).
