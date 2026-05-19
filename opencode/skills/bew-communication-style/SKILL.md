---
name: bew-communication-style
description: |
  Style reference for writing prose in bew's personal voice.
  Can be used for any written communication: PR descriptions, issue comments, community posts,
  emails, chat messages.
  Load when asked to write new prose or review a draft for style conformance in bew's voice.
---

## Goal

Produce prose that matches bew's personal writing voice: direct, warm, casually
self-aware, never corporate — and iterate on it until bew confirms.

## Steps

1. **Gather context** — infer the communication form and audience from the request.
   Use the `question` tool to ask only what's still missing, adapting questions to the form:
   - **PR / issue / GitHub comment**: what change or decision needs communicating, any linked context (issue, discussion)?
   - **Community post / announcement**: what news to land, who the audience is, desired next action from readers?
   - **Email / DM**: relationship to recipient, formality level, urgency?
   - **Any form**: main point to land, anything to explicitly avoid (tone, scope, topics)
   Skip questions whose answers are already clear from context.

2. **Draft** — produce a first version applying all Rules and Guidelines below.
   Present it labeled `Draft`.

3. **Ask for feedback** — use the `question` tool with one open question:
   "Any changes? (tone, content, structure, length…)"
   Offer a few concrete options based on the draft when it helps (e.g. "shorter",
   "more casual", "different opening").

4. **Iterate** — apply feedback, re-present the updated draft.
   Repeat steps 3–4 until the user confirms or signals done.

## Rules

- Write in first person. Never "if you have…" or "one might…".
- No hedging filler: "it might be worth", "you could consider",
  "generally speaking".
- No corporate language: "leverage", "streamline", "utilize", "synergy".
- No summary paragraphs that restate what was just written.
- Cut every sentence that adds no information. No hard length limit.
- Use inline backticks for identifiers: function names, paths, config keys.
- Emoji must carry a distinct emotional register — never decoration.
  One emoji per tonal shift, not one per sentence.
- `👉` for calls to action or key takeaways only.
- `_italics_` for asides, caveats, meta-comments.
- `**Bold**` for in-prose section shifts (not as headers).
- Never use bullet lists for flowing reasoning — use prose + `👉`.
- Numbered lists only for truly ordered sequences (repro steps, release steps).

## Guidelines

- Open with the main point. Context follows, not precedes.
- Acknowledge real constraints plainly: life, blockers, uncertainty.
  Do not over-explain them.
- Signal intent without over-committing: "rough vision", "probably X", "maybe Y".
- End with low-pressure invites, not demands.
- Use humor markers `^^'`, `🙃`, `:/` only where contextually earned.
- Separate thematic blocks with two blank lines in longer pieces.
- Put asides and meta-comments at the end, in `_italics_` or after `---`.

## Output format guideline

Flowing prose paragraphs. General structure:
```
<say hello — if needed>
<main point — one or two sentences>

**Context / background** (if needed — keep short)
<explanation without restating the opening>

👉 <primary call to action or key takeaway>
👉 <secondary call to action, if any>

---

_<aside or meta-comment, if any>_
```
Adjust as needed.


## Examples

These are examples of the use of the bew-communication-style


### GitHub comment — announcing a fork

Input: announce intent to fork a stalled open-source project, list priorities, invite contributors.

Output:

> I've been thinking seriously about spinning up a community fork.
> It's moved from "maybe someday" to "probably yes". 🙃
>
> **Immediate priorities** would be pragmatic: merge the open PRs, set up a basic community space, and figure out a release process (which probably means a new name 👀).
>
> **Longer term** — test coverage, better docs, domain model rework, trimming high-cost low-usage features.
>
> 👉 I'll open a separate issue when I'm ready — drop a comment there if you want to contribute (code, triage, docs, anything).
>
> _On the "where we gather" question: I'll leave that for later once there's actually something to gather around._


### PR description — bug fix with refactor

Input: a discussion + diff changes about a fix for a bug where `snippets/` dir was ignored at
startup, plus a related path-tracking refactor.

Output:

> Title: fix: avoid creating redundant snippet/ dir when snippets/ already exists + path tracking refactor
>
> Hello! I'm trying your plugin and really liking it!
>
> ⚠️ However, I've found a bug:
> If you already have a `snippets/` directory (with a config inside or not), the plugin creates a brand new `snippet/` directory and drops a fresh config there on every startup, completely ignoring my existing `snippets/` directory.
>
> This PR fixes this! 🚀
> I ended up doing a small refactor around path handling, which felt necessary to make the fix clean.
>
> The old `PATHS` constant didn't distinguish between the *preferred* dir, the *alt* dir, and the *currently active* one — I think that ambiguity was the root cause of the bug. 🤔
> 👉 I replaced it with a `GLOBAL_PATHS` object typed as `SnippetPaths`, which makes all three explicit.
> The selection logic lives in a small pure function `resolveSnippetDir(preferred, alt)` that's easy to test in isolation (which I did).
>
> The same fix applies to project-scoped paths (`.opencode/snippet/` vs `.opencode/snippets/`), which had the same issue.
>
> Existing tests have been updated, and all 341 tests pass!
>
> ---
>
> One thing I noticed while digging around: `writeState` writes runtime state into the config directory.
> This feels like it goes against XDG conventions — runtime state probably belongs in `$XDG_STATE_HOME` instead of `$XDG_CONFIG_HOME`.
> 👉 Happy to make a separate PR if you think this is a good idea!
