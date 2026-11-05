# README structure

Sections are recommendations, not a checklist.
Rename, reorder, or omit any section to fit the package.

## Recommended sections

- **Purpose & scope** — the default subject. What the package is; what it delegates to siblings or the OS.
- **Responsibilities** — the default subject. Bulleted capability areas, one line each.
- **Architecture** — when the mechanism is non-obvious. Central types, threading/event model, data flow.
- **Features & build** — only when real build-time features/flags/defaults or platform-specific steps exist.
- **Module organization** — complex packages only, and only with user approval.
- **Cross-crate relationships** — complex packages only, and only after the user confirms.
- **Usage** — ask the user before adding.

## Content registers

Keep each register separate; do not blur layers.

- **Interface & behaviour** (Purpose, Responsibilities) — the public surface and its high-level behaviour.
  Declarative present tense.
  This is the authoritative behavioural contract for the package.
  Do not use empirical framing ("observed", "seen").
- **Mechanism** (Architecture) — how it works.
  Exact type spellings, private fields, and internals belong here, and only when they add understanding.
- **Quirks** — label them with a GitHub-flavored callout or a "Known quirks" section.
  Use `> [!NOTE]`, `> [!WARNING]`, `> [!TIP]`, `> [!IMPORTANT]`, or `> [!CAUTION]` as appropriate.
  Keep caveats distinct from the contract.

## Rules

- Confirm the final heading set with the user before writing headings.
- Write a bold paragraph lead-in as `**Label**:`, with the colon outside the span and no blank line after it.
- State positive facts only; never write a negative fact or a section whose content is an absence.
- Do not map source files under `src/` unless the package is complex and the user approves.
- Order Responsibilities as a progression, most central first (setup → spawn → secondary utilities → re-exports).
  Mirror the Purpose narrative.
- Never prefix a module/file name with `src/` when the file actually lives under `src/`; use the bare name.
  This applies in every mode: *Author* and *Update* never write the prefix; *Review* flags it.
- A package is "complex" when it has more than one subsystem or a `src/` tree with several modules.
- Map each section to verifiable claims so *Step:Verify* can check it.
