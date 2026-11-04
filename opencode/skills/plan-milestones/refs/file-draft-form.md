## Milestone file — Draft form

The milestone file is initially created in this simpler form at the end of `Phase:Draft`,
before in-depth discussion about the plan.

- Header: `## <topic> (draft)` (becomes `## M<N> — <topic> (draft)` after numbering
  in `Phase:Discuss`).
- Fields: **Goal** (filled from the settled draft) and **Ordering reason**, which starts
  as `(pending ordering)` when the order is not yet settled.
  If draft already exposed an initial ordering, record it here from the start.
- No **Finished**, **Proof**, or **Tasks**.

Topics parked in the backlog follow the backlog appendix in <./file-format.md>: a bullet with the
topic name and its Goal, under a `## Backlog (draft)` header after the last milestone entry, with
`(draft)` after the topic name.
A topic whose ordering the user has already constrained carries its `Pinned:` line from the start.

Example:
```md
## {checkout-core} (draft)

**Goal**: `ghh` checks out a PR branch with correct named-remote tracking.

**Ordering reason**: (pending ordering)
```
