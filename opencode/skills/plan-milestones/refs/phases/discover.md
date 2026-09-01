## 1. `Phase:Discover` — read spec, identify capability boundaries

Read all files under `$specpath`.

Identify:
- Core behavioral requirements and explicit constraints.
- Anything marked uncertain, "to be confirmed empirically", or flagged as an assumption.
- Natural capability boundaries (a component or subsystem that can be delivered end-to-end
  before another starts).
- Shared components/subsystems that multiple other parts will depend on.
- Any features or subsystems that are clearly out of scope or deferred.
- The persistence layer: whether it is designed in the spec, or needs a design step.

If no readable content is found under `$specpath`: stop and tell the user.

Check whether `$milestonesfile` already exists.
- **No file** — create from scratch. Apply the ordering and grouping rules in `SKILL.md`.
  M1 is always a research milestone if any spec assumptions are unconfirmed.
- **File exists** — determine what changed or what the user wants to add/adjust.
  Read existing milestones; map them against the spec.
  Surface only the affected milestones for discussion — do not re-plan the whole file unless asked.
