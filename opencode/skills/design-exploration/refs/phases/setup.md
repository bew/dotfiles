# Phase:Setup — resolve identity & dir; write brief

## Resolve identity

Derive:
- `$name` — the design's human-readable name.
- `$slug` — the design's kebab-case slug.

Take both from context if present; otherwise ask.

## Resolve the exploration dir

Resolve `$explodir`:
- If the invoking context supplies an exploration dir, that's the candidate.
- Otherwise the candidate is `_WIP_EXPLORATIONS/$slug`.

Always confirm the candidate path with the user before creating it or writing files.
If `$explodir` does not exist, create it.
`$explodir` — the confirmed path.

## Seed the brief

Read <../artefacts.md> for the brief format.

If `$briefpath` exists: read it, refresh `Motivation` if the instructions changed,
keep the existing topic index.
Otherwise: distill the user's instructions into the brief's `Motivation`
(context, problem, scope, out-of-scope), and write `$briefpath` with an empty topic list.

Ready to move to `Phase:Explore`? (say 'next' or similar to proceed)