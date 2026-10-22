# Phase:Review

In-context review pass over the full spec at `$specpath`.
No subagent — review happens in the same session.

## Review pass

Read full `$specpath` before starting.

If the user says 'tell me more' (or a listed alias): answer in output only — make no spec edits.
Pause until the user resumes.

Check each of the following, flag any issues:

- All Open Questions (per-section and Global) are either resolved or explicitly marked non-blocking
  with a one-line reason (or longer explanation if this is still in-flux).
  Deferred OQs are intentionally retained during drafting;
  a deferred Blocking OQ still blocks readiness until resolved.
- All content sections are fully written — no `SKELETON TODO` placeholders remain
  (Introduction and Terminology, if present, included)
- If Terminology section exists: all terms used in spec are defined there before first use
- No terminology drift — single canonical name used everywhere for each concept
- No project-global doc content restated — concepts and terms documented there
  are referenced, not redefined
- Gaps are inline-defined and recorded; promoted gaps carry a `task-capture-handoff` capture
- Alternatives & Tradeoffs section present and honest (compares against simpler alternative)
- `## Global Open Questions` section is present at end of spec
- No empty `### Open Questions` subsections remain (the Global section is exempt while the spec is
  in progress — it is pruned only when the spec reaches `READY`, see *Transition to ready*)
- Any OQ entries present follow correct format (see <../spec-structure.md>)
- Prose in touched sections follows sentence-per-line format
- `manage-spec` output agrees with the file: the H1 status tag and the loader paragraph match the
  state the tool reports.
  Both are tool-owned — report a mismatch instead of editing them to "fix" it.

`FIXME:` / `TODO:` callouts are allowed — they signal work still to be done, not a review failure.
By contrast, a leftover `SKELETON TODO` placeholder is a review failure — it means a section was never filled.
If a callout is not specific to its surrounding text, suggest moving it to Open Questions instead.

Report review findings to user as a short list: items that need attention vs. items that look good.
Work through fixes collaboratively before assessing readiness.

## Readiness assessment

Read <../spec-readiness.md> to evaluate whether the spec qualifies for `MAYBE-READY`.

After review pass is clean, assess readiness:
- If criteria met: run `<skill-dir>/scripts/manage-spec maybe-ready` from `$specdir`
- Surface assessment to user with brief rationale

## Transition to ready

Transition means the spec is considered stable reference material — design intent is settled enough
that it no longer needs to live under the work-in-progress prefix.
It does not mean implementation is done or the design will never change.

Only offer the transition if spec is assessed `[MAYBE-READY]` or better.

Offer: *Spec looks ready. Transition it to ready with `manage-spec ready`?*

If user confirms:
1. Read <../lifecycle.md> — run `<skill-dir>/scripts/manage-spec ready` from `$specdir`
2. Take the new `$specdir`, `$specpath` from the printed `Session vars`
3. Prune `## Global Open Questions` if it holds no entries — a READY spec no longer carries it

`manage-spec` also updates the H1 tag and removes the skill loader meta-paragraph.
Do not repeat those edits by hand.

If user declines: stay in the work-in-progress state, tag stays `[MAYBE-READY]`.

NOTE: `## Global Open Questions` entries default to **Non-blocking**.
If a review pass judges a Global entry as critical, escalate it to **Blocking**.

Do not offer a transition to ready if any blocking Open Questions remain unresolved.
