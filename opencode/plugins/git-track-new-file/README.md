# git-track-new-file plugin

Global OpenCode V2 plugin that registers the `git_track_new_file` tool.
The tool git-tracks new files (`git add -N`) so they are tracked for the user
immediately — without manual staging.

## Why an explicit tool, not an auto-hook

A plugin could auto-run `git add -N` via a `tool.execute.after` hook after every
`write` call — no agent involvement needed.
However, injecting a confirmation message back into the conversation via
`session.prompt` (even with `noReply: true`) causes OpenCode to switch to plan
mode, interrupting the agent's flow.
Using an explicit tool avoids any session interaction: the agent calls it, it
runs silently, and control returns immediately.

## What it does

Exposes a `git_track_new_file` tool that registers newly created files with git.
The companion skill (`skills/git-track-new-file/`) tells the agent when to invoke it and which paths to skip.

The result is a one-line status — `tracked`, `skipped (<reason>)`, or `failed (<git error>)` —
with the path rendered as `<repo>/<path-relative-to-repo-root>`.

The tool is registered with `options.codemode`, so it also appears in the Code
Mode catalog.

## Skip rules

Mechanical skips — files are silently skipped when:
- Path matches a secret pattern: `/tmp/`, `.env*`, `*.key`, `*.pem`, `*.secret`, `*.p12`, `*.pfx`
- File would be ignored by git (checked via `git check-ignore -q`)

Agent-judgment skips live in the companion skill, which is the single source for paths the agent should not track.
They are not enforced in code; `.gitignore` remains the mechanical backstop.

## Repo discovery / cwd

Git commands are anchored with `git -C <file's directory>`, so repo discovery
does not depend on the process cwd. This matters because V2 runs global plugins
in a shared server process whose cwd is not the session's project directory.

Anchoring also covers symlinked paths (e.g. `~/.config/opencode` symlinked into
a dotfiles repo) without needing `realpath` resolution or an "outside
repository" retry.

## Layout

This is a directory plugin, discovered automatically from the global plugins
root (`~/.config/opencode/plugins/`). No config entry is needed.
`index.ts` is the entry point; `README.md` is companion documentation and is
ignored by discovery. Additional helper modules can live alongside `index.ts`
and be imported normally.
