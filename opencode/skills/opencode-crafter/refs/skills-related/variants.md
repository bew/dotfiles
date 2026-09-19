# Skill Variants

A skill variant is a skill derived from a base skill, living as a sibling directory
named `<base-name>-<suffix>` (see <./anatomy.md§skill-variants>).

A variant carries two companion files:
- `VARIANT` — declares its type and constraints (format below).
- `README.md` — explains the diff from the base skill to human readers.

Detection is by naming only: for a base skill `<base-name>`,
every sibling dir matching `<base-name>-*`.

## `VARIANT` file

- Known variant type: the file contains only the type token, e.g. `standalone`.
  Its constraints are looked up from the type spec.
- Unknown variant type: the file lists the variant's constraints, one per line.

Read the `VARIANT` file during propagation to learn how to update that variant.

## Known types

- `standalone` — <./standalone-anatomy.md>

## When to update

Variants are updated only via `Phase:PropagateChange`, after a base-skill change is validated.
- Known type: run the type's update flow.
- Unknown type: follow the constraints declared in its `VARIANT` file; if it is missing or unclear,
  ask the user.
