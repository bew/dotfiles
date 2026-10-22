# Spec Readiness

Criteria for assessing whether a spec is ready to leave the draft state.

## Status tags

| Tag | Meaning |
|---|---|
| `DISCOVERY` | Inputs being gathered; discovery notes live in `DISCOVERY.md` |
| `EXPLO` | Deep design maturation delegated to `design-exploration` |
| `DRAFT` | Active work-in-progress; sections may be skeletal or incomplete |
| `MAYBE-READY` | Passes readiness criteria; awaiting author confirmation or final review |
| `READY` | Confirmed ready |
| `ABANDONED` | No longer being pursued; lives under `SPEC-KO-<slug>/` |

The H1 of each spec file carries its status tag; `manage-spec` keeps the tag, the file that
carries it, and the directory name in sync — read <./lifecycle.md>.
Never edit the tag or move the directory by hand.

## Readiness criteria

A spec is `MAYBE-READY` when **all** of the following hold:

1. All content sections are fully written — no `SKELETON TODO` placeholders remain
   (Introduction and Terminology, if present, included).
2. All `FIXME:` / `TODO:` callouts have been addressed or converted to Open Questions entries.
3. All Open Questions entries (per-section and Global) are marked **Blocking** or **Non-blocking**.
4. No **Blocking** Open Questions remain unresolved.
   Global entries default to **Non-blocking**; they must be escalated to Blocking explicitly during review to block readiness.
5. Alternatives & Tradeoffs section is present and compares against at least one simpler alternative.
6. Naming discipline holds: no synonym drift.
   If Terminology section exists, all terms are defined there before use.

A spec does NOT need to be implementation-complete to be `MAYBE-READY`.
It needs to be design-stable enough that an implementer could start from it.

`READY` adds one gate on top of those criteria: the author (user) has reviewed the spec and
explicitly agreed it reflects current design intent.
`MAYBE-READY` is stamped before that agreement, so this gate blocks the move to `READY`, not the
move to `MAYBE-READY`.

## What "ready" does NOT mean

- All Open Questions resolved — non-blocking questions may remain open.
- Implementation exists or is planned imminently.
- The design will never change — specs can be updated after the transition to ready.

## Transition to ready

Moving to ready means the spec is considered stable reference material.
Run `<skill-dir>/scripts/manage-spec ready` from `$specdir`.
Take the new paths from its output.

Going back is allowed when the design reopens — `manage-spec draft` moves it back.
