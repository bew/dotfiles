# Phase:Ship — Write (new artefacts only)

IMPORTANT: Do not enter this phase unless `Phase:Review` has completed and user has explicitly
confirmed shipping (e.g. "yes", "ship", "proceed"). A generic "next" or "go" does not count.
If review was skipped: stop, run `Phase:Review` first, then return here.

Copy all files from `$draftpath` to `$installpath`.
For skills, create full directory structure including any `./refs/`, `./scripts/`, `./assets/`, `./templates/` or `tests/` dirs.

After all files written successfully, clean up:
Must use `trash $draftpath` (never `rm -rf`).
