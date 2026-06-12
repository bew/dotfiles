# Phase:ship — Write (new artefacts only)

Copy all files from `$draftpath` to `$installpath`.
For skills, create full directory structure including any `./references/`, `./scripts/`, `./assets/`, `./templates/` or `tests/` dirs.

After confirming all files are written successfully, clean up:
Must use `trash $draftpath` (never `rm -rf`).
