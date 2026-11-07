# Test suite for `git-tracked-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-tracked-files"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: lists committed files and intent-to-add entries" {
    setup_initial_commit
    setup_committed_file "tracked.txt"
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == *"tracked.txt"* ]]
    [[ "$output" == *"new.txt"* ]]
}

@test "defaults: excludes untracked files" {
    setup_initial_commit
    setup_untracked "loose.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" != *"loose.txt"* ]]
}

@test "defaults: empty in a fresh repo" {
    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: pathspec limits the listing" {
    setup_initial_commit
    setup_committed_file "alpha.txt"
    setup_committed_file "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "alpha.txt"
    [[ "$output" == "alpha.txt" ]]
}

@test "cli: --rel prints paths relative to the current directory" {
    setup_committed_file "sub/a.txt"
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "a.txt" ]]
}

@test "cli: --rel prefixes a path outside the current directory with .." {
    setup_committed_file "top.txt"
    mkdir -p sub
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "../top.txt" ]]
}
