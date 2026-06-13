# Phase:Ship — Write (new artefacts only)

Copy all files from `$draftpath` to `$installpath`.
For skills, create full directory structure including any `./refs/`, `./scripts/`, `./assets/`, `./templates/` or `tests/` dirs.

After all files written successfully, clean up:
Must use `trash $draftpath` (never `rm -rf`).
