# README structure

Sections are recommendations, not a checklist.
Rename, reorder, or omit any section to fit the package.

## Recommended sections

- **Purpose & scope** — the default subject. What the package is; what it delegates to siblings or the OS.
  Name the role the package plays for its consumers, not a roster of them.
- **Responsibilities** — the default subject. Bulleted capability areas; depth scales with package complexity.
- **Architecture** — when the mechanism is non-obvious. Central types, threading/event model, data flow.
  Cover mechanism that helps a maintainer or agent understand what the package does; leave incidental internals to API documentation.
  For a complex package, a Mermaid diagram of the internal object relationships can replace a paragraph of prose; offer it rather than adding it unprompted.
- **Failure behaviour** — when the package has a meaningful error surface: what is rejected, which error type is returned, and how partial input is handled.
  Include it for codecs, parsers, protocol layers, and anything with a fallible public API.
- **Features & build** — only when real build-time features/flags/defaults or platform-specific steps exist.
- **Module organization** — complex packages only, and only with user approval.
- **Cross-crate relationships** — complex packages only, and only after the user confirms.
- **Usage** — ask the user before adding.

## Content registers

Keep each register separate; do not blur layers.

- **Interface & behaviour** (Purpose, Responsibilities, Failure behaviour) — the public surface and its high-level behaviour.
  Declarative present tense.
  This is the package's behavioural contract for overview purposes; the source remains authoritative for detail.
  Do not use empirical framing ("observed", "seen").
- **Mechanism** (Architecture) — how it works, at overview altitude.
  Exact public type spellings of the mechanism and its observable behaviour belong here.
  Private fields, internal helpers, and implementation strategy stay in source comments or API documentation unless the overview needs them to explain what the package does.
- **Quirks** — label them with a GitHub-flavored callout or a "Known quirks" section.
  Use `> [!NOTE]`, `> [!WARNING]`, `> [!TIP]`, `> [!IMPORTANT]`, or `> [!CAUTION]` as appropriate.
  Keep caveats distinct from the contract.
- A mechanism fact appears once, in Architecture.
  Responsibilities names the capability; it carries only as much mechanism as the reader needs to recognise it.
  A simple package needs no mechanism; a complex package may need a paragraph, and the depth scales with package complexity.
  Architecture explains the mechanism; it does not re-list capabilities.
  Purpose states scope and the problem the package solves; it does not preview Architecture.
  Failure behaviour states the error surface; it does not restate the mechanism that produces it.

## Rules

- Confirm the final heading set with the user before writing headings.
- When offering section choices, state what each choice omits: a section left out is information the reader will not get.
- Write a bold paragraph lead-in as `**Label**:`, with the colon outside the span and no blank line after it.
- State positive facts only; never write a negative fact or a section whose content is an absence.
  Exception: allow a negative fact when omitting it would distort the overview.
- Do not map source files under `src/` unless the package is complex and the user approves.
- Order Responsibilities as a progression, most central first (setup → spawn → secondary utilities → re-exports).
  Mirror the Purpose narrative.
- Keep Responsibilities a navigation index of capability areas, not an exhaustive API inventory.
  Leave constructor and accessor enumerations to API documentation.
  A bullet names a role, not a list of symbols:
  Good: "PDU classification: name a decoded PDU, tell whether it carries user input, and extract its pane id."
  Bad: "PDU classification: `Pdu::pdu_name`, `Pdu::is_user_input`, and `Pdu::pane_id`."
- State caller-enforced conventions explicitly: magic values, ordering rules, who assigns an identifier, and which side owns a lifecycle step.
  They are invisible in the package source and cannot be recovered from the types.
- Write one fact per sentence.
  A sentence carrying three qualifications is a bullet that has not been split.
- Name the role, not the roster: "the mux client and server", not a list of every dependent crate.
  Name specific crates only when the consumer set is small and fixed by the architecture.
- Name a constant when a consumer must import it or compare against it; never quote its value.
  The value changes without notice, while the name is the stable handle a caller uses.
  Describe thresholds and tuning knobs qualitatively.
- Never prefix a module/file name with `src/` when the file actually lives under `src/`; use the bare name.
  This applies in every mode: *Author* and *Update* never write the prefix; *Review* flags it.
- A package is "complex" when it has more than one subsystem or a `src/` tree with several modules.
- Spend the overview on invariants and failure conditions before instrumentation.
  Metrics, logging, and private structure are optional unless the consumer observes them.
- Map each section to a reader task and to verifiable claims, so *Step:Verify* can check both accuracy and coverage.
