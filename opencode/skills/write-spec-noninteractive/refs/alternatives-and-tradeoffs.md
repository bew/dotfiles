# Alternatives & Tradeoffs

**Scope:** compare whole-spec with alternative directions.
For localized alternatives within the chosen direction (affecting only one-two sections),
place them in the optional section 8 instead.

Do not go deep into alternative directions — mention them and their tradeoffs
only if they were discussed with the user during discovery.
This section is a concise comparison, not an exhaustive exploration.

## Single proposed design vs simpler alternative

1. Show simplest viable alternative in code.
2. List advantages of plain alternative.
3. List advantages of proposed design.
4. List costs of proposed design.
5. State rough heuristic for when to use each.

## Multiple competing designs

- Give each option a short label (e.g. **Option A — session wrapper**).
- For each: show minimal code sketch, list advantages, list costs.
- End with **Decision criteria**: name concrete conditions under which each option wins.
  Avoid "it depends" without specifying what it depends on.
- If genuinely unresolved: move to Open Questions.
