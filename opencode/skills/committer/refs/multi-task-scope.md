# Multi-task scope

The committer drafts a single commit, so multiple work items need a choice.

1. Ask the user via `question` tool — a MULTI-select listing the work items.
   Label each option with the work item, plus its files/areas when known.
   Add these trailing options:
   - "Multiple commits" — split the selected work items into separate commits.
   - "Abort" — stop.
2. Apply the answer:
   - "Abort" selected: stop. Wins over any other selection.
   - "Multiple commits": invoke the `diff-to-commits` skill, scoped to the selected work
     items' files/areas (all work items when none is individually selected). Stop this skill.
   - Work item(s) selected: set `Scope` to their files/areas (union); continue.
   - No selection: stop.
