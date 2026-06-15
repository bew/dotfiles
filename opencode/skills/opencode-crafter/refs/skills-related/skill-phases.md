# Skill Phases — Skill-specific Guidance

## Structure in SKILL.md

List phases as a numbered overview near the top of `SKILL.md`.
Each entry: number, phase name in inline code, em dash, one-line description.

```md
1. `Phase:Discover` — gather inputs; confirm requirements
2. `Phase:Draft` — write skeleton; fill sections iteratively
3. `Phase:Review` — review with user; assess readiness
```

For each phase, include a section heading in `SKILL.md`. Phase instructions may live inline or in a dedicated ref file — let the progressive disclosure conditions decide which.

## Progressive disclosure with phases
<!-- §progressive-disclosure-phases -->

Context accumulates as a skill's workflow progresses: each phase's ref file is loaded when that phase starts and remains in context for all subsequent phases. This means:
- Instructions for a future phase must NOT be in context yet — they add noise and clutter before they're relevant.
- Once loaded, a phase's file stays available — later phases build on earlier outputs/decisions already in context.

Extract a phase to `refs/phases/<name>.md` when **any** of the following:
- Phase instructions exceed ~20 lines
- Phase content is only needed from a certain point in the workflow onward
- Phase contains rules, examples, or edge cases not relevant to earlier phases

Keep inline in `SKILL.md` when phase instructions are short and needed for orientation from the start.

Always keep in `SKILL.md`:
- The phase overview list (needed at all times for orientation)
- A ``## N. `Phase:Foo` `` section heading per phase

When a phase is extracted, the section body is a single trigger line.

Example:
```md
## 2. `Phase:Draft` — Write skeleton; fill sections iteratively

When entering `Phase:Draft`: read <./refs/phases/draft.md> for full instructions.
```

### Required phases still benefit from extraction
<!-- §req-phases-can-extract -->

A phase being required does NOT mean it should stay inline.
When an agent is on `Phase:Draft`, instructions for `Phase:Review` are noise — even though review is always required later.
Extract all phases that meet the conditions above, regardless of whether they're optional.

## Crafter integration

### During `Phase:Discover`

For **new skills**: phases add significant structural overhead (multiple files, gates, reference triggers).
Before proposing phases, explain the tradeoff to user and confirm they want this structure.
Use the `question` tool for this confirmation — do not assume.

If confirmed: read this file & design phases together before drafting.
If declined (simple skill): a flat `Steps` list in `SKILL.md` is sufficient — do not add phases.

For **existing phased skills**: no confirmation needed — phases already in place.

### During `Phase:Review`

Check phased skills for:
- Phase overview list present near top of `SKILL.md`
- Each phase has ``## N. `Phase:Foo` — small description`` section heading in `SKILL.md`
- Extracted phases: single trigger line in `SKILL.md` body pointing to ref file; full instructions in `refs/phases/<name>.md`
- Phase gate present at end of each phase's section (inline body or ref file)
- Optional phases marked `_(if needed)_` with a skip condition
- Progressive disclosure conditions applied correctly
- Named steps used wherever required (see <../rules-for-steps-phases-headers.md§when-named-steps>)
