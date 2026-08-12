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

If `explore-diff` was already invoked in the last few messages and the result is still visible
in context: check whether it covers the current diff (it may have a broader scope).
If yes, extract the relevant concerns from it — skip subagent invocation.

Otherwise, invoke the `explore-diff` subagent via the `task` tool.

Pass this task (adapt based on any scope/focus inputs received from caller):

> Diff source: requested diff source [restricted to `<scope>` if scope arg present].
> Working directory: `<absolute path, from session prompt>`
> Purpose: commit message drafting.
> For each concern: include label, what changed (specific), inferred intent,
> and the representative file(s) or directory(ies) most useful as git log pathspecs
> (list individual files when few, top-level dir when many — agent's judgment).
> Omit user-facing impact and risks.
> Keep summaries intent-focused and concise.
> [Extra context from caller: `<focus>` (if present).]

Wait for subagent to return.

If subagent reports `Empty diff. Nothing to analyse.`: stop.

If subagent reports a `FALLBACK:` block (staged diff was empty, unstaged files found):
Read the list of files from the report.
Ask user via `question` tool — construct the question text dynamically:
- Mention the found files by name.
- Option 1: "Use these unstaged changes" — re-run `explore-diff` with `git diff -- <scope>` as diff source.
- Option 2: "Abort" — stop.
If user picks option 1: retry `explore-diff` with `git diff -- <scope>` as diff source and the same workdir, then continue to *Step 2*.
If user picks option 2: stop.

Use subagent summary as the sole basis for *Step 2* and *Step 3*.
Do not run `git diff` yourself.

## Step 2 — Detect commit style

Collect all representative paths from the summary.
Run one combined `git log --oneline -10 -- <all paths>`.
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
```
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

When the subject describes a fix, name the root cause or mechanism — not just the symptom or
the artifacts changed.
Think: does the subject say _why_ it's broken, or just _what_ is broken?

When listing 2+ items or when trying to shorten the line, separate with `/` (not `, ` or `and`):
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
- **Paragraph(s) only** — when a short paragraph names all concerns clearly enough on its own.
  Use when bullets would just restate what the paragraph already said.
- **Paragraph(s) + bullets** — when each concern benefits from its own line for clarity or detail.
  One bullet per semantic concern.
- Default to paragraph(s) + bullets when unsure; the iteration step lets the user trim.

**Paragraph(s) rules**:
- Describe the new state or outcome only.
  No before/after comparisons ("old X did Y; new X does Z") — just what the result is and why.
- When a sentence describes a structural change ("X lets Y become Z"), make sure to close the loop:
  mention what Z actually means in practice.
  Think: does the reader know what the result means after this sentence?
- Express intent and tradeoff — not which artifacts were touched.
  "Document the shell-alias subdir tradeoff, wrt…" over "Add a comment and inline notes to the file."
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
- Fit into 72 chars, use newlines as needed (compress text a little, should still be ~prose)

Always blank line between subject and body, and between paragraphs.

Output raw commit message (and warning if applicable) — no markdown fencing, no extra commentary.
Surround the message with `-----` delimiter lines so it stands out in the terminal output:
```
-----
<commit message>
-----
```

## Step 4 — Iterate

After outputting the message, iterate with user, and use the `question` tool.

Always include one or both of these options based on BUILD/PLAN mode (labels to be used verbatim):
- "✅ Looks good" — reply `Done` & stop.
- "🚀 Use as-is and commit" — commit & stop.
  (omit this option if in PLAN mode)

And inspect the message to include concrete, message-specific suggestions (no emojis!):
- Always offer 1–2 alternative subject lines when they would be meaningfully different
  (e.g. different framing, tighter wording, or different root-cause emphasis).
  Label them inline, e.g. "Alt subject: <wording>".
- If it has a bullet list: offer structural variants for the list
  (e.g. "Drop the bullets, fold key points into the paragraph",
  "Expand the X bullet with more detail")
- If it has a paragraph: offer paragraph-level changes
  (e.g. "Drop the paragraph, lead with the bullets directly",
  "Tighten the paragraph — it's repeating the subject")
- If the subject is near the 72 chars limit: offer "Shorten subject — trim `<the verbose part>`"
  or alternative subject wording that could fit.
- If the body feels long: offer "Shorten body — trim `<specific area>`"
- Omit options that don't apply to the message as written

Apply any requested change and re-output.
Repeat until user ends says 'looks good' / 'use as-is' or equivalent.

If user picks "🚀 Use as-is and commit": run `git commit -m "<message>"`.
Do NOT run `git commit` before reaching this step — never commit speculatively without user approval
for THIS commit.

Similarly `git add` is only allowed when explicitly requested by the user for THIS commit.
Ask via `question` tool with specific files listed before staging anything.
