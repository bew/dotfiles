## Discussion views

Two chat formats show the evolving plan during the session.
Both use the same bullet style: goal inline on the first line, attached lines indented below.

### Focused view

Shown before each question round in `Phase:Draft` and `Phase:Discuss`.
Lists only the topics a question touches plus directly related ones
(merge candidates, parallel candidates, shared-component neighbours).

Goals are memory anchors only — no dependency lines.

```md
**Mentioned topics**:
- `{topic1}`: one-line goal for this topic.
**Related topics**:
- `{related-topic}`: one-line goal for this topic.
  Related because <why, e.g. merge candidate, shares a dependency>.
```

Skip unrelated topics — do _not_ dump all topics on every question.

When asking multiple question rounds in the same message, separate each focused-view + question
block with a `-----` line, so the reader can visually tell rounds apart.

### Whole-plan view

Whole-plan view used once, for confirmation, at the end of `Phase:Draft`.
It lists every topic, split at the provisional ordering-window boundary: topics expected inside the
window first, topics bound for the backlog after a labeled break.
Omit the break when every topic fits the window.
Once `$milestonesfile` exists, its `Dependency Graph` and `Backlog` sections replace this view.

```md
**Planned structure**:
- `{topic-a}`: goal for this topic.
  No dependency.
- `{topic-b}`: goal.
  Depends on: `{topic-a}`.
- `{topic-c}`: goal.
  Parallel with `{topic-b}`.
  Depends on: `{topic-a}`.

**Past the ordering window** (backlog):
- `{topic-d}`: goal.
  Bundles `{topic-x}` + `{topic-y}`.
  Depends on: `{topic-b}`, `{topic-c}`.
```

Edges shown here are chat-only for backlog-bound topics — the file records none until they are
promoted.
