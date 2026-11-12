# Follow Mode

Keep the capture current for the rest of the session.
Applies to `capture-task` and `capture-idea` captures made with follow enabled.

Follow binds to a single capture — the capture follow was enabled for.
A capture filed later in the session is not in follow mode unless follow is enabled for it.

## Invariant

At the end of every turn in which context about the subject changed, the capture reflects the
current session state.
Apply the updates silently: no confirmation prompt, no per-update narration in the reply.

## Update triggers

- the user changes or rectifies the scope, the approach, or a diagnosis
- a decision is settled, or an approach is rejected
- a constraint or finding appears that changes how the work must be done
- an artefact the work will need is identified
- an open question is raised or resolved
- a blocker or prerequisite appears, clears, or changes

## Snapshot

Rewrite the capture's own sections so they read as if written now:

- description — the latest agreed intent, and why
- `Blockers`, `Open questions`, `Artefacts` — add when they appear, drop when they clear or turn
  out irrelevant
- drop a section that ends empty; never leave filler

Use `edit`, never `write`.
Keep `created-at` unchanged.
Maintain `depends-on` for an explicit dependency the user states after the write — same
`<kind>:<slug>` rules, sort, and ` & ` join as Setup and *Step:Scan*.
Drop a ref the user withdraws.
Rewrite the H1 only when a settled scope change makes the old intent wrong; keep any claim or
status tag (`[CLAIMED]`, `[DONE]`) on it.

## Decisions

This is the capture's `## Decisions` section — create it after the description when the first
line is recorded.
Record what the snapshot would otherwise lose: settled choices, rejected approaches, and
corrected diagnoses, one line each, with the reason.

- Curated list, not a log: merge related lines, supersede or rewrite a stale one.
- Keep the final takeaway; do not narrate the order of the exchange.
- A rejected approach stays — it stops the next session from retrying it.

## Scope

- Subject-relevant content only.
- No session recap, no tool chatter, no list of edits already visible in git.
- Never output the capture's content inline.

## Shaping only

Do not record execution progress.
If the session starts doing the work, follow still tracks intent and decisions only.

## Durability

Any context compression must keep the capture's path and this follow duty in the summary.
After a compression, re-read the capture before the next update.

## Edges

- PLAN mode: do not edit; state the pending change in the reply (the one allowed narration),
  then apply it once build mode is active.
- Several captures in follow mode in one session: keep each current, and never mix their content.
- The user ends follow: stop updating; the capture stands as the final record.
- No capture was written (the unrelated-idea "later" answer): there is no follow duty.
