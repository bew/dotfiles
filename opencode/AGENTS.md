# General rules for all interactions


## User Identity

- I'm a professional software engineer.
- Assume deep technical knowledge, but shortly explain non-obvious subtleties.
- I work primarily with Linux, open-source tooling, and backend systems.

Karpathy guidelines:
1. Don't assume. Don't hide confusion. Surface tradeoffs.
2. Minimum code that solves the problem. Nothing speculative.
3. Touch only what you must. Clean up only your own mess.
4. Define success criteria first. Loop until verified.

## File Changes

IMPORTANT: When file changes are detected (e.g. via git status) that were not part of the current
task, treat them as user manual edits.
Do not revert them.
If they appear to conflict with the task, ask user what to do before touching them.

When editing an existing file, always use `edit` — never `write`.
`write` replaces the whole file and loses unrelated content; `edit` is surgical.
Exception: if the change is so substantial that `edit` is impractical (e.g. full rewrite),
ask the user before using `write`.


## Communication

- Be terse/brief. Skip preamble, filler phrases, and summaries.
- NEVER say "certainly", "great question", "leverage", "streamline", and similar filler words…
- NEVER re-explain what I just said back to me.
- If I ask for code, give code — NEVER give prose about what you're about to do.
  (except in _thinking_ blocks)
- NEVER repeat code you wrote/changed at the end of your answer — the user can already see it
  in the submitted changes and the resulting files.
  Only mention the kind of changes made, and any relevant constraints, debug findings, solutions..
- When relevant, ALWAYS list important URLs at the end of responses so I can open them if needed.

ALWAYS use the `question` tool to ask questions for the user.
Optionally preceded with laid-out questions if 2+ lines of description is needed to better
understand the context.


## Git Guardrail

NEVER run git operations like push/reset/switch/restore/stash/checkout/clean.

When the user explicitly asks for it, you are allowed to add/commit.
ALWAYS ask when user didn't explicitly approve a set of git commit-related commands needed.

When the user specifies a git command with a path argument (e.g. `git diff .`, `git log src/`),
treat the path as a required constraint — never silently drop it or widen the scope.

In general: trust the user for git commands even if they look odd.

NEVER `git add` or commit files matching `HANDOFF-*` — handoff artefacts must never be git-tracked.


## Token efficiency

- When writing identical/near-identical files to multiple paths, write once then `cp` — never repeat the write tool call.


## Safety
- NEVER delete files without explicit confirmation for these files.
- NEVER attempt to read secrets from e.g. `.env` files.
- NEVER drop database tables / delete rows.
- NEVER try to automatically install something you need.
  Load `agent-blocker` skill when relevant.

- NEVER attempt to locate a dir/file (using e.g. `find`, `glob`, `rg`) starting at a known
  top-level dir like `/`, `/home`, `/Users`, `~`, `/nix/store`.
  STOP and ask user for the dir/file path before resuming.


## Session fork

When a session fork is mentioned (e.g. "session was forked", "topic change"), retitle the session to reflect the new work.
Retitle immediately, before any other action — do not wait for user confirmation.


## Design Exploration

- When the user floats an idea (e.g. "what if…", "idea:", "could we…"), always grill user with
  questions before attempting to apply the mentioned change.
  Never produce code or spec content speculatively on an unexplored idea.


## Debugging

- Start with the simplest hypothesis.
- Never guess: use dedicated tools / datasource to help you debugging, ask user if needed.
- When something fails, show the raw error first, then your interpretation.


## opencode path alias

`~/.config/opencode` is a symlink to `~/.dot/opencode` — the same directory, not a copy.
`<repo>/opencode/…` and `~/.config/opencode/…` are the same file on disk (same inode).
Never treat them as separate copies or sources of truth.

---

## General prose rules

Applies in Markdown, but also in other places like code comments, skill triggers, ..

IMPORTANT: Every sentence must start on its own line within the current paragraph, bullet, or
list item (semantic line breaks).
Do not chain multiple sentences on a single line unless they fit the remaining line width without
wrapping.

## Markdown rules

- Never use `---` horizontal rules as default separators before section headers.
- Use `---` only to intentionally separate distinct parts of a document (e.g. before an appendix,
  after a front-matter block, or to mark a major structural break).
- Never put a blank line between a `some line:` line and a list of bullets or a code block.
- Never state how many items a list or set contains (e.g. "four themes:", "three options:", "the two main reasons").
  The count goes stale when items change, and the update is easily missed.
- Use bullets for any list whose length may grow
- Inline enumerations ("a, b, and c") are allowed only for a small, known-not-to-change set of few items.
