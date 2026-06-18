# git-intent-to-add plugin

Auto-loaded global OpenCode plugin that registers new files with git (`git add -N`) so they
appear in `git diff` and other git-aware tools immediately — without manual staging.

## What it does

**Automatic** (no agent needed): after every `write` tool call, the plugin runs `git add -N`
on the written file via a `tool.execute.after` hook.
On success, a short `[git-intent-to-add]` message is injected into the conversation
(`noReply: true` — visible in context, AI does not respond to it).

**On demand** (agent-driven): exposes a `git_intent_to_add` tool the agent calls after bash
commands that create files (`cp`, `mv`, `curl -o`, `mkdir`, etc.).
The companion skill (`skills/git-intent-to-add/`) tells the agent when to invoke it.

## Skip rules

Files are silently skipped when:
- Path matches a secret pattern: `/tmp/`, `.env*`, `*.key`, `*.pem`, `*.secret`, `*.p12`, `*.pfx`
- File would be ignored by git (checked via `git check-ignore -q`)

## Symlink handling

If `git add -N` fails with an "outside repository" error (common when `~/.config/opencode` is
symlinked into a dotfiles repo), the plugin resolves the real path via `realpath` and retries once.
