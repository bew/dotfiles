## Task file format

One file per work unit, written for every milestone in the scoping boundary — in `Phase:Finalize`,
or when scoping a later batch (see <./continuing-a-plan.md>).
A milestone with several work units gets several task files.

This file owns the task-file naming:
`$taskfilename` = `TASK-<namespace>-M<N>-<task-slug>.md`.
`<task-slug>` is the kebab-case form of the work unit's task title — the same title used as link
text in the milestone's **Tasks** field.

`<namespace>` groups the related tasks.
Reuse the namespace of the `TASK-*` files already in `$taskdir`.
Otherwise derive it from the plan source: the spec or plan directory name, with a leading
`SPEC-<STATUS>-` segment stripped — e.g. `SPEC-DRAFT-wrapkit-system` → `wrapkit-system`.
When the plan is not spec-driven, use the plan directory name.
Confirm a derived value with the user before writing.
Never change `$namespace` after first use.

The file opens with this frontmatter, above the H1:
```md
---
created-at: <YYYYMMDDThhmm>
---
```

Add `depends-on` directly after `created-at`, only when this task genuinely needs other work
finished first: one entry per dependency, joined with ` & `.
`task:<slug>` — the other task's `$taskfilename` with the `TASK-` prefix and `.md` suffix dropped.
When the blocker is a whole milestone rather than a specific task, name it in the body's opening
paragraph instead of inventing a ref kind.
Units run one at a time, in the **Tasks** order, so a shared compile surface is not a dependency.
Omit the key otherwise.

The body:
```md
# TASK: <task title>

<One-line statement of the task at hand.>

<Short paragraph: what to do and why.
Keep it self-contained for the immediate work.
Defer everything else to the related files — never duplicate the spec, the Goal, or the Proof.>

## References

- `<$milestonesfile>` — milestone `M<N>`: Goal, Proof, ordering reason.
- `<$specpath>` — spec context.
```
