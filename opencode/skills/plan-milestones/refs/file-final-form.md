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
- [TASK: CLI entry point and dispatch](TASK-<namespace>-M<N>-cli-entry-and-dispatch.md)
- [TASK: Hardcoded stub struct](TASK-<namespace>-M<N>-hardcoded-stub-struct.md)
- [TASK: Core plumbing](TASK-<namespace>-M<N>-core-plumbing.md)
- [TASK: Terminal output](TASK-<namespace>-M<N>-terminal-output.md)

**Future work**: `--help` and man-page generation for `<subcommand>` (out of scope for now).
```

A milestone past the scoping boundary carries rough tasks instead — plain bullets, no links:
```md
**Tasks** (rough):
- CLI entry point and dispatch to `<subcommand>`.
- Hardcoded stub struct with the fields the real source will eventually provide.
```

Backlog entries are not milestones — topic name plus Goal, appended after the last milestone
entry, with an optional `Pinned:` line:
```md
----

## Backlog

- `{publish-flow}`: `<subcommand>` output reaches a remote destination, not just the terminal.
  Pinned: must land after the destination config exists, before any packaging work.
- `{packaging}`: installable artifact and release pipeline.
```
