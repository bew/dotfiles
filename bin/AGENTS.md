# Shell Script Writing & Testing Guide

## Shell Script Writing Style

Load the `write-script-bash` skill (builds on `write-script-generic`) before writing or reviewing bash scripts.

## Testing with Bats

Load the `write-script-bats` skill before writing or reviewing `.bats` test files.

## Example well-written scripts

See these scripts in `bin/` for complete examples (with Bats tests):
- `envrg` & `envrg.bats` — environment variable grepper with smart-case, color handling, on-demand stdin piping
- `gen-random-string` & `gen-random-string.bats` — flexible random string generator with charset rules
