---
name: caveman-review
description: >
  Compressed code review comments. Cuts noise from feedback while preserving the actionable signal.
  Each comment is one line: location, problem, fix.
  When the context is already using caveman mode, and user requests a review, ask user whether this
  skill should be used.
---

Write code review comments terse and actionable.
One line per finding: Location, problem, fix.
No throat-clearing.


## Rules

**Format:** `L<line>: <problem>. <fix>.` — or `<file>:L<line>: ...` when reviewing multi-file diffs.

**Severity prefix (optional, when mixed):**
- `BUG:` — broken behavior, will cause incident
- `RISK:` — works but fragile (race, missing null check, swallowed error)
- `nit:` — style, naming, micro-optim. Author can ignore
- `Q:` — genuine question, not a suggestion

**Drop:**
- "I noticed that...", "It seems like...", "You might want to consider..."
- "This is just a suggestion but..." — use `nit:` instead
- "Great work!", "Looks good overall but..." — say it once at the top, not per comment
- Restating what the line does — the reviewer can read the diff
- Hedging ("perhaps", "maybe", "I think") — if unsure use `Q:`

**Keep:**
- Exact line numbers
- Exact symbol/function/variable names in backticks
- Concrete fix, not "consider refactoring this"
- The *why* if the fix isn't obvious from the problem statement


## Examples

Bad: "I noticed that on line 42 you're not checking if the user object is null before accessing the email property. This could potentially cause a crash if the user is not found in the database. You might want to add a null check here."
Good: `L42: ❌ bug: user can be null after .find(). Add guard before .email.`

Bad: "It looks like this function is doing a lot of things and might benefit from being broken up into smaller functions for readability."
Good: `L88-140: nit: 50-line fn does 4 things. Extract validate/normalize/persist.`

Bad: "Have you considered what happens if the API returns a 429? I think we should probably handle that case."
Good: `L23: 🤔 risk: no retry on HTTP 429 (TooManyRequest). Wrap in withBackoff?`

## Auto-Clarity

Drop terse mode for: security findings (CVE-class bugs need full explanation + reference), architectural disagreements (need rationale, not just a one-liner), and onboarding contexts where the author is new and needs the "why".
👉 In those cases write a normal paragraph, then resume terse for the rest.

## Boundaries

Reviews only — does not write the code fix, does not approve/request-changes, does not run linters.
"stop caveman-review" or "normal mode": revert to verbose review style.
