---
name: write-github-issue
description: |
  Guidelines for drafting a GitHub issue in bew's voice.
  Load when asked to write, draft, or review a GitHub issue (feature request, bug report,
  question, or other type).
metadata:
  maintainers: [bew]
---

# Skill: write-github-issue

## Goal

Draft a GitHub issue that is clear, well-researched, and framed to lower maintainer friction.

## Issue types
<!-- §issue-types -->

Supported types — only one scenario is currently specified:

- **Ask for something** (feature request, capability ask, ask-for-help) — see <./refs/ask-for-something.md>

Other types (RFC, bug report, question, discussion) — no guidelines yet.
Apply general principles below and use judgment.

## General principles

IMPORTANT: Load `bew-communication-style` before writing any prose — required for voice and tone.

- **Show your work.** Mention what you searched, tried, or considered before writing the issue.
  Maintainers respond better when they see the effort.
- **Be concrete.** Name real APIs, config keys, methods, or behaviors.
  Avoid abstract descriptions when specific ones are possible.
- **Explain context before asking.** Give the maintainer enough background to understand *why*
  this matters before they reach the ask.
- **Offer alternatives.** Multiple implementation paths signal you've thought it through and
  reduce the cognitive load of having to invent one.
- **Keep scope tight.** One issue = one concern.
  Split if there are multiple independent asks.
- **End with an optional broader angle** only if genuinely relevant
  (e.g. "is this something that belongs upstream instead?").
  Don't force it.
- **Be nice.** Open source is a shared space — a genuine thank-you and a light touch of warmth go a long way.
  1–3 smileys max across the whole issue; never forced.

## Steps

1. Identify the issue type — read the matching ref if one exists (see <§issue-types>).
2. **Context check** — assess whether there is enough data to apply general principles:
   - Is the problem grounded in real, tested behavior?
   - Are alternatives explored (not just invented on the spot)?
   If data is thin, ask the user:
   > Not enough context to write a well-grounded issue.
   > Should we stop and gather more first, or draft a lighter version for your own research notes?

   Proceed only once user decides.
3. Read the matching ref file (if one exists for this issue type), then draft the issue body
   applying general principles and any type-specific guidelines.
4. Review: every sentence must earn its place. Cut filler.
