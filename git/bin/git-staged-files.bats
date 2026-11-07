# Test suite for `git-staged-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-staged-files"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: lists a staged modification" {
    setup_initial_commit
    setup_committed_file "tracked.txt"
    echo "change" >> tracked.txt
    git add tracked.txt

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "tracked.txt" ]]
}

@test "defaults: lists a staged new file" {
    setup_initial_commit
    setup_staged "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new.txt" ]]
}

@test "defaults: staged rename shows only its destination" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new.txt" ]]
}

@test "defaults: lists paths with spaces" {
    setup_initial_commit
    setup_staged "a file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "a file.txt" ]]
}

@test "defaults: empty when nothing is staged" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: pathspec limits the listing" {
    setup_initial_commit
    setup_staged "alpha.txt"
    setup_staged "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "alpha.txt"
    [[ "$output" == "alpha.txt" ]]
}

@test "cli: --rel prints paths relative to the current directory" {
    setup_initial_commit
    setup_staged "sub/a.txt"
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "a.txt" ]]
}

@test "cli: --rel prefixes a path outside the current directory with .." {
    setup_initial_commit
    setup_staged "top.txt"
    mkdir -p sub
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "../top.txt" ]]
}
