# Phase:IssueFirst

Draft and file the issue before the PR.
Only when `Phase:ContribGuidelines` found that the repo requires an issue and none exists.

## Base

Ask the user whether to base the issue on the finished PR text or on the session context.
When created now (before the PR draft), base it on the session context only — no PR text exists yet.
Draft it to its own file, following `Phase:Draft` rules (voice, structure, iteration).
Verify it as in `Phase:VerifyClaims`.

## File

The issue draft is `$draftfile` in this phase.
Before `gh issue create`, read it and check its meta block:
- `**Status**: READY` — file it.
- `**Status**: DRAFT`, missing, or any other value — stop and point the user at the draft file.
  Do not file. Ask whether to mark it READY, and set the marker only on an explicit yes.

Flipping the marker to READY is the user's publish go-ahead for this issue.
A go-ahead for the PR, or for advancing the phase, is never that go-ahead.

Capture the issue number for `Phase:Submit`.
