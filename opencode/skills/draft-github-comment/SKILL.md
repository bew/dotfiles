---
name: draft-github-comment
description: |
  Draft a comment on an existing GitHub issue or PR in bew's voice, then post it via `gh`
  after explicit approval.
  Load when asked to comment on, reply to, or "+1" an issue or PR, to add repro evidence to
  someone else's report, or to clarify or answer a question in a thread.
  Modes: support (same wish + your own missing piece), evidence (repro, version, logs),
  clarify (answer, or clarify your own earlier comment).
  Not for drafting issue/PR bodies, and not for code review comments.
metadata:
  maintainers: [bew]
---

# Skill: draft-github-comment

## Goal

Produce a threaded GitHub comment that reads as a participant — a user who wants something —
and post it only after the user approves the draft.

## Setup — resolve inputs

Determine the following from whatever is in context (user message, prior context, session):

- **Target**: issue or PR number, or its URL. Required — stop and ask if absent.
  A URL supplies `<n>` and its `owner/name`, which wins over the repo default.
- **Repo**: `owner/name` of the repo holding the thread.
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
Repo: <owner/name>
Login: <handle>
Mode: <support|evidence|clarify>
Hints: <value, or "(none)">
```

## Phases

1. `Phase:Thread` — read the thread; map what is already asked and answered.
2. `Phase:Draft` — load the mode rules and voice skills; draft in a file; iterate.
3. `Phase:Post` — post via `gh` after explicit approval; report the comment URL.

State each var once known:
- `$login` — the resolved GitHub handle, used to spot the user's earlier comments.
- `$mode` — the resolved mode: `support`, `evidence`, or `clarify`.
- `$draftfile` — path of the local draft, e.g. `$TMPDIR/github-comment-<owner>-<name>-<n>.md`.

## 1. `Phase:Thread` — read before writing

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
- the status: open, closed, merged; for a PR, draft or ready for review
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
- One emoji per tonal shift, three at most in the body.
- Callouts are optional, with no fixed mapping to a section: GitHub blockquote callouts
  (`> [!NOTE]`, `> [!WARNING]`) or inline markers (`⚠️`, `👉`), wherever a point or an aside
  should not be skimmed past.
  The style skills' marker semantics still apply.
- No closing `_italic aside_` besides the signature.
  Any other closing aside must carry new information.
- Hedge what you don't control (`if possible`), never the facts.
- One sentence per line.
- Proof-read before presenting: no dropped words, no "would be replaces"-style slips.
- End every draft with a blank line, then `_Comment drafted & iterated on with AI assistance_`.
  The line ships inside the posted body.

Write the draft to `$draftfile`, then present it in chat labeled `Draft`, with the path.
Iterate on feedback until the user signals it is ready.

Ready to move to `Phase:Post`? (say 'next' or similar to proceed)

## 3. `Phase:Post` — post after explicit approval

Post only after explicit go-ahead. Never post unprompted.

Before posting: re-run the `Phase:Thread` reads and compare against the map taken there.
If someone covered the point meanwhile: report it, then ask whether to post anyway.
If the thread got closed or merged meanwhile: ask, as in `Phase:Thread`.

```sh
gh issue comment <n> --repo <repo> --body-file "$draftfile"
```

Works for PRs too — `gh pr comment <n>` is equivalent.

On failure:
- `Unauthorized`/`403` on the write while reads work: run `gh auth status`.
  A second account may be able to comment; ask before running `gh auth switch --user <name>`.
  After a successful switch: re-run the post command; the switch approval covers the retry.
  If the retry fails the same way: stop and tell the user neither account can comment.
- "Enterprise Managed User … cannot access this content": the active account is work-managed and
  barred from that repo. Same fix as above.
- Any other auth error: ask the user to re-authenticate.

After posting: the command prints the comment URL; report it.
Leave `$draftfile` in place.

## Rules

- Read the full thread before drafting, always.
- Never restate the issue back to the people who wrote it.
- Never re-raise a covered point. State the delta instead.
- Preserve the user's deliberate choices: wording, casing, asides, emoji they added.
  Fix only slips introduced in the current draft.
- Keep the draft in a file. Never hold it only in chat.
- Comments only. Never edit the issue body, labels, assignees, or PR state.
- Top-level thread comments only. Inline review comments are out of scope.

## Guidelines

- Prefer positioning as a user who wants the thing over a reviewer of the proposal.
- Reference sibling issues or PRs by `#N` where they carry weight.
- Quote the covering comment when telling the user something is already handled.
- Ask before inventing an implementation proposal on their behalf.
