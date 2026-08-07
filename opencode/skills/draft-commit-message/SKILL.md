---
name: draft-commit-message
description: |
  Load the commit drafter ONLY when the user explicitly asks to draft or generate a commit message.
  Do NOT auto-load speculatively.
  Covers the full drafting process: diff analysis via explore-diff (defaults to staged changes),
  commit style detection, message writing, and eventual iteration loop.
metadata:
  maintainers: [bew]
---

## Goal

Produce a well-formed git commit message for a diff, then iterate until user is satisfied.

Caller may pass a scope (path/glob to restrict the diff) and/or a focus hint (free-text context).
Both are optional; defaults to full staged diff with no extra context.

## Step 1 — Analyse diff via `explore-diff`

Invoke the `explore-diff` subagent via the `task` tool.

Pass this task (adapt based on any scope/focus inputs received from caller):

> Diff source: requested diff source [restricted to `<scope>` if scope arg present].
> Purpose: commit message drafting.
> For each concern: include label, what changed (specific), inferred intent,
> and the representative file(s) or directory(ies) most useful as git log pathspecs
> (list individual files when few, top-level dir when many — agent's judgment).
> Omit user-facing impact and risks.
> Keep summaries intent-focused and concise.
> [Extra context from caller: `<focus>` (if present).]

Wait for subagent to return.
If subagent reports an empty diff: stop.

Use that summary as the sole basis for *Step 2* and *Step 3*.
Do not run `git diff` yourself.

## Step 2 — Detect commit style

Collect all representative paths from the summary.
Run one combined `git log --oneline -15 -- <all paths>`.
For any concern whose paths return few/no results:
also run `git log --oneline -5 -- <that concern's paths>`.

Inspect results:
- If majority follow `<type>(<maybe-scope>): <subject>` (conventional commits): use that format.
- If majority follow `topic(<maybe-sub-scope>): <subject>` (scoped commits): use that format.
- Otherwise: Default to scoped commits style:
  Derive a short lowercase topic word from the concern labels or paths
  (subsystem, directory, or area being changed) and use as prefix.
  Examples: `ci`, `docs`, `adapters`.
  If no clear topic can be derived: use no prefix.

For topic sub-scope, use `:` as inner separator (e.g: `hl:foo` or `skl:crafter`).

## Step 3 — Write the commit message

If summary has 2+ distinct concerns, output this before the message:
```text
WARNING: This diff mixes distinct concerns. Consider splitting into separate commits:
- <concern 1 label>
- <concern 2 label>
- …
```

### Subject line

Must complete "When applied, this commit will `<subject>`".
72 chars max. Imperative mood. No trailing period.
Use style from *Step 2*.
Capitalize the first word of the subject (after the `prefix: ` part, if any).

Prefer outcome/intent phrasing over mechanical phrasing:
"Unify X into Y" or "Add support for Z" — not "Replace A with B" or "Rename X to Y".

When listing multiple items, separate with `/` (not `, ` or `and`):
"Fix foo/bar/baz" or "Tighten rules for commands/ship gate/steps".

If the list would push past 72 chars, abbreviate the last items or collapse to a category word.

### About numbers

Do not use counts or numbers anywhere in the message (subject or body) —
not "3 concerns", not "fixes 2 bugs", not "adds N rules".
Use qualitative language: "few", "several", or name the things directly.

EXCEPTION: a number is fine when it represents a significant quantity or a before/after contrast
(e.g. "reduces latency from 200ms to 50ms").

### Body

Omit body entirely for single trivial changes (typo fix, rename, comment tweak).

**Form** — choose what fits best:
- **Paragraph only** — when a short paragraph names all concerns clearly enough on its own.
  Use when bullets would just restate what the paragraph already said.
- **Paragraph + bullets** — when each concern benefits from its own line for clarity or detail.
  One bullet per semantic concern.
- Default to paragraph + bullets when unsure; the iteration step lets the user trim.

**Paragraph rules**:
- Describe the new state or outcome only.
  No before/after comparisons ("old X did Y; new X does Z") — just what the result is and why.
- When listing items that follow a clear pattern, express the pattern rather than enumerating
  all members (e.g. "opencode/agents + global/project scopes" over four individual strings).

**Bullet rules**:
- Answer "what changed and why" — not "which file changed".
- Do not prefix bullets with file paths or directory names. One short clause per bullet.
- Omit file paths unless the path itself is meaningful.
- Collapse minor cleanups into one trailing bullet: `- Minor: <comma-separated list>.`
- Do not bullet things already said in subject or paragraph.

**Formatting**:
- Use backticks only for identifiers that appear literally in code
  (variable names, command names, flags).
- Do not backtick-quote technical terms or scope names.

Always blank line between subject and body, and between paragraphs.

Output raw commit message (and warning if applicable) — no markdown fencing, no extra commentary.

## Step 4 — Iterate

After outputting the message, ask user using the `question` tool.

Always include one of these options:
- **✅ Use as-is** — done (if we're in PLAN mode)
- **🚀 Use as-is and commit** — done and commit (if we're in BUILD mode)

And inspect the message to include concrete, message-specific suggestions (no emojis!):
- If it has a bullet list: offer structural variants for the list
  (e.g. "Drop the bullets, fold key points into the paragraph",
  "Expand the X bullet with more detail")
- If it has a paragraph: offer paragraph-level changes
  (e.g. "Drop the paragraph, lead with the bullets directly",
  "Tighten the paragraph — it's repeating the subject")
- If the subject is near the 72-char limit: offer "Shorten subject — trim `<the verbose part>`"
  or alternative subject wording that could fit.
- If the body feels long: offer "Shorten body — trim `<specific area>`"
- Omit options that don't apply to the message as written

Apply the requested change and re-output.
Repeat until user says "use as-is" or equivalent.
