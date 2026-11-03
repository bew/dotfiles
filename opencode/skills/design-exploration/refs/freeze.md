# Freezing a topic

Invoked from <./phases/explore.md> (`## Conclude a topic`) and <./phases/wrap.md> (`## Freeze`).
It owns the whole freeze operation, so neither phase restates it.

## A freeze needs discussion

`frozen` means settled: the user has answered concrete proposals in that topic.
Nothing else earns it.

- A topic with no file of its own was never opened: it is `unexplored`.
- A topic with a file but no discussion round in it — nothing but the leading description, or
  agent-authored candidates nobody answered — is `unsettled`.

A topic with discussion that still holds an unanswered `(active)` direction does not freeze yet.
Surface that direction inline; the user answers it, defers it as `(deferred)`, or rejects it into
`## Rejected directions` first.

## Ask before writing a contradictory status

When the user calls a topic settled while nothing in it was discussed, surface the contradiction
inline and ask, before any status write:

- name the topic and what is missing — no file, or no answered direction;
- offer the outcomes the vocabulary allows: open it for discussion now, or park it for a later
  session under the status its case gives (see `## Write the status`);
- never offer `frozen` in that set, and never record `frozen` on that answer.

An answer that opens the topic returns to `Phase:Explore` (`## Start or resume a topic`).
An answer that parks it writes that status per `## Write the status`, and states in one line why the
topic is not `frozen`.
An unanswered ask parks the topic the same way; at `Phase:Wrap`, silence is re-asked instead
(`SKILL.md` — *Interaction conventions*).

## Write the status

A frozen topic:
- `dedicated`: mark the topic `frozen` in the brief index.
- `adhoc`: set the file's H1 tag to `[frozen]`.

A parked topic:
- with a file — record it `unsettled`: its brief-index row in `dedicated`, its H1 tag in `adhoc`.
- with no file — record it `unexplored`: its brief-index row in `dedicated`, added when absent; in
  `adhoc` the `(unexplored)` line per <./artefacts.md>.

Leave unresolved items under `Open threads` untouched: a freeze never resolves a thread and never
rewords one.
