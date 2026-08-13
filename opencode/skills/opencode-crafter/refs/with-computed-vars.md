# Skill with Computed Vars

Skills sometimes compute values mid-session used by multiple subsequent steps or phases
(e.g. a path, slug, or resolved directory).
These are **computed vars**, values the agent derives and carries forward.
(not to confuse with runtime inputs from user context, see <./with-precise-inputs.md> if needed)

## Declaration block

Declare all computed vars early in `SKILL.md`, before the first step/phase that uses them.
Use a bold label + definition list — not a `## section` heading.
Vars may not be fully defined here, only declared to exist.
Each remaining var will be fully defined in the step that computes it.

Should mention that vars should be output to context once known.

Example:
```md
**Vars used throughout**: (output them in context once known!)
- `$foo` — short description of what it holds.
- `$base` — resolved base path for <this thing>.
- `$barpath` — `$base/nested/static/dir`
```
(note: `$barpath` here is partially defined, will be fully defined once `$base` is defined)

Place the block:
- After phase overview list (if skill has phases).
- After `## Setup` (if skill uses precise inputs).
- Otherwise: top of body, before the first step.

## Defining vars

Each var is defined in the step/phase that computes it.
State derivation logic there; later steps reference by name, do not re-derive.

Example step defining `$slug` and `$specpath`:
```md
## Step 2 — Resolve spec path

Ask user for a short slug (kebab-case, e.g. `auth-flow`).
Derive:
- `$slug` — the confirmed slug.
- `$specpath` — `_WIP_SPECS/$slug/SPEC.md`
```

## When to declare a var

Declare when value is:
- Used in 2+ steps/phases, **or**
- Complex enough that repeating derivation would be error-prone.

Single-use simple values: keep inline, no var needed.

## Naming guidelines

- `$` prefix — signals computed token, not a literal string.
- Single lowercase word preferred: `$slug`, `$dir`, `$scope`.
- Paths: suffix `…path` (file/generic), `…root` (top-level dir); `…dir` is allowed:
  `$specpath`, `$draftpath`, `$configroot`, `$workdir`.
- Short wins: `$dir` over `$outputdir` when no ambiguity (short `$path` not allowed).
- Avoid shadowing env vars: `$HOME`, `$PATH`, `$USER`, `$PWD`, etc.

## Rules

- Declare every var in the block before first use.
- Each var's defining step must include derivation logic.
- Later steps reference by name — never re-derive from raw context.
- If a var cannot be resolved: stop & surface the error. Do not substitute silently.
