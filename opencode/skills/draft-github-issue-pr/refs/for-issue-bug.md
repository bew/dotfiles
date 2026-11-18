# Personal Bug-Report Shape

Base shape for a bug report.
Repo required items are pinned on top.

- **Description** — what happened, and its impact.
  Lead with the user-visible behavior, not the root cause or low-level tooling.
  A root cause is optional; the symptom and repro stand on their own.
  Keep it subordinate, and only as far as the evidence supports it.
- **Steps to reproduce** — a numbered sequence.
  Start with a user-visible behavior, so the bug reproduces without the diagnostic setup.
  No tooling version strings in a step.
  A small temporary diagnostic patch is allowed as a repro aid — e.g. a `console.error` at a
  swallowed catch site that surfaces the real failure.
  Cite captured evidence (a log line, an error string) as support for the diagnosis, never as the
  reproduction itself.
- **Environment** — version, OS, terminal, where relevant.
  Every tooling version lives here, never in the description or the repro prose.

Load `bew-communication-style` before writing.
Use wrapped semantic line breaks: each sentence starts on its own line.
