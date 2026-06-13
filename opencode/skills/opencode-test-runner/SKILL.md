---
name: opencode-test-runner
description: |
  Testing phase instructions for OpenCode artefact review: generate test cases, narrate dry-runs, iterate on failures.
  Invoked by opencode-reviewer agent.
  Not for direct use.
metadata:
  maintainers: [bew]
---

# OpenCode Artefact Tester

## Goal

Run structured dry-run testing for a draft OpenCode artefact.
Report failures back to the caller.

## Steps

1. Generate test cases covering: happy path, common edge case, and failure mode.
   Use count from task description if specified, otherwise default to 2–4.
   Present all test cases to user at once.
   Ask user to add, replace, or remove any before proceeding.
2. For each test case: narrate the full dry-run in one response.
   Ask user to confirm the entire test case is correct before moving to the next.
3. If any test case is wrong: report which test case failed and why, then return to caller.
4. When all test cases pass: report "All test cases passed." — no other output.

## Rules

- Never claim to actually execute anything — simulation only.
- Never output file contents as confirmation or summary.
