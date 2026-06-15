# Steps, Phases, Headers

## What are phases

A **phase** is a named, sequential stage of a workflow with a bounded scope, a clear entry trigger, and an explicit exit signal.

Use phases when an artefact has 3+ distinct concerns that should not all be in context at the same time — e.g. gather inputs, then produce output, then review/ship.
For simpler artefacts, a flat numbered **Steps** list is sufficient.

## When to use named steps or phases
<!-- §when-named-steps -->

Use named steps or phases when **any** of the following:

- 3+ top-level phases or steps in the artefact
- 3+ steps within any single phase
- Any step references another step (even if fewer than 3 items, positional refs become unreliable)

**Named steps**:
Def with: `1. **Setup**` (bold name inline in list)
Ref with: `*Setup*` (italic)

Example:
```md
1. **Setup** — read inputs, validate, load files
2. **Review** — evaluate criteria, surface gaps, apply fixes
...
If input missing: stop. Do not proceed to *Review*.
If criteria loop finds new gaps: return to *Review*.
```

**Named phases**:
Def with: ``## N. `Phase:Foo` — short description`` header with body
Ref with: `` `Phase:Foo` ``

Example:
```md
## 2. `Phase:Review` — evaluate criteria, apply fixes

...phase body...

Return to `Phase:Setup` if inputs change.
```

## Naming convention

**Phase names**: `Phase:<Name>` format — title-case, no spaces, e.g. `Phase:Discover`, `Phase:Draft`.
Names: short verb/noun — `Discover`, `Draft`, `Review`, `Ship`, `Setup`, `Output`.
Avoid generic names: ~~`Phase1`~~, ~~`Phase:Processing`~~.

**Step names**: plain title-case word(s), no prefix — `Setup`, `Review`, `Output`.
Avoid generic names: ~~`Step1`~~, ~~`Processing`~~.

## Named headers

Add an anchor to any header you need to reference from elsewhere — opt-in, not mandatory.

**Definition** — HTML comment on the line immediately after the heading:

```md
### Required phases still benefit from extraction
<!-- §req-phases-can-extract -->
```

**Reference** — use the slug inline:
- Same file: <§req-phases-can-extract>
- Cross-file: <./other/file.md§req-phases-can-extract>

**Slug format**: kebab-case, descriptive but no filler words — derive from heading meaning, not verbatim heading text.
Encode modality when it matters: a heading about something that *can* happen differs from one about something that *always* does — the slug should reflect that (`§req-phases-can-extract` not `§req-phases-extract`).
Good: `§req-phases-can-extract`, `§phase-gates`, `§optional-phases`
Avoid: `§the-required-phases-that-can-be-extracted`, `§rp-ext`

## Phase gates

A phase gate is an exit signal at the end of each phase's instruction block.
It lets the user inspect mid-flight work before the agent advances.

**Where**: last line of each phase's section.
**Why**: prevents agent from racing through phases; creates a natural checkpoint for user review.

Form — informational only, do not use the `question` tool:

```md
Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)
```

Rule: agent never auto-advances. Always wait for user confirmation before entering next phase.

## Optional phases

Mark optional phases with a `_(if needed)_` suffix in the overview list.
Include a skip condition immediately before or inside the phase entry.

```md
## 3.5. `Phase:Scripts` _(if needed)_ — script POC & iterate via subagent

Skip this phase if artefact does NOT have a script.
```

Use a fractional number (e.g. `3.5`) to preserve ordering without renumbering required phases.

## Reference integrity

Rules for `§slug` anchors and references — enforce when writing or reviewing artefact files.

- Every `§slug` reference must have a matching `<!-- §slug -->` anchor in the target location.
- Same-file ref (`§slug`): anchor must exist in the same file.
- Cross-file ref (<./path/to/file.md§slug>): target file must exist and contain `<!-- §slug -->`.
- Anchors with no reference anywhere are dead weight — remove or add a reference.
- Add an anchor only when a reference to it exists (opt-in, not mandatory on all headers).

---

For skill-specific guidance (SKILL.md structure, crafter integration): read <./skills-related/skill-phases.md>.
