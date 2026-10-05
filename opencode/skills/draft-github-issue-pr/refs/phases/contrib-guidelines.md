# Phase:ContribGuidelines

Read the repo's conventions before drafting, and split them into required and advisory items.
Store the annotated results in `$repotemplate` and `$repoguidelines`.

## What to read

Check the local checkout for:
- `CONTRIBUTING.md`, `CONTRIBUTING`, `.github/CONTRIBUTING.md`, or `docs/CONTRIBUTING.md`.
- PR and issue templates: read <../templates.md> and store the result in `$repotemplate`.
- PR title and commit conventions, base branch, and required checklists.

Store the annotated guideline text in `$repoguidelines`.
If a source is missing, set it to `(none)` and say so.

## Required vs advisory

Mark each item:
- Required — an explicit "must" or "open an issue first" rule, required checks, a required base
  branch, or anything the repo auto-rejects on.
  Always pinned.
- Advisory — a suggestion, preferred style, or optional step.
  Applied only when it does not conflict with the personal guideline.

## Issue-first rule

Determine whether the repo requires an issue before a PR.

- Look for an explicit "open an issue first" rule in `CONTRIBUTING.md`.
- If it is unclear, ask the user.
  Do not assume either way.

Record whether the requirement is **auto-enforced** (the repo rejects a PR without a linked
issue) or **procedural** (the guidelines ask for it, but the check exempts this change).

If an issue is required and none exists, ask the user **when** to create it.
Do not frame "proceed PR-only" as the default fallback — the requirement stands either way.
Ask with these timing options:
- Create the issue now — jump to `Phase:IssueFirst` before the PR draft, then resume
  `Phase:PreDraft`.
- Create the issue before sending the PR — finish the PR draft, then draft and file the issue
  at `Phase:IssueFirst`/`Phase:Submit` and add `Closes #N`.
- Skip the issue (only when the requirement is not auto-enforced) — proceed PR-only and note
  the exemption in the draft.

The issue itself is drafted at `Phase:IssueFirst`, not during this phase.

## Unclear conventions

When a convention is ambiguous, or a rule needs a judgement call, ask the user.
Do not guess and do not silently pick a default.
