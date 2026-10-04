# git-track-new-file skill

Companion skill for the `git-track-new-file` plugin.

The tool handles the mechanics (`git add -N`, secret/gitignore skips, symlink resolution).
This skill owns when to call it and which paths to skip, and gates on whether the current directory is a git repository at all.

Without this skill, the agent has no instruction to call the tool after `write` calls or
other file-creating operations, so new files would go untracked until the user manually stages them.
