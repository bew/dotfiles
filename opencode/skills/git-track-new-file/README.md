# git-track-new-file skill

Companion skill for the `git-track-new-file` tool artefact.

The tool handles the mechanics (`git add -N`, skip heuristics, symlink resolution).
This skill ensures the agent knows *when* to call it — after every tool call that creates new
files or directories — and gates on whether the current directory is a git repository at all.

Without this skill, the agent has no instruction to call the tool after `write` calls or
other file-creating operations, so new files would go untracked until the user manually stages them.
