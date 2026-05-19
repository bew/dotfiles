---
description: Draft a PR description in my personal style
---

## Phases

### Phase 1 — Gather context

Check the "Additional user context" section at the bottom first. Pre-filled answers skip their corresponding question below.

Ask (skipping any already answered):
1. What is the diff source?
   - Current branch vs `@{u}` (tracking upstream)
   - Current branch vs `main` / `master`
   - Staged changes only
   - Custom — I'll provide a diff command
2. Is there a linked GitHub issue? If so, what's the URL or number?
3. Any extra context or notes to include? (optional)

Do not proceed until questions 1 and 2 are answered. Question 3 is optional.

### Phase 2 — Fetch the diff

From the chosen diff source, deduce the exact `git diff` command to run.
If the mapping is ambiguous, state the command you plan to run and ask for confirmation before executing.
Run the command and use its output as the diff content for drafting.

### Phase 3 — Draft

Produce an initial PR title and body following the output structure and style rules below.

### Phase 4 — Iterate

After the draft, ask:
- Does this look right?
- Anything to adjust, add, or remove?

Iterate until confirmed.

### Phase 5 — Offer to save

Offer to save the description to `pr-desc.txt` for easier editing or copying.
Run `git rev-parse --show-toplevel` to find the repo root.
If `pr-desc.txt` already exists there, warn the user before overwriting.
Save only on explicit confirmation. Skipping is fine.

---

## Output structure

```
Title: <title>

<opening line>

<body paragraphs>

---

<asides, if any>
```

- Title on the first line, prefixed with `Title:`.
- Blank line before the body.
- Asides separated by `---` at the end.

---

## Style rules

### Voice and tone

- Open with a short friendly sentence: e.g. "Hello! I'm trying your plugin and really liking it!"
- Use first person: "I found", "my existing X". Never "if you have...".
- Describe the goal/bug/improvement directly and personally — if a GitHub issue covers it, reference it instead of restating it.
- No hedging. State directly. Use `🤔` only for genuine open questions to the author.
- Asides (follow-ups, questions to author) go last, after `---`, with a casual invite.

### Sentences and structure

- Short sentences. Break at breath points. No comma-chaining.
- Use short paragraphs as the default structure.
- `👉` as soft bullet for key takeaways.
- `-` bullet lists only when something is genuinely enumerable.
- Numbered lists only for truly ordered sequences (e.g. repro steps).

### Emoji

- Use as section-shift markers — one per shift, not decoration.
- Conventional commits prefix (`fix:`, `feat:`, `chore:`, etc.) in the title only when it fits naturally — never forced.

---

## Example

Input: a discussion and diff of changes covering a fix for a bug where the `snippets/` dir was ignored at startup, plus a related path-tracking refactor.

Output:

> Title: fix: avoid creating redundant snippet/ dir when snippets/ already exists + path tracking refactor
>
> Hello! I'm trying your plugin and really liking it!
>
> ⚠️ However, I've found a bug:
> If you already have a `snippets/` directory (with a config inside or not), the plugin creates a brand new `snippet/` directory and drops a fresh config there on every startup, completely ignoring my existing `snippets/` directory..
>
> This PR fixes this! 🚀
> I ended up doing a small refactor around path handling, which felt necessary to make the fix clean.
>
> The old `PATHS` constant didn't distinguish between the *preferred* dir, the *alt* dir, and the *currently active* one, I think that ambiguity was the root cause of the bug. 🤔
> 👉 I replaced it with a `GLOBAL_PATHS` object typed as `SnippetPaths`, which makes all three explicit.
> The selection logic lives in a small pure function `resolveSnippetDir(preferred, alt)` that's easy to test in isolation (which I did).
> The new `GLOBAL_PATHS` is populated once on startup with `getGlobalPaths` which works the same way as `getProjectPaths`, with the new active dir selection.
>
> The same fix applies to project-scoped paths (`.opencode/snippet/` vs `.opencode/snippets/`), which had the same issue.
>
> Existing tests have been updated, and all 341 tests pass!
>
> ---
>
> One thing I noticed while digging around: `writeState` writes runtime state into the config directory.
> This feels like it goes against XDG conventions, and runtime state probably belongs in `$XDG_STATE_HOME` (or `$XDG_RUNTIME_DIR` for truly ephemeral data) instead of `$XDG_CONFIG_HOME`.
> 👉 Happy to make a separate PR if you think this is a good idea!

---

## Additional user context

May be empty. If non-empty, use to pre-fill answers and skip corresponding questions in Phase 1.

```
$ARGUMENTS
```
