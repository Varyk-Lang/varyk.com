+++
title = "Why I built Varyk"
description = "The languages I worked in before Varyk, what each of them got right, and the one thing none of them gave me."
date = 2026-09-24T14:31:00+02:00
+++

Varyk exists to make Rust available to everyone. That is the mission; this post is the story behind it.

I came to Varyk through the languages I worked in before it. JavaScript, then Python, then TypeScript: productive languages, but I kept paying for weak type safety with bugs a compiler should have caught, and TypeScript is only as safe as the JavaScript underneath it. I also needed performance those languages could not give me. So I went looking for a language that was fast and would catch my mistakes.

Go is simple, and I like that. But it has a garbage collector, with the runtime and memory overhead that come with it, and a syntax I never took to. Swift is a good language whose server ecosystem is too small for the microservices I build. Rust has the ideology I believe in: ownership instead of a garbage collector, safety enforced by the compiler, native performance, and an ecosystem that already has everything a service needs. I love it. Day to day, though, it is difficult to work with, and much of the difficulty comes from quirks that have nothing to do with the program being written.

What I wanted did not exist: Rust's ecosystem, guarantees, and performance, with code as simple as Go. Varyk is that language, built so that anyone can pick it up, not only people who have already learned Rust.

## What that means in practice

Varyk compiles to Rust, the way TypeScript compiles to JavaScript. Every program becomes ordinary Rust that the Rust compiler checks, so the safety and the speed are Rust's own, and from milestone 2 every crate on crates.io is available without bindings. What Varyk removes is the part of Rust you have to hold in your head. The [Why page](/why/) lays out what that costs in Rust and how Varyk takes it out; the [examples](/learn/examples/) show what the code looks like.

Varyk is pre-0.1 and experimental. If the bet sounds wrong to you, I would like to hear why: [hello@varyk.com](mailto:hello@varyk.com).
