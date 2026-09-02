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
Once `$milestonesfile` exists, its `Dependency Graph` section replaces this view.

```md
**Planned structure**:
- `{topic-a}`: goal for this topic.
  No dependency.
- `{topic-b}`: goal.
  Depends on: `{topic-a}`.
- `{topic-c}`: goal.
  Parallel with `{topic-b}`.
  Depends on: `{topic-a}`.
- `{topic-d}`: goal.
  Bundles `{topic-x}` + `{topic-y}`.
  Depends on: `{topic-b}`, `{topic-c}`.
```
