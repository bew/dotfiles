# Phase:Review

In-context review pass over the full spec at `$specpath`.
No subagent — review happens in the same session.

## Review pass

Read full `$specpath` before starting.

Check each of the following, flag any issues:

- All Open Questions (per-section and Global) are either resolved or explicitly marked non-blocking
  with a one-line reason (or longer explanation if this is still in-flux).
- Introduction is prose (not skeleton placeholders)
- Terminology section (if present) is complete prose (not skeleton placeholders)
- If Terminology section exists: all terms used in spec are defined there before first use
- No terminology drift — single canonical name used everywhere for each concept
- Alternatives & Tradeoffs section present and honest (compares against simpler alternative)
- `## Global Open Questions` section is present at end of spec
- No empty `### Open Questions` subsections remain (Global section is exempt — it is always present)
- Any OQ entries present follow correct format (see <../spec-structure.md>)
- Prose in touched sections follows sentence-per-line format
- Status tag in H1 reflects current state

`FIXME:` / `TODO:` callouts are allowed — they signal work still to be done, not a review failure.
If a callout is not specific to its surrounding text, suggest moving it to Open Questions instead.

Report review findings to user as a short list: items that need attention vs. items that look good.
Work through fixes collaboratively before assessing readiness.

## Readiness assessment

Read <../spec-readiness.md> to evaluate whether spec qualifies for promotion.

After review pass is clean, assess readiness:
- If criteria met: update status tag to `[MAYBE-READY]` in `$specpath` H1
- Surface assessment to user with brief rationale

## Promotion offer

Promotion means the spec is considered stable reference material — design intent is settled enough
that it no longer needs to live in the work-in-progress area.
It does not mean implementation is done or the design will never change.

Only offer promotion if spec is assessed `[MAYBE-READY]` or better.

Offer: *Spec looks ready. Promote to `_SPECS/<slug>/`? This moves the directory and updates status to `[READY]`.*

If user confirms:
1. Read <../rename.md> — run `<skill-dir>/scripts/rename-spec $basedir/<slug>/ _SPECS/<slug>/`
2. Update H1 in `$specpath` (now at `_SPECS/<slug>/SPEC.md`) to `[READY]`
3. Update `$basedir`, `$specdir`, `$specpath` in session to reflect new location
4. Report new path to user

If user declines: leave in `_WIP_SPECS/`, status stays `[MAYBE-READY]`.

NOTE: `## Global Open Questions` entries default to **Non-blocking**.
If a review pass judges a Global entry as critical, escalate it to **Blocking**.

Do not offer promotion if any blocking Open Questions remain unresolved.
