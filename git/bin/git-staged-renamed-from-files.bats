# Test suite for `git-staged-renamed-from-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-staged-renamed-from-files"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: lists the old path of a staged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "old.txt" ]]
}

@test "defaults: lists old paths with spaces" {
    setup_initial_commit
    setup_committed_file "old file.txt"
    setup_staged_rename "old file.txt" "new file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "old file.txt" ]]
}

@test "defaults: ignores a plain staged addition" {
    setup_initial_commit
    setup_staged "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "defaults: empty when nothing is staged" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: --rel prints paths relative to the current directory" {
    setup_initial_commit
    setup_committed_file "sub/old.txt"
    setup_staged_rename "sub/old.txt" "sub/new.txt"
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "old.txt" ]]
}

@test "cli: --rel prefixes a path outside the current directory with .." {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged_rename "old.txt" "new.txt"
    mkdir -p sub
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "../old.txt" ]]
}
