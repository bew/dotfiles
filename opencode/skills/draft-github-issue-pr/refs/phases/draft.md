# Phase:Draft

Write a review package into a concrete file, then iterate with the user.

## Draft file

`$draftfile` (default `/tmp/opencode_gh_drafts/<reponame>-<kind>-<slug>.md`) is a review package,
not the final body.
It holds:
- A `## Meta` block: target, the issue-first decision (required? auto-enforced or procedural, and
  when the issue is created), the template used, the pinned required items, the advisory items
  applied or skipped, the base branch, and the claim list from `Phase:PreDraft`.
- Then a `---` separator, and a `##` heading holding the PR title.
- Then the body, running to the end of the file.
  Write it inline — never wrap the body in a markdown code block.

The body follows the layered shape.
The meta block is review scaffolding and is never filed.

Derive `$draftfile`: `<reponame>` from `$repo`, `<kind>` from `$kind`, and `<slug>` as a short
kebab-case of the draft's topic.

## Structure

Build the body's shape by layering, not by picking one source:
1. Base — re-derive the subtype from `Phase:Classify`; read `<../for-<kind>-<subtype>.md>` if it
   exists, otherwise `<../for-<kind>.md>`.
   This is the personal guideline for the target: section order, extra sections, and voice.
2. Pin — add every item marked required in `$repotemplate` and `$repoguidelines`, with their exact
   headings, in the repo's order.
   Required items are never dropped or reordered.
3. Overlay — apply advisory repo items only where they do not conflict with the base.
   The personal guideline wins on order, extras, and voice.

Resolve any conflict in favour of a required repo item.

## Duplicate check (issues only)

Before writing an issue body, check whether the ask already exists.
Spawn a subagent to search the target repo's issues and PRs, open and closed, for the ask
(e.g. several queries via `gh search issues --repo <owner>/<name> "<term>"` and
`gh issue list --state all --search "<term>"`).
Never tick an "already suggested" acknowledgement checkbox unless that check actually ran.
When issues are related but distinct, mention them in the body with a short line on why each is a
different scope.

## Motivation

Identify and refine the motivation with the user, unless `Phase:PreDraft` already established it.
State it in one sentence: the problem, and why this change addresses it.

## Prose

Load `bew-communication-style` before writing any prose.

- One sentence per line.
- Preserve the user's voice, punctuation, and deliberate quirks.
  Do not "fix" their style.
- Name real APIs, keys, and paths only as the code shows them.
- Cut filler, restated tasks, and summary paragraphs.

## Iteration loop

This phase is a stop-and-wait loop, not one shot.

- Write the review package to `$draftfile`.
- Point the user at the file.
  Do not paste the whole body into chat.
- Stop and wait for feedback.
- On feedback, or after the user edits the file and says so: re-read the file,
  then revise and rewrite it.
- Re-check context, motivation, and tone each round.
  Repeat until the user confirms.
- Never overwrite a manual edit without reading it first.

## Findings

Keep incidental findings subordinate and explicit, e.g. a short note:
"Noticed while testing, not addressed here:".
Never let a side finding define the artefact's purpose.
