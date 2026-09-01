## Milestone file format

The file starts with a **dependency graph** section before any milestone entry.
Same style as the whole-plan view (see <./discussion-views.md>); milestone numbers are appended
to the topic names.
The graph is created at the end of `Phase:Draft`; its header carries a `(draft)` marker
(the bullets carry none). Numbers are appended in `Phase:Discuss`.
`Phase:Finalize` strips the draft markers.

```md
## Dependency Graph

- `{topic-a}` (M1): goal.
  No dependency.
- `{topic-b}` (M2): goal.
  Depends on: `{topic-a}`.
```

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

3. **Finished** — list of components, subsystems, or important behaviors that are fully complete
   (per current spec) after this milestone.
   Omit anything still in progress — do not mention it at all.
   Omit this field entirely if nothing reaches completion in this milestone.

4. **Proof** — bullet list of concrete, observable steps to confirm the milestone is done.
   Each bullet is "run X, observe Y".
   Must be executable without ambiguity.

5. **Tasks** — overview of the work units within the milestone.
   Kept as a placeholder until actual task files or tickets exist; replaced by links when they do.

Prose style: each sentence starts on a new line within the same paragraph.
Multiple sentences never appear on the same line.
