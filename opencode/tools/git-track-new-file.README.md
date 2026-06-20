# git-track-new-file tool

Global OpenCode tool artefact that registers new files with git (`git add -N`) so they
are git-tracked for the user immediately — without manual staging.

## Why a tool artefact, not a plugin

A plugin implementation can auto-run `git add -N` via a `tool.execute.after` hook after every
`write` call — no agent involvement needed.
However, injecting a confirmation message back into the conversation via `session.prompt`
(even with `noReply: true`) causes OpenCode to switch to plan mode, interrupting the agent's flow.
Using a tool artefact avoids any session interaction: the agent calls it explicitly, it runs
silently, and control returns immediately.

## What it does

Exposes a `git_track_new_file` tool the agent calls after any tool call that creates new files:
`write`, `cp`, `mv`, `curl -o`, `mkdir`, etc.
The companion skill (`skills/git-track-new-file/`) tells the agent when to invoke it.

## Skip rules

Files are silently skipped when:
- Path matches a secret pattern: `/tmp/`, `.env*`, `*.key`, `*.pem`, `*.secret`, `*.p12`, `*.pfx`
- File would be ignored by git (checked via `git check-ignore -q`)

## Symlink handling

If `git add -N` fails with an "outside repository" error (common when `~/.config/opencode` is
symlinked into a dotfiles repo), the tool resolves the real path via `realpath` and retries once.
