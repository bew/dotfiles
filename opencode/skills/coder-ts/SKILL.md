---
name: coder-ts
description: |
  TypeScript code writing guidelines: type-only imports, type aliases, readonly and const
  assertions, and file headers.
  Always load when asked to draft/write/edit/refactor/review TypeScript (.ts/.tsx) code files.
  Requires coder-generic skill.
metadata:
  maintainers: [bew]
---

## Goal

Write TypeScript modules with type-only imports, type aliases, and consistent file headers,
building on generic conventions.

REQUIRES: load `coder-generic` skill first.

All TypeScript here is **module code**: `.ts`/`.tsx` files imported by other code, not run
directly.
Standalone TS scripts are out of scope — this skill ships no script variant.

If working on **module code**: read <./module-rules.md>.

## Rules

- Prefer `type` aliases for object shapes and unions; reserve `interface` for declaration merging.
- Mark immutable collections `readonly` (`readonly T[]`, `ReadonlyMap`).
- Use `as const` for literal constants and fixed ordered lists.
- Use `===` and `!==`; never `==` or `!=`.
- Prefer optional chaining and nullish coalescing over `!` non-null assertions.
- Use `unknown` at untrusted boundaries, then narrow before use — never `any`.
- When filtering a union-typed collection, use a type guard so narrowing survives downstream.

## Comments

- Open every file with a `//` header: one line stating purpose, then optional paragraphs
  separated by blank `//` lines.
- Document each declaration with a `//` comment on the line above it.
- See `coder-generic` for comment content rules.

## Testing

TypeScript tests run on Bun's test runner.
Import `test` and `expect` from `"bun:test"`; drive time with `jest.useFakeTimers()` and
`jest.advanceTimersByTime(...)`.
Run tests with `bun test <path>`.
No dedicated TypeScript testing skill exists yet — ask the user before adding a test framework.
