---
description: Draft a git commit message from staged changes
subtask: true # isolated context
---

Draft a commit message for currently staged changes.

## Recent commits

```
!`git log --oneline -10`
```

## Staged diff

```
!`git diff --staged`
```

## Instructions

### Step 0 — Guard: verify staged changes exist

If staged diff above is empty, output exactly:
```
No staged changes. Stage files with `git add` before running this command.
```
Then stop. Do not produce a commit message.

### Step 1 — Detect commit style

Inspect 10 recent commits above.

- If majority follow `<type>(<scope>): <subject>` (conventional commits), use that format.
- If majority follow `topic(<optional-sub-scope>): <subject>`, use that format.
- Otherwise, derive short lowercase topic word from diff (subsystem, directory, or area being changed) and use as prefix.
  Examples: `ci`, `docs`, `adapters`.
  If no clear topic can be derived, use no prefix.

### Step 2 — Analyse the diff

Identify distinct concerns in diff.
A concern is a logically independent change.
(e.g. a bug fix, a new feature, a refactor of a separate module)

**Warning**: if staged diff contains 2 or more unrelated concerns, output this warning before commit message:

```
WARNING: This diff mixes N distinct concerns. Consider splitting into separate commits:
- <concern 1>
- <concern 2>
- …
```

### Step 3 — Write the commit message

**Subject line rule**: subject must complete this sentence:
> "When applied, this commit will <subject>"

Keep it 72 chars or fewer. Imperative mood. No trailing period.
Use style detected in step 1.

**Default verbosity — middle ground**:
- Omit body entirely only for single-line trivial changes (typo fix,
  rename, comment tweak).
- Otherwise: one short explanatory paragraph (2–3 sentences max)
  summarising intent, followed by condensed bullets — one per
  semantic concern, kept to one line each.
- Do not produce exhaustive bullet lists covering every detail of
  the diff. Aim for enough context to understand the change without
  reading the diff.

**Bullet discipline** — each bullet must answer "what changed and why",
not "which file changed". Diff already records file locations.
Rules:
- One bullet per semantic concern (may cover several files/lines).
- Omit file paths unless path itself is meaningful information.
- Collapse unrelated minor cleanups (renames, trivial fixes) into
  single trailing bullet: `- Minor: <comma-separated list>.`
  Skip typo fixes — not worth mentioning.
- Do not bullet-point things already said in subject or paragraph.

Example body format:
```
Brief paragraph explaining the intent or context.

- Add configurable IAM role input to replace all hardcoded ARNs.
- Pass all secrets via env vars instead of inline template expressions.
- Minor: rename `encoded-password` for clarity.
```

When body is present: blank line between subject and body, and
between paragraphs. This MUST ALWAYS be respected.

Output only raw commit message (and warning if applicable) — no markdown fencing, no extra commentary.

### Step 4 — Offer adjustment

After outputting the commit message, ask the user whether they want
to adjust it. Use the `question` tool with these options:

- **Use as-is** — proceed
- **More details** — ask a targeted follow-up: which area needs more
  explanation? (paragraph, bullets, a specific concern, overall?)
- **Less details** — ask a targeted follow-up: what to trim? (paragraph,
  bullets, a specific area, collapse to subject only?)
- **Edit subject** — user wants to tweak wording of the subject line

When the user picks "More details" or "Less details", use the
`question` tool again to ask the targeted follow-up before rewriting.
Do not guess what to change — ask first.
