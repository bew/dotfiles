---
name: draft-github-issue-pr
description: |
  Draft a GitHub issue or pull request body in bew's voice, conformed to the target
  repo's contributing guidelines and templates.
  Load when asked to write, draft, or file a GitHub issue or PR, including feature
  requests, bug reports, and turning a diff or branch into a PR description.
  Not for reviewing existing issues or PRs.
metadata:
  maintainers: [bew]
---

# Skill: draft-github-issue-pr

## Goal

Produce a local, file-backed draft of an issue or PR body that conforms to the repo's
contributing guidelines (issue-first rules, issue/PR templates), in bew's voice,
with every claim either verified or explicitly labeled.

## Setup — resolve inputs

Determine the following values from whatever is available in context
(user message, prior context, session):
- **Kind**: `pr` or `issue`. Default: `pr` when a branch or diff exists; ask if ambiguous.
- **Repo**: target repo as `owner/name`, or a local path.
  Default: current git repo.
- **Source**: the diff, branch, spec, code, or repro the draft is based on.
  Required for a PR; optional for an issue.
- **Hints**: any remaining free-form text.
  Default: `(none)`.

State resolved values:
```text
Kind: <pr|issue>
Repo: <value>
Source: <value, or "(none)">
Hints: <value, or "(none)">
```

## Phases

1. `Phase:Classify` — confirm target artefact and subtype; stop before drafting.
2. `Phase:ContribGuidelines` — read the repo's conventions; decide if an issue is required.
3. `Phase:PreDraft` — gather facts; build the claim list; label verified or unverified.
4. `Phase:Draft` — write and iterate on the draft in a concrete file.
5. `Phase:VerifyClaims` — run cited commands; re-check claims, paths, prose, conventions.
6. `Phase:IssueFirst` _(if required)_ — draft and file the issue before the PR.
7. `Phase:Submit` — file the artefact (PR, or issue on an issue-only run).

State each var in context once known:
- `$kind` — `pr` or `issue`.
- `$repo` — the resolved repo.
- `$repotemplate` — the repo's template structure, with required and advisory items marked.
  `(none)` if absent.
- `$repoguidelines` — the repo's contributing guidelines, with required and advisory items marked.
  `(none)` if absent.
- `$draftfile` — path of the current local draft.

## 1. `Phase:Classify` — confirm target and subtype

Confirm before drafting:
- `$kind`: PR or issue; default PR when a branch or diff exists.
- The subtype: feature / bug for an issue; feature / fix / refactor / docs for a PR.
  Subtype guides the shape and is re-derived at `Phase:Draft`; it is not carried as a var.

If the session already states both unambiguously, restate and continue.
Otherwise stop and ask.
Never guess — a wrongly targeted artefact wastes the draft.

Ready to move to `Phase:ContribGuidelines`? (say 'next' or similar to proceed)

## 2. `Phase:ContribGuidelines` — read repo conventions

When entering `Phase:ContribGuidelines`: read <./refs/phases/contrib-guidelines.md> for full
instructions.
If the user chose "create the issue now": proceed to `Phase:IssueFirst`, then resume at
`Phase:PreDraft`.

Ready to move to `Phase:PreDraft`? (say 'next' or similar to proceed)

## 3. `Phase:PreDraft` — gather facts and build the claim list

When entering `Phase:PreDraft`: read <./refs/phases/pre-draft.md> for full instructions.

Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)

## 4. `Phase:Draft` — write and iterate on the draft

When entering `Phase:Draft`: read <./refs/phases/draft.md> for full instructions.

Ready to move to `Phase:VerifyClaims`? (say 'next' or similar to proceed)

## 5. `Phase:VerifyClaims` — re-check claims, paths, and prose

When entering `Phase:VerifyClaims`: read <./refs/phases/verify-claims.md> for full instructions.

Ready to move to the filing phase? (`Phase:IssueFirst` if the repo requires an issue and none
exists yet, otherwise `Phase:Submit`.)

## 6. `Phase:IssueFirst` _(if required)_ — draft and file the issue first

Skip unless the repo requires an issue before a PR and none has been filed yet.

When entering `Phase:IssueFirst`: read <./refs/phases/issue-first.md> for full instructions.

Ready to continue? (`Phase:PreDraft` when entered early on "create the issue now", otherwise
`Phase:Submit`.)

## 7. `Phase:Submit` — file the artefact

When entering `Phase:Submit`: read <./refs/phases/submit.md> for full instructions.

## Rules

- Never draft before `$kind` and its subtype are confirmed.
- Read the repo's contributing guidelines and templates before writing, and classify each item as
  required or advisory.
  Never assume their shape.
- Layer shapes: pin every required repo item; otherwise follow your `for-<kind>[-<subtype>].md`
  guideline for section order, extra sections, and voice.
  Advisory repo hints never override it.
- Ask the user whenever a convention or action is unclear or needs confirmation.
  Do not guess.
- Never assert a claim — bug status, test result, API shape, or path — that code, a repro, or
  a command run does not back.
  Label unverified claims as such.
- Never write "verified", "tests pass", or similar without running the command yourself and
  citing the real output.
- Never alter the user's voice, punctuation, or deliberate quirks.
  Preserve `!`, `🙂`, asides, and wording.
- One sentence per line in every drafted prose body (semantic line breaks).
- Derive a PR's purpose from its diff.
  Keep incidental findings subordinate and mark them explicitly out of scope.
- Do not state a concrete path, key, or shape unless the code shows it.
- Write every draft to a concrete file.
  Do not leave the body only in chat.
- For an issue, check existing issues and PRs (open and closed) for duplicates via a subagent
  before drafting.
  Never tick an "already suggested" acknowledgement box unless that check actually ran.
- Default to the smallest deliverable.
  Do not build scripts or tooling unless asked.
- Draft only.
  File via `gh` only after explicit user go-ahead.

## Guidelines

- Show your work: name what you searched, ran, or read.
- Be concrete: real APIs, config keys, methods, behaviours.
- Explain context before the ask: give enough background to understand why it matters.
- Offer alternatives for feature asks: 2–3 concrete paths, with brief rationale.
- Keep one concern per artefact; split independent asks.
- Optional broader angle only when genuinely relevant.
  Do not force it.
- Be nice: 1–3 smileys across the body, never forced.
