## Task file format

One file per milestone, created in `Phase:Finalize` when the task destination is task files.

This file owns the task-file naming:
`$taskfilename` = `TASK-<namespace>-M<N>-<topic>.md`.
`<namespace>` groups the related tasks; `<topic>` is the milestone topic, kebab-case.

The file opens with this frontmatter, above the H1:
```md
---
created-at: <YYYYMMDDThhmm>
---
```

Add `depends-on` directly after `created-at`, only when the milestone has explicit dependencies:
one `task:<slug>` per dependency, joined with ` & `.
`<slug>` is the other task's `$taskfilename` with the `TASK-` prefix and `.md` suffix dropped.
Omit the key otherwise.

The body:
```md
# TASK: <topic>

<One-line statement of the task at hand.>

<Short paragraph: what to do and why.
Keep it self-contained for the immediate work.
Defer everything else to the related files — never duplicate the spec, the Goal, or the Proof.>

## Tasks

<The milestone's work units.
One concrete line each.>

## References

- `<$milestonesfile>` — milestone `M<N>`: Goal, Proof, ordering reason.
- `<$specpath>` — spec context.
```
