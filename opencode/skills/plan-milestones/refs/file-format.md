## Milestone file format

The file starts with a **Sources** section and the **dependency graph**, then **Out of Scope**,
then the milestone entries, and ends with a **Backlog** appendix for topics not yet ordered.

```md
## Sources

- Spec: `<$specpath>`
- Related: <other docs/URLs/context referenced during discovery, if any — omit if none>
```

Written once, when the file is first created at the end of `Phase:Draft`.
Updated later only if the user points to a new spec source or related doc for an added milestone.

The **dependency graph** section comes next.
Same style as the whole-plan view (see <./discussion-views.md>); milestone numbers are appended
to the topic names.
The graph is created at the end of `Phase:Draft`; its header carries a `(draft)` marker
(the bullets carry no marker).
Numbers are appended in `Phase:Discuss`, and only for the milestones inside the ordering window.
Milestones outside that window live in the **Backlog** instead — they have no numbers and no
edges.
Discussion may move topics across that boundary in either direction.
`Phase:Finalize` strips the draft markers.

```md
## Dependency Graph (draft)

- `{topic-a}` (M1): goal.
  No dependency.
- `{topic-b}` (M2): goal.
  Depends on: `{topic-a}`.
```

After the dependency graph, an **Out of Scope** section lists anything deliberately descoped or
deferred — omit this section entirely if there is nothing to list.

```md
## Out of Scope

- <item>: <why it's descoped/deferred>.
```

Populated from items surfaced as out-of-scope in `Phase:Discover`, and any later explicit
descope decision made during `Phase:Discuss`.

A `----` line separates the header sections (Sources, Dependency Graph, Out of Scope) from the
first milestone entry.
A second `----` line separates the last milestone entry from the **Backlog** appendix.

Milestone entries exist in two forms: the draft form and the final form.
The draft form, produced at the end of `Phase:Draft`, is specified in <./file-draft-form.md>.
The final form, produced in `Phase:Finalize`, is specified in <./file-final-form.md>.

Both forms share the following field definitions and prose style, in order:

1. **Goal** — one or two sentences.
   What capability exists after this milestone that didn't before.
   Functional and behavioral description only — no implementation details.

2. **Ordering reason** — one or two sentences.
   Why this milestone is placed here in the sequence.
   Captures the dependency or phase logic so future readers don't need the full discussion context.
   Required only for milestones inside the ordering window — backlog entries carry none.

3. **Finished** — list of components, subsystems, or important behaviors that are fully complete
   (per current spec) after this milestone.
   Omit anything still in progress — do not mention it at all.
   Omit this field entirely if nothing reaches completion in this milestone.

4. **Proof** — bullet list of concrete, observable steps to confirm the milestone is done.
   Each bullet is "run X, observe Y".
   Must be executable without ambiguity.

5. **Tasks** — the milestone's work units, in one of two states.
   Scoped: one link per work unit, in natural order.
   Link text is the task title: `- [TASK: <task title>](<$taskfilename>)`.
   Rough: plain bullets of task ideas under the `**Tasks** (rough):` label, with no task-file links.
   Which state applies is set by the milestone's place relative to the scoping boundary
   (see <./phases/finalize.md>).

6. **Future work** — optional, one or two sentences.
   Points to something in the **Out of Scope** section that this milestone's output would
   eventually support or relate to, so a future reader can connect the two.
   Omit if there is none.

Prose style applies file-wide (Out of Scope bullets, Sources, milestone fields, etc.):
each sentence starts on a new line within the same paragraph/bullet.
Multiple sentences never appear on the same line.

An aside that isn't part of the main description — e.g. flagging that a milestone can run in
parallel with another, or pointing to related future work — is written as a standalone
`NOTE: ...` line, set apart from the surrounding prose.
This is not for ordinary cross-references (`M<N>`, `` `{topic}` ``), which stay inline as usual.

## Backlog appendix

After the last milestone entry and its `----` line, a **Backlog** section lists the topics planned
but not yet ordered — omit it entirely when every milestone fits the ordering window.

```md
----

## Backlog (draft)

- `{topic-c}` (draft): goal.
- `{topic-d}` (draft): goal.
  Pinned: must land before `{topic-b}`.
```

Each entry is one bullet: the topic name in backticks and its Goal.
The `(draft)` marker follows the topic name and is stripped in `Phase:Finalize`.
No numbers, no dependency edges, and none of the milestone fields — a backlog entry is not yet
a milestone.
Grouping heuristics apply to backlog entries too (see `Grouping heuristics` in `SKILL.md`);
they may be regrouped when they are promoted and actually planned.

A `Pinned:` line under an entry records an ordering constraint the user already knows about.
It is free-form prose, written once, and consumed at promotion: its content moves into the
promoted milestone's Ordering reason.
A pin that contradicts the milestones already ordered is surfaced to the user, not folded in
silently.

A plan written before this layout may carry its backlog next to the dependency graph.
Leave it there while working on that file, and move it to the appendix only when the plan is
rewritten.
