# Spec Readiness

Criteria for assessing whether a spec is ready to leave `_WIP_SPECS/`.

## Status tags

| Tag | Meaning |
|---|---|
| `DRAFT` | Active work-in-progress; sections may be skeletal or incomplete |
| `MAYBE-READY` | Passes readiness criteria; awaiting author confirmation or final review |
| `READY` | Confirmed ready; lives in `_SPECS/` |
| `ABANDONED` | No longer being pursued; kept for reference |

Status tag lives in H1: `# [STATUS] <Name>`
Update in-place with `edit` whenever status changes.

## Readiness criteria

A spec is `MAYBE-READY` when **all** of the following hold:

1. Introduction is complete prose — no placeholders, no skeleton headings.
   Terminology section (if present) is also complete prose.
2. All `FIXME:` callouts have been addressed or converted to Open Questions entries.
3. All Open Questions entries (per-section and Global) are marked **Blocking** or **Non-blocking**.
4. No **Blocking** Open Questions remain unresolved.
   Global entries default to **Non-blocking**; they must be escalated to Blocking explicitly during review to block readiness.
5. Alternatives & Tradeoffs section is present and compares against at least one simpler alternative.
6. Naming discipline holds: no synonym drift.
   If Terminology section exists, all terms are defined there before use.
7. Author (user) has reviewed the spec and explicitly agreed it reflects current design intent.

A spec does NOT need to be implementation-complete to be `MAYBE-READY`.
It needs to be design-stable enough that an implementer could start from it.

## What "ready" does NOT mean

- All Open Questions resolved — non-blocking questions may remain open.
- Implementation exists or is planned imminently.
- The design will never change — specs can be updated after promotion.

## Promotion

`_WIP_SPECS/<slug>/` → `_SPECS/<slug>/` means the spec is considered stable reference material.
Use <./rename.md> to move the directory (handles git-tracked and plain directories).
After move, update H1 status tag to `[READY]`,
remove the skill loader meta-paragraph (between H1 and first section),
and update session vars.

Demotion (`_SPECS/` → `_WIP_SPECS/`) is allowed if design reopens —
update tag to `DRAFT` and restore the skill loader meta-paragraph after H1
(exact text in <./phases/draft.md> H1 format).
