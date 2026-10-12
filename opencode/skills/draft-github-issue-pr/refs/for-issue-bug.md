# Personal Bug-Report Shape

Base shape for a bug report.
Repo required items are pinned on top.

- **Description** — what happened, and its impact.
  Lead with the user-visible behavior, not the root cause or low-level tooling.
  Keep the root cause subordinate, and only as far as the evidence supports it.
- **Steps to reproduce** — a numbered sequence.
  Start with a user-visible behavior, so the bug reproduces without the diagnostic setup.
  A small temporary diagnostic patch is allowed as a repro aid — e.g. a `console.error` at a
  swallowed catch site that surfaces the real failure.
  Cite captured evidence (a log line, an error string) as support for the diagnosis, never as the
  reproduction itself.
- **Environment** — version, OS, terminal, where relevant.

Load `bew-communication-style` before writing.
One sentence per line.
