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

## Setup — resolve inputs

Determine the following values from whatever is available in context
(prior command output, user message, session prompt, or defaults):

- **Working directory**: from user context. Default: <from env block in system prompt>.
- **Scope**: a path, glob, or area to narrow the diff (e.g. `src/adapters/`, `*.ts`).
  Default: none (full diff).
- **Diff type**: infer from any available wording — "staged" means staged changes; anything else
  (including "unstaged", "current diff", or no mention) means staged. Default: staged.
- **Focus**: free-text note to guide writing (intent, emphasis, context).
  If user context looks like a diff scope — treat it as scope instead.
  Both scope and focus may be present simultaneously.

State resolved values:
```text
Working directory: <resolved absolute dir>
Scope: <path/glob, or "(none)">
Diff type: staged | unstaged
Focus: <free-text, or "(none)">
```

## Step 1 — Analyse diff via `explore-diff`

IMPORTANT: Never run `git diff` or `git diff --cached` directly — not even to inspect
the diff before routing to `explore-diff`.
Raw bash diff output in context does not substitute for an `explore-diff` result.

If `explore-diff` was already invoked in the last few messages and the result is still visible
in context: check whether it covers the current diff (it may have a broader scope).
If yes, extract the relevant concerns from it — skip subagent invocation.

Otherwise, invoke the `explore-diff` subagent via the `task` tool.

Pass this task (adapt based on *Setup* values):

> Diff source: `<git diff [--staged] -- <scope>>` (use values from *Setup*).
> Working directory: `<working directory from Setup>`
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

## Step 2 — Detect commit style

