# Phase:Submit

File the artefact (the PR, or the issue on an issue-only run).

## Publish gate

Before any `gh ... create`, read the draft file of the artefact about to be filed — its own
`$draftfile`, re-derived for that artefact, never an already-filed issue draft — and check its
meta block:
- `**Status**: READY` — proceed to File.
- `**Status**: DRAFT`, missing, or any other value — stop and point the user at that file.
  Do not file. Ask whether to mark it READY, and set the marker only on an explicit yes.

Only the marker of the artefact being filed authorises a file.
A READY issue draft never authorises the PR.
Flipping the marker to READY is the user's publish go-ahead.
A request to draft, push, branch, review, or advance the phase is never that go-ahead.

## File

Branch on `$kind`:
- PR: take the title from the `##` heading after the meta `---`, and extract the body after that
  heading into a temp file, then
  `gh pr create --title <title> --body-file <temp>`.
  Use the repo's PR title convention; if an issue was filed in `Phase:IssueFirst`, add
  `Closes #N` to the body.
- Issue (issue-only run): take the title from the `##` heading after the meta `---`, and extract the
  body after that heading into a temp file, then
  `gh issue create --title <title> --body-file <temp>`.
  Apply any required title convention from `$repotemplate` (e.g. a `[FEATURE]:` prefix).

File only after the publish gate passes.

## gh auth

Assume `gh` is authenticated.
Do not check upfront.
Only handle an auth error if a `gh` command returns one.
On an auth error: stop, ask the user to re-authenticate (`gh auth login`), then retry.

## Keep the drafts

Leave the draft files on disk as the source of truth for further edits.
