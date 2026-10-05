# Phase:IssueFirst

Draft and file the issue before the PR.
Only when `Phase:ContribGuidelines` found that the repo requires an issue and none exists.

## Base

Ask the user whether to base the issue on the finished PR text or on the session context.
When created now (before the PR draft), base it on the session context only — no PR text exists yet.
Draft it to its own file, following `Phase:Draft` rules (voice, structure, iteration).
Verify it as in `Phase:VerifyClaims`.

## File

- File only after explicit user go-ahead (`gh issue create`).
- Capture the issue number for `Phase:Submit`.
