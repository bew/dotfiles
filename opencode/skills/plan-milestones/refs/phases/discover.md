## 1. `Phase:Discover` — read spec, identify capability boundaries

Read all files under `$specpath`.

Identify:
- Core behavioral requirements and explicit constraints.
- Anything marked uncertain, "to be confirmed empirically", or flagged as an assumption.
- Natural capability boundaries (a component or subsystem that can be delivered end-to-end
  before another starts).
- Shared components/subsystems that multiple other parts will depend on.
- Any features or subsystems that are clearly out of scope or deferred — track these for the
  file's **Out of Scope** section (see <../file-format.md>).
- The persistence layer: whether it is designed in the spec, or needs a design step.
- Any docs/URLs referenced alongside `$specpath` (linked specs, related tickets, prior art) —
  track these for the file's **Sources** section (see <../file-format.md>).

Before leaving this phase, cross-check every spec section/table row against the draft topic
list: for each requirement found, confirm it maps to at least one topic (existing or new), or
is explicitly listed as out of scope/deferred.
Do this now — do not defer it to an ad-hoc follow-up pass after milestones are finalized.

If no readable content is found under `$specpath`: stop and tell the user.

Check whether `$milestonesfile` already exists.
- **No file** — create from scratch. Apply the ordering and grouping rules in `SKILL.md`.
  M1 is always a research milestone if any spec assumptions are unconfirmed.
- **File exists** — determine what changed or what the user wants to add/adjust.
  Read existing milestones; map them against the spec.
  Surface only the affected milestones for discussion — do not re-plan the whole file unless asked.
