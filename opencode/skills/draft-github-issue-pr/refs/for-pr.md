# Personal PR Shape

The base shape for a PR body.
The repo's required items are pinned on top; advisory repo hints never override this.
Load `bew-communication-style`.
One sentence per line.

Open with a greeting (`Hello!`).
Then lead with the motivation, in first person and in your own voice:
the problem or the wish that prompted the change ("I was staring at X and thought it would be nice
to see Y").
Then cover the change:
- **What changed** — the behaviour or capability, and the problem it solves.
  Derive it from the diff, not from a guess at intent.
  Enumerate the concrete details as bullets under a colon intro when there are several.
- **How it works** — the approach, and any non-obvious decision.
  Name real functions, files, and APIs.
- **How verified** — lead with what you tested by hand, then the real command(s) run and their
  result.
  List the unit tests covering the changed behaviour, if any exist.
- **Side notes** — optional.
  Findings noticed but not addressed, kept subordinate.

Keep it first-person and low-formality — this is a person talking, not documentation.
Keep casual asides in parentheses, and 1–3 smileys where they fit.
Do not pad.
