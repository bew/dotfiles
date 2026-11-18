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
- Issue, no investigation: read no source code.
  Record what the user observed, the exact steps, and any output or log line they supplied.
  The report stands without a fault location.
  If steps or output are missing, ask the user for them; never reconstruct them.
- Issue, investigation accepted ('dig in', or a later explicit ask): confirm the root cause via the
  code path and a repro; record the exact steps and output.
  For a feature, also check whether it is already implemented; ground it in a concrete situation.
- Reading conventions files and the issue/PR duplicate search are not source reads.
  The search runs before any issue body is written; its mechanics live in `Phase:Draft`.
- Read the source for any path, key, or API shape a PR draft will name.
  Do not recall it.
  For an issue, name a path only when the user supplied it or the investigation produced it;
  otherwise drop the detail.

## Motivation

Include motivation here only if the session already established it.
Otherwise leave it to the `Phase:Draft` loop, where you refine it with the user.

## Claim list

List every factual claim the draft will make, and mark each `reported`, `verified`, or `unverified`:
- `reported` — the user's own observation or supplied evidence.
  State it in first person as what they saw; never as a fault location, mechanism, or fix.
- `verified` — backed by a code read, a repro, or a command run.
- `unverified` — not yet checked.

Present the list to the user.
The user may mark a claim `verified` from their own knowledge; that counts.
`verified` claims are stated flatly.
`reported` claims are stated only as the user's observation.
`unverified` claims are hedged, or left out.
