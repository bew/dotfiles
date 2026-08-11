---
name: diff-to-commits-drafts
description: |
  Load when the /diff-to-commits-drafts command triggers.
  Splits a diff into logical commits and drafts each commit message interactively,
  one group at a time.
metadata:
  maintainers: [bew]
---

The command has already resolved `Diff source` and `Working directory` into context.

## Overview

1. `Phase:Explore` — analyse diff via subagent
2. `Phase:Group` — propose groupings, iterate until confirmed
3. `Phase:Draft` — draft commit message per group, one by one
4. `Phase:Summary` — staging guidance for all groups

## 1. `Phase:Explore` — analyse diff via subagent

Read `Diff source` and `Working directory` from context (set by the command).

NOTE: Subagents do not inherit the parent's cwd — pass `Working directory` explicitly in the prompt.

Invoke the `explore-diff` subagent via the `task` tool with this prompt
(substitute resolved values):

> Diff source: `<diff source>`
> Working directory: `<working directory>`
> Purpose: commit grouping — split this diff into logical, self-contained commit candidates.
> For each concern: include label, what changed (specific), inferred intent,
> and representative files (list individual files when few, top-level dir when many).
> Keep summaries intent-focused and concise.

Wait for subagent to return.

If subagent reports `Empty diff. Nothing to analyse.`: output "Diff is empty — nothing to split." and stop.

Ready to move to `Phase:Group`? (say 'next' or similar to proceed)

## 2. `Phase:Group` — propose groupings, iterate until confirmed

From `Phase:Explore` output, propose a grouping of the diff into commits.

For each proposed group, show:
- Name — short, descriptive label
- Files/areas — which files or directories belong to this group
- Rationale — one-line explanation of why this is a coherent unit

Ask user to confirm, rename, merge, or split groups.
Iterate until user explicitly confirms the grouping.

NOTE: A group may span multiple concerns if user decides they belong in one commit.
Never advance to `Phase:Draft` without explicit user confirmation.

Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)

## 3. `Phase:Draft` — draft commit message per group, one by one

For each confirmed group in order (or all in one go, if requested):

1. Announce: "Drafting commit for group: **<group name>**".
2. Load the `draft-commit-message` skill.
3. Follow its steps — scope the diff to this group's files.
   Pass the group name as focus hint.
4. Complete the full draft-commit-message iteration loop until user confirms the message.
5. Record the confirmed subject line and full message for this group.
6. Proceed to the next group.

Do not advance to the next group until user confirms the current commit message.

Ready to move to `Phase:Summary`? (say 'next' or similar to proceed)

## 4. `Phase:Summary` — staging guidance for all groups

Output a recap table:

| Group | Commit subject |
|---|---|
| `<group 1>` | `<subject>` |
| `<group 2>` | `<subject>` |

Then, for each group, output the staging + commit commands:

```sh
# <group name>
git add <file1> <file2> ...
git commit <<'EOF'
<subject line>

<body if any>
EOF
```

Do not run any git commands automatically.
