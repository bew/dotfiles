---
name: draft-github-comment
description: |
  Draft a comment on an existing GitHub issue, PR, or discussion in bew's voice, then publish it
  only when the user says `publish` or `send it`.
  Load when asked to comment on, reply to, or "+1" an issue, PR, or discussion, to add repro
  evidence to someone else's report, or to clarify or answer a question in a thread.
  Modes: support (same wish + your own missing piece), evidence (repro, version, logs),
  clarify (answer, or clarify your own earlier comment).
  Not for drafting issue/PR bodies, and not for code review comments.
metadata:
  maintainers: [bew]
---

# Skill: draft-github-comment

## Goal

Produce a threaded GitHub comment that reads as a participant — a user who wants something —
and publish it only when the user says `publish` or `send it`.

## Setup — resolve inputs

Determine the following from whatever is in context (user message, prior context, session):

- **Target**: issue, PR, or discussion number, or its URL. Required — stop and ask if absent.
  A URL supplies `<n>` and its `owner/name`, which wins over the repo default.
  The URL shape gives the kind: `/issues/<n>`, `/pull/<n>`, `/discussions/<n>`,
  `orgs/<org>/discussions/<n>`.
  An org-level discussion URL carries no repo — skip the repo default and resolve by org login.
- **Repo**: `owner/name` of the repo holding the thread.
  Not needed for an org-level discussion.
  Skip the default when the target URL already names the repo.
  Default: the clone's parent when it is a fork, else the clone itself.
  Read `gh repo view --json nameWithOwner,parent`; the parent object has no `nameWithOwner`, so
  build it from `parent.owner.login` and `parent.name`.
  Ask if ambiguous.
- **Login**: the user's GitHub handle, from `git config github.user`. Required — stop and ask if
  unset.
- **Mode**: `support`, `evidence`, or `clarify`. Required — no default.
  When the user already supplied draft comment text, infer the mode from it and confirm before
  drafting.
  Never infer it from the thread alone: stop and ask.
- **Hints**: remaining free-form text — the point to make, extra context. Default: `(none)`.

State resolved values:
```
Target: <number|url>
Repo: <owner/name|(none — org-level discussion)>
Login: <handle>
Mode: <support|evidence|clarify>
Hints: <value, or "(none)">
```

## Draft vs publish
<!-- §draft-vs-publish -->

Publishing happens only on `publish` or `send it`. Nothing else authorises a write.

- `draft`, `edit`, `rework`, `shorten`, `update`, `fix the typo` — edit `$draftfile` only.
- A draft request aimed at an already-published comment is still a local edit: no mutation,
  no question about publishing.
- After presenting an edited draft, add one passive nudge:
  `Say 'publish' to <publish this comment|update the published comment>.`
- Never ask a publish-confirmation question before `Phase:Publish`, and never treat silence as
  approval.

## Phases

1. `Phase:Thread` — read the thread; map what is already asked and answered.
2. `Phase:Draft` — load the mode rules and voice skills; draft in a file; iterate.
3. `Phase:Publish` — publish on `publish` or `send it`; report the comment URL.

State each var once known:
- `$login` — the resolved GitHub handle, used to spot the user's earlier comments.
- `$mode` — the resolved mode: `support`, `evidence`, or `clarify`.
- `$n` and `$repo` — the resolved target number and repo, as used in the commands below.
- `$draftfile` — path of the local draft, e.g.
  `$TMPDIR/github-comment-<owner|org>-<name|discussions>-<n>.md`.

## 1. `Phase:Thread` — read before writing

Kind decides the read path:
- issue or PR: the reads below.
- discussion, repo or org-level: resolve the node ID first, then
  <./refs/discussions.md§disc-read>.

```sh
gh api repos/<repo>/issues/<n> --jq '{number, title, state, state_reason, is_pr: (.pull_request != null), body}'
gh api repos/<repo>/issues/<n>/comments --paginate --jq '.[] | "--- \(.user.login) \(.created_at)\n\(.body)"'
```

When `is_pr` is true, also read the PR state and the review threads:
```sh
gh api repos/<repo>/pulls/<n> --jq '{state, draft, merged, merged_at}'
gh api repos/<repo>/pulls/<n>/reviews --paginate --jq '.[] | "--- \(.user.login) \(.state) \(.submitted_at)\n\(.body)"'
gh api repos/<repo>/pulls/<n>/comments --paginate --jq '.[] | "--- \(.user.login) \(.created_at)\n\(.body)"'
```

Read the body and every comment. Then state:
- the status:
  * for an issue/PR: open/closed/merged
  * for a PR: draft or ready for review
  * for a discussion: open/closed, answered or not, and its category
- whether `$login` has already commented here, and when
- what the thread already asks for
- what a maintainer has answered, ruled out, or prototyped
- where the user's intended point lands: already covered, adjacent, or new

If the point is already covered: stop, quote the covering comment, and tell the user.
Do not draft a duplicate.

If the thread is closed or merged: name the state and the resolving event, then ask whether to
comment anyway.
If the user declines: stop.

Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)

## 2. `Phase:Draft` — draft and iterate

When entering `Phase:Draft`: read the mode file for `$mode` —
<./refs/modes/support.md>, <./refs/modes/evidence.md>, or <./refs/modes/clarify.md>.

