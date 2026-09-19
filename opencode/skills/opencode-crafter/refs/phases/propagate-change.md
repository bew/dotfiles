# Phase:PropagateChange — propagate a validated change to skill variants

Run after `Phase:Review` for updates, only when the updated skill has variants.
A variant is any sibling skill named `<base-name>-<suffix>`
(see <../skills-related/anatomy.md§skill-variants>).
Read <../skills-related/variants.md> for the `VARIANT` format and known types.

## Skip condition

Skip unless: the updated artefact is a skill, and at least one `<base-name>-*` sibling exists.
If there are no variants: end the session.

## Steps

1. List the updated skill's variants — sibling dirs matching `<base-name>-*`.
2. Read each `VARIANT` file — it tells you how to update that variant (type + constraints).
3. For each variant, ask the user whether to propagate. Never auto-propagate.
4. Known type (e.g. `standalone`): run the type's update flow —
   `Phase:Classify` → `Phase:Discover` → `Phase:Draft` → `Phase:Review`.
   The variant's `Phase:Discover` computes the semantic diff against the base
   and filters each change against the variant's constraints.
5. Unknown type: update following the constraints declared in its `VARIANT` file.
   If the `VARIANT` file is missing, or you are unsure, ask the user.

## Rules

- Never propagate without explicit user confirmation.
- Propagate only changes compatible with the variant's constraints.
- If a change cannot be mirrored (e.g. base gained a `scripts/` dir): ask the user.
