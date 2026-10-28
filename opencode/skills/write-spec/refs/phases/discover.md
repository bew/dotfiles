# Phase:Discover

Gather all inputs needed to write the spec.
Do not begin drafting until all required inputs are answered or explicitly waived.

If the user says 'tell me more' (or a listed alias): answer in output only — make no spec edits.

## Required inputs

A settled design or an already approved plan waives `Phase:Explore`, never `Phase:Discover`.
Writing `SPEC.md` directly is the failure mode this phase prevents.

1. **Name** — what is this spec about? (may be a system, concept, protocol, format, etc.)
   The name might be temporary or not yet settled — that's fine;
   it can be renamed later (see Renaming and state changes below).
2. **Slug** — short kebab-case identifier derived from the name; used as `$slug` and directory name.
   Suggest a slug from the name; let user confirm or override.
3. **Problem** — what does it solve, and for whom?
4. **Inspirations** — any prior art, external systems, or prior sessions that shaped the design?

If user has supplied most context inline, confirm/waive inputs quickly
rather than asking each one explicitly.

Once all required inputs are answered or waived, proactively create the spec directory
and signal readiness to draft — do not keep asking follow-up questions.

## Project-global docs

Survey the docs that define project-global concepts and terms.
Read <../project-global-docs.md> for identification and the reference rule.

Confirm the candidate set with the user, then note concepts and terms already documented there.
The spec references those concepts and terms instead of restating them.

## Next phase

Always present both options to the user at the end of `Discover`:

- `Phase:Explore` — deep design maturation via the `design-exploration` skill.
- `Phase:Draft` — go straight to the spec skeleton.

Recommend one, with a one-line reason:

- Design genuinely uncertain (competing models, undefined central concept) → recommend `Explore`;
  a skeleton now would lock structure before the crux is resolved.
- Design settled enough to pick a section skeleton → recommend `Draft`;
  exploration adds a loop without changing the structure.

Recommend, but let the user choose.

The chosen phase moves the spec:
`Phase:Explore` runs `manage-spec explo`; `Phase:Draft` runs `manage-spec draft`.
Both run from `$specdir` and print the `Session vars` to adopt.

## Creating the spec directory

Once inputs are confirmed, run from the project directory:
```sh
<skill-dir>/scripts/manage-spec init <slug> [<title>]
```

It prints a `Session vars` block holding `$slug`, `$specdir`, and `$specpath`,
then the discovery-notes file to fill in, and creates `SPEC-DRAFT-<slug>/` in the `discovery`
state.
`SPEC.md` is seeded with the frontmatter block, the `[DISCOVERY]` H1, and the loader paragraph;
`DISCOVERY.md` is seeded with the `# Discovery notes` heading.
Use the printed values for the rest of the session.
Tell the user the printed `$specpath` before proceeding.

Every spec starts in the `discovery` state; later states are reached through `manage-spec`,
never by hand — read <../lifecycle.md>.

## Discovery notes

`DISCOVERY.md` is the file `init` seeded; record the confirmed inputs (name, problem, inspirations,
and any constraint the user stated) there, below the `# Discovery notes` heading.
These notes are `Phase:Draft`'s first input.
`DISCOVERY.md` stays editable from every later state — promoting the spec never moves or rewrites
it.
Do not write them into `$specpath`: `SPEC.md` holds the tag, the loader, and the spec body, and
`Phase:Draft` is what fills that body.

When the user already has a written brief or exploration material, point `DISCOVERY.md` at it
instead of copying it.

## Renaming and state changes

Read <../lifecycle.md> for the state table, the transition table, and the tool usage.
`manage-spec` owns the H1 tag, the loader paragraph, the frontmatter block, and the directory name.

Ready to move to `Phase:Explore` or `Phase:Draft`? (say 'next' or similar to proceed)
