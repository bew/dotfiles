# Phase:PreDraft

Gather facts before writing any prose.
The draft's credibility rests on this phase.

## Repo conventions

Templates and guidelines were read in `Phase:ContribGuidelines`.
Use `$repotemplate` and `$repoguidelines`.
Do not re-fetch them.

## Facts

- PR: delegate the diff to the `explore-diff` agent for a structured summary.
  Pass the diff source (a `git diff` command or the `<base>...HEAD` range), the working directory,
  and the purpose.
  Ask it to extract:
  - the actual change, per file;
  - the intent, in one or two sentences;
  - non-obvious decisions and their rationale;
  - new or changed unit test cases;
  - anything noticed but not addressed.
  Confirm the agent can run the command; if it cannot, run the diff yourself and pass the text.
- Bug: confirm the root cause via the code path and a repro; record the exact steps and output.
- Feature: check it is not already implemented or requested; ground it in a concrete situation.
- Read the source for any path, key, or API shape the draft will name.
  Do not recall it.

## Motivation

Include motivation here only if the session already established it.
Otherwise leave it to the `Phase:Draft` loop, where you refine it with the user.

## Claim list

List every factual claim the draft will make, and mark each `verified` or `unverified`:
- `verified` — backed by a code read, a repro, or a command run.
- `unverified` — not yet checked.

Present the list to the user.
The user may mark a claim `verified` from their own knowledge; that counts.
Only `verified` claims may be stated flatly in the draft.
