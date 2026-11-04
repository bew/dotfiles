---
name: verify-claims
description: |
  Verify an artefact's claims against a ground-truth source.
  Use for "verify these claims", "fact-check this doc", "check this against the code", or a delegated verification step.
  Reports verdicts only; never applies fixes.
  Callers may pass an explicit check-group taxonomy.
metadata:
  maintainers:
    - bew
---

# Verify Claims

## Setup — resolve inputs

Determine the following values from whatever is available in context
(user message, prior context, session prompt, or defaults):

- **Artefact**: the document holding the claims.
  Required — ask the user if absent.
- **Ground truth**: the source(s) each claim is checked against.
  May be the artefact itself for internal-only checks (coherence, conventions).
  Required — ask the user if absent.
- **Taxonomy**: the check-groups to cover.
  Use the caller's explicit taxonomy when supplied.
  Always cover the default skeleton (<§default-check-groups>) as a floor.
  A caller taxonomy adds groups; never removes them.
  Default: the default skeleton.
- **Deterministic checks**: a domain entrypoint to run first, if one exists.
  Default: `(none)`.
- **Domain refs**: the domain check specs to consult before checking (e.g. language census procedures).
  Default: `(none)`.

State resolved values:
```text
Artefact: <resolved value>
Ground truth: <resolved value>
Taxonomy: <resolved value>
Deterministic checks: <resolved value, or "(none)">
Domain refs: <resolved value, or "(none)">
```

Stop and ask when an input is missing or ambiguous; do not spawn subagents.

## Goal

Verify every claim in an artefact against its ground-truth source, and report per-claim verdicts.
Produce verdicts only; never apply fixes.

## Step 1 — Derive Claims

Enumerate every claim in the artefact as an atomic, falsifiable statement.
Split compound sentences into separate claims.

## Step 2 — Group Claims

Assign each claim to a check-group.
Cover the default skeleton (<§default-check-groups>) plus any caller-supplied taxonomy.
Order groups foundation-first: existence and naming first, mechanism and behaviour last.

## Step 3 — Deterministic Pre-checks

Skip this step when the domain supplies no deterministic entrypoint.
Otherwise run the entrypoint and read only its output; treat that output as ground truth.
Never audit the entrypoint's source.
Translate each finding in that output into a claim verdict and carry it into the report (*Step:Report*).

## Step 4 — Validate

Spawn one `general` subagent per check-group.
Each subagent explores the ground truth to validate its claims; the main agent must not self-validate.
Pass any supplied domain refs to the subagent for the groups they cover.

Instruct each subagent:
- Do not trust the artefact; check each claim against the ground truth.
- When the artefact is its own ground truth, check claims against its other parts.
- Quote a concrete locator (`file:line` or equivalent) as evidence per claim.
- Return TRUE / FALSE / PARTIAL / UNVERIFIABLE per claim.
- Use UNVERIFIABLE when the ground truth cannot decide; state what is missing.

One subagent per group keeps verdicts independent and stops context creeping between checks.

## Step 5 — Report

Collect every verdict, including findings from the deterministic pre-checks. Group the report by check-group.
Per claim, write a paragraph: a `Claim:` line, then `Verdict:` and `Evidence:` each on its own line.
Add a `Suggested fix:` line for each FALSE/PARTIAL verdict you can fix confidently.
Surface conflicting verdicts to the user; never silently pick one.
The report is the deliverable; the caller applies any fixes.

## Default check-groups
<!-- §default-check-groups -->

Default taxonomy; a caller may add to it, never remove from it.

- **Referential integrity** — named paths, symbols, and identifiers exist as described.
- **Factual accuracy** — stated facts (names, versions, numbers, behaviour) match the source.
- **Completeness** — "all/every/each" claims are total; no dangling references.
- **Internal coherence** — no part contradicts another.
- **Conventions & style** — the artefact follows its declared conventions.

Add domain groups when needed, for example:
- **Mechanism** — control-flow and concurrency claims match the actual types and call sites.
- **Examples** — samples are semantically correct, not merely symbol-valid.

## Output format

```md
## Referential integrity

Claim: "the crate exposes a `Config` type".
Verdict: TRUE.
Evidence: `src/config.rs:14`.

Claim: "the CLI flag is `--fast`".
Verdict: FALSE.
Evidence: `src/cli.rs:10` defines `--quick`.
Suggested fix: rename the flag to `--quick`.

Claim: "the scheduler is initialised by `run()`".
Verdict: UNVERIFIABLE.
Evidence: `src/lib.rs:5`; ground truth does not show initialisation.
```

## Example

> Verify the claims in this README against the crate source.
