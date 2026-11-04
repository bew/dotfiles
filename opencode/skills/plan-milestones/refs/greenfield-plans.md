# Greenfield plans

Load this file only once the plan is detected as greenfield (see `Important concepts` in
`SKILL.md`).
It covers the opening milestones, research placement, and CI placement.

## Opening milestones

- The first milestone scaffolds the project: dev env setup, a build that runs, and a smoke test.
  It is exempt from the single-concern rule — its concern is the build env working.
  A spike blocking the scaffolding goes first — see `Research placement` below.
- The smoke test exercises one real path end to end — it proves the toolchain, not the product.
  Its shape follows the project type:
  - backend or web app: a hello-world route or page;
  - CLI with subcommands: a `thetool hello` command wired so later subcommands slot in easily.
  Ask the user when the project type fits neither example, or when another first path proves more.
- The two milestones after the scaffolding stay very small — one concern each.
  Judge "small" qualitatively: its scope fits in a reader's head and its **Proof** runs quickly.
- A research milestone does not use up one of the two small slots.
- Sizing returns to normal after those two.
  Up to that point the project shape and internal structure are still in flux, so a big early
  milestone would be built on guesses.

## Research placement

On a greenfield plan a research milestone comes after the scaffolding, though not necessarily
directly after it — settle its slot with the user.
Exception: an assumption blocking the scaffolding itself puts the spike first; confirm with the
user.

## CI placement

The scaffolding smoke test is not the first testable, non-trivial output, so it does not anchor CI.
CI may land in the scaffolding milestone or at the first real deliverable — settle which during
`Phase:Discuss`.
