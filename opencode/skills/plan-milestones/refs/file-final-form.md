## Milestone file — Final form

Produced in `Phase:Finalize`.

- Header: `## M<N> — <topic>`; the `(draft)` marker is stripped.
- All fields, in the exact order given in <./file-format.md>.

The full final-form example demonstrates all fields:
```md
## M<N> — `<subcommand>` — core flow (hardcoded stub)

**Goal**: `<subcommand>` works end-to-end with a hardcoded stub in place of a real data source.
All plumbing (I/O, state write, output) functions correctly and is independently verifiable.
No real API, no edge cases — just the core path, fully exercised.

**Ordering reason**: establishes the end-to-end plumbing before any real data source exists.
Subsequent milestones replace the stub without changing observable behavior.

**Finished**: `<state-file format>` (schema finalized, read+write working).

**Proof**:
- Run `<subcommand>` — exits zero, produces expected output.
- Confirm the expected side effect (file written, state updated, etc.) is observable.
- Confirm the stub value triggers any warning or conditional path it is designed to exercise.

NOTE: can run in parallel with M<N> — {topic-c}.

**Tasks**:
- CLI entry point and dispatch to `<subcommand>`.
- Hardcoded stub struct with the fields the real source will eventually provide.
- Core plumbing: the end-to-end flow using the stub.
- Terminal output: step summary and any conditional warning.

**Future work**: `--help` and man-page generation for `<subcommand>` (out of scope for now)
(optional field — omit when there is no relevant follow-up to flag).
```
The milestone after this one replaces the stub with a real data source,
keeping observable behavior identical.