Load `bew-communication-style` and `bew-inline-callout-style` for voice and markers.
Apply their Rules and Guidelines only — the phases here replace the style skill's own Steps.

Comment-specific overrides, on top of the style skills:
- Cut anything that restates the issue.
- Open with the intent, not a preamble.
  A greeting line fits only on the user's first comment in the thread, or when resuming after a gap
  of weeks or more since their last comment there.
- Never assert the user's own history, workflow, or current workaround.
  A first-person claim is allowed only when it traces to their hints or to something they said this
  session. Everything else is an open question: ask before the first draft, not after a correction.
- Callouts are optional, with no fixed mapping to a section: GitHub blockquote callouts
  (`> [!NOTE]`, `> [!WARNING]`) or an inline `⚠️`, wherever a point or an aside should not be
  skimmed past.
  The style skills' marker semantics still apply.
- No closing `_italic aside_` besides the signature.
  Any other closing aside must carry new information.
- Hedge what you don't control (`if possible`), never the facts.
- One sentence per line.
- Proof-read before presenting: no dropped words, no "would be replaces"-style slips.
- End every draft with a blank line, then `_Comment drafted & iterated on with AI assistance_`.
  The line ships inside the published body.

**Long-paragraph check** — apply the blunt-paragraph flag from `bew-communication-style`.
Flag 3–4 long sentences in one paragraph: deliver the draft first, then list each flagged
paragraph with a one-line reason, and offer a rework.
Flagging never blocks the draft.

### Emoji
<!-- §emoji -->

(NOTE: these are not hard rules, they should be updated/refined as relevant contexts are found)

One sentiment emoji per paragraph, three at most in the body, except the `❌`+`✅` pair.

- `👉` — the ask, or a takeaway the reader should carry away.
  Closes a prose paragraph: at most two per comment, never attached to a bullet item, never
  decoration.
- `🤔` — genuine uncertainty the author holds: an open question, a gap you cannot verify.
  Not for softening an ask, not for politeness.
- `😬` — admitting a workaround or compromise is shaky, or self-inflicted.
  Never on a maintainer's decision, never on someone else's bug.
- `❌` — a surface that cannot carry the case, or a workaround ruled out.
  Never aimed at a person, never on an opinion.
- `✅` — a concrete thing that does work, only when paired with a `❌` in the same passage.
- Drop the emoji when the sentence already carries the tone: a wrong emoji reads worse than none.

`⚠️` stays a callout marker, and `🙃`, `^^'`, `:/` stay humor markers.
This list governs sentiment emoji only.

Write the draft to `$draftfile`, then present it in chat labeled `Draft`, with the path.
Iterate on feedback until the user signals it is ready.

Ready to move to `Phase:Publish`? (say 'next' or similar to proceed)

## 3. `Phase:Publish` — publish on `publish` or `send it`

Publish only on `publish` or `send it`. Never publish unprompted.
A `publish` request naming an already-published comment means an edit of that comment, not a new one
— see <./refs/discussions.md§disc-update> for the discussion path.

Before publishing: re-run the `Phase:Thread` reads and compare against the map taken there.
If someone covered the point meanwhile: report it, then ask whether to publish anyway.
If the thread got closed or merged meanwhile: ask, as in `Phase:Thread`.

Issue or PR:
```sh
gh issue comment <n> --repo <repo> --body-file "$draftfile"
```
`gh pr comment <n>` is equivalent.

Editing a published issue comment takes its REST ID, not a node ID:
```sh
gh api -X PATCH repos/<repo>/issues/comments/<comment-id> -F body=@"$draftfile"
```

Discussion: <./refs/discussions.md§disc-publish>.
`gh issue comment` does not work on discussions.

The failure branches below apply to the GraphQL path too.

On failure:
- `Unauthorized`/`403` on the write while reads work: run `gh auth status`.
  A second account may be able to comment; ask before running `gh auth switch --user <name>`.
  After a successful switch: re-run the publish command; the switch approval covers the retry.
  If the retry fails the same way: stop and tell the user neither account can comment.
- "Enterprise Managed User … cannot access this content": the active account is work-managed and
  barred from that repo. Same fix as above.
- Any other auth error: ask the user to re-authenticate.

After publishing: the command prints the comment URL; report it.
Leave `$draftfile` in place.

## Rules

- Publish gate, and what counts as an edit-only request: <§draft-vs-publish>.
- Read the full thread before drafting, always.
- Never restate the issue back to the people who wrote it.
- Never re-raise a covered point. State the delta instead.
- Never assert the user's own history, workflow, or current workaround.
- Preserve the user's deliberate choices: wording, casing, asides, emoji they added.
  Fix only slips introduced in the current draft.
- Emoji placement follows <§emoji>.
- Keep the draft in a file. Never hold it only in chat.
- Comments only. Never edit the issue body, labels, assignees, or PR state.
- Top-level comments only.
  A reply is possible on discussions (<./refs/discussions.md§disc-publish>) and on PR review
  threads; on a plain issue, quote the comment you answer instead.
  Inline review comments are out of scope.
- Ask before inventing an implementation proposal on the user's behalf.

## Guidelines

- Prefer positioning as a user who wants the thing over a reviewer of the proposal.
- Reference sibling issues or PRs by `#N` where they carry weight.
- Cite a discussion comment as `#discussioncomment-<id>`; `#N` does not resolve there.
- Quote the covering comment when telling the user something is already handled.