A **subsystem dir** is inferred from a concern's label + paths:
Pick the dir naming the component:
.. not too shallow (not repo root or containers like `src/`),
.. not too deep (not the leaf file's parent).
If the concern touches both code & test paths, use code path(s) only; if test-only, use test path(s).

Run `git log --oneline -5` scoped to a path per the following, then inspect results:
- **Single concern**: scope = subsystem dir.
  If empty → `git log --oneline -10` (no pathspec).
- **2+ concerns**: scope = deepest common ancestor of all changed paths, if meaningful
  (not repo root or a broad container).
  If no meaningful common ancestor: run `git log --oneline -5 -- <subsystem dir>` per concern; merge non-empty results.
  If no results for common ancestor or per-concern logs → `git log --oneline -10` (no pathspec).

Inspect results to derive commit prefix & style:
- If majority follow `<type>(<maybe-topic/scope>): <subject>` (conventional commits): use that format.
- If majority follow `<topic>(<maybe-sub-scope>): <subject>` (scoped commits): use that format.
- Otherwise: Default to scoped commits style:
  Derive a short lowercase topic word from the concern labels or paths
  (subsystem, directory, or area being changed) and use as prefix.
  Examples: `ci`, `docs`, `adapters`. `misc` allowed for small changes.
  If no clear topic can be derived: use no prefix.

For topic sub-scope (if needed), use `:` as inner separator (e.g: `hl:foo` or `skl:crafter`).

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
When identifiers appear literally in code, backtick them in the subject too (see **Formatting**).
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
- One paragraph per semantic concern. Never mix unrelated topics in a single paragraph.
  BAD: one paragraph spanning worktrees layout, config extraction, and a cache split.
  GOOD: one paragraph per concern, each standing alone.
- A paragraph can be as simple as 1-2 lines, don't attempt to 'fill the void' with words.
- Describe the new state or outcome only.
  No before/after comparisons ("old X did Y; new X does Z") — just what the result is and why.
- When a sentence describes a structural change ("X lets Y become Z"), make sure to close the loop:
  mention what Z actually means in practice.
  Think: does the reader know what the result means after this sentence?
- Express intent and tradeoff — not which artifacts were touched.
  "Document the shell-alias subdir tradeoff, wrt…" over "Add a comment and inline notes to the file."
- Omit file paths from paragraph prose. Paths are redundant — they are already visible in
  `git show`. Only mention a path when the path itself carries meaning (e.g. a naming convention
  being established for the first time).
- Describe *what* the result enables, not *how* it works internally.
  Omit implementation mechanism (library choices, fallback chains, internal field names) unless
  the mechanism is itself the point of the change — i.e. a deliberate tradeoff worth recording.
- When listing items that follow a clear pattern, express the pattern rather than enumerating
  all members (e.g. "opencode/agents + global/project scopes" over four individual strings).

**Bullet rules**:
- Answer "what changed and why" — not "which file changed".
- Do not prefix bullets with file paths or directory names. One short clause per bullet.
- Omit file paths unless the path itself is meaningful.
- Collapse minor cleanups into one trailing bullet: `- Minor: <comma-separated list>.`
- Omit the Minor bullet entirely if items are purely structural (doc cross-references,
  ordering notes, inline prose clarifications) with no behavioral significance.
- Do not bullet things already said in subject or paragraph.

**Formatting**:
- Use backticks only for identifiers that appear literally in code
  (variable names, command names, flags).
- Do not backtick-quote technical terms or scope names.
- Start each sentence on its own line — never run several sentences back-to-back on one line.
  Sentences stay in the same paragraph; only a blank line splits paragraphs. This is a hard rule.
  After writing the body, verify no line contains more than one sentence.
- Fit into 72 chars, use newlines as needed (compress text a little, should still be ~prose).
  Never join two sentences on one line to satisfy the limit — see the sentence-break rule above.

Always blank line between subject and body, and between paragraphs.

Output raw commit message (and warning if applicable) — no markdown fencing, no extra commentary.
Surround the message with 2 `---` delimiter lines & blank lines (above/below) so it stands out in
the terminal output:
```
---

<commit message>

---
```

## Step 4 — Iterate

After outputting the message, iterate with user, and use the `question` tool.

Always include one or both of these options based on BUILD/PLAN mode (labels to be used verbatim):
- "✅ Looks good" — reply `Done` & stop.
- "🚀 Use as-is and commit" — commit & stop.
  (omit this option if in PLAN mode)

IMPORTANT: Use these labels verbatim.
Do NOT combine or conflate them (e.g. "Looks good — proceed to commit" is not allowed).
They are distinct: one approves, one commits.

Inspect the message and derive concrete, message-specific suggestions.
Add them as additional options in the SAME `question` tool call:
- Always add 1–2 alternative subject options when they would be meaningfully different
  (e.g. different framing, tighter wording, or different root-cause emphasis).
  Label format: "Alt subject: <wording>".
- If it has a bullet list: add structural variant option(s)
  (e.g. "Drop the bullets, fold key points into the paragraph",
  "Expand the X bullet with more detail")
- If it has a paragraph: add paragraph-level change option(s)
  (e.g. "Drop the paragraph, lead with the bullets directly",
  "Tighten the paragraph — it's repeating the subject")
- If the subject is near the 72 chars limit: add "Shorten subject — trim `<the verbose part>`"
  or alternative subject wording that could fit.
- If the body feels long: add "Shorten body — trim `<specific area>`"
- Omit options that don't apply to the message as written

Apply any requested change and re-output.
Repeat until user says 'looks good' / 'use as-is' or equivalent.

If user picks "🚀 Use as-is and commit":
- When diff-type is **staged**: run the commit directly via the multiline heredoc form:
  ```sh
  git commit -F - <<'EOF'
  <subject line>

  <body if any>
  EOF
  ```
  Do NOT inspect unstaged changes, do NOT run `git diff`, do NOT `git add` anything.
  The staged content is the contract established in Step 1 — commit it as-is.
- When diff-type is **unstaged**: ask via `question` tool which files to stage (list them),
  wait for confirmation, `git add` only the confirmed files, then run the same
  multiline heredoc commit form above.

Do NOT run `git commit` before reaching this step — never commit speculatively without user approval
for THIS commit.
