# Phase:Submit

File the artefact (the PR, or the issue on an issue-only run).
Draft-only unless the user gives explicit go-ahead.

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

File only after explicit user go-ahead.
Never file automatically.

## gh auth

Assume `gh` is authenticated.
Do not check upfront.
Only handle an auth error if a `gh` command returns one.
On an auth error: stop, ask the user to re-authenticate (`gh auth login`), then retry.

## Keep the drafts

Leave the draft files on disk as the source of truth for further edits.
