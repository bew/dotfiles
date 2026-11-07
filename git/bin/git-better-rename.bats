# Test suite for `git-better-rename` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-better-rename"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: move stays an unstaged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    assert_unstaged_rename "old.txt" "new.txt"
}

@test "defaults: leaves nothing staged" {
    setup_initial_commit
    setup_committed_file "old.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    [[ -z "$(git diff --cached --name-only)" ]]
}

@test "defaults: handles paths with spaces" {
    setup_initial_commit
    setup_committed_file "old file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "old file.txt" "new file.txt"
    assert_unstaged_rename "old file.txt" "new file.txt"
}

@test "defaults: moves into a subdirectory" {
    setup_initial_commit
    setup_committed_file "old.txt"
    mkdir -p sub

    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "sub/old.txt"
    assert_unstaged_rename "old.txt" "sub/old.txt"
}

@test "defaults: keeps pre-existing staged changes staged" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged "unrelated.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    assert_staged_new "unrelated.txt"
    assert_unstaged_rename "old.txt" "new.txt"
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: dry run does not touch the index" {
    setup_initial_commit
    setup_committed_file "old.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" -n "old.txt" "new.txt"
    [[ -z "$(git diff --cached --name-only)" ]]
}

@test "cli: --staged leaves the move staged" {
    setup_initial_commit
    setup_committed_file "old.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --staged "old.txt" "new.txt"
    assert_staged_rename "old.txt" "new.txt"
}

@test "cli: --staged keeps pre-existing staged changes staged" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged "unrelated.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --staged "old.txt" "new.txt"
    assert_staged_new "unrelated.txt"
    assert_staged_rename "old.txt" "new.txt"
}

@test "cli: --undo reverses an unstaged move" {
    setup_initial_commit
    setup_committed_file "old.txt"
    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --undo "old.txt" "new.txt"
    [[ -e "old.txt" ]]
    [[ ! -e "new.txt" ]]
    [[ -z "$(git status --porcelain)" ]]
}

@test "cli: --undo is idempotent" {
    setup_initial_commit
    setup_committed_file "old.txt"
    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    run -0 --separate-stderr "$SCRIPT_PATH" --undo "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --undo "old.txt" "new.txt"
    [[ "$stderr" == *"already undone"* ]]
    [[ -z "$(git status --porcelain)" ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: --undo reverses a multi-file move" {
    setup_initial_commit
    setup_committed_file "a.txt"
    setup_committed_file "b.txt"
    mkdir -p sub

    run -0 --separate-stderr "$SCRIPT_PATH" "a.txt" "b.txt" "sub"
    run -0 --separate-stderr "$SCRIPT_PATH" --undo "a.txt" "b.txt" "sub"

    [[ -e "a.txt" ]]
    [[ -e "b.txt" ]]
    [[ ! -e "sub/a.txt" ]]
    [[ ! -e "sub/b.txt" ]]
    [[ -z "$(git status --porcelain)" ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: propagates a failure from git mv" {
    setup_initial_commit
    setup_committed_file "old.txt"

    # `git mv` refuses a missing source; the wrapper must exit non-zero
    run --separate-stderr "$SCRIPT_PATH" "missing.txt" "new.txt"
    [[ "$status" -ne 0 ]]
    [[ -z "$(git diff --cached --name-only)" ]]
}

@test "error: --undo needs a source and a destination" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH" --undo "only.txt"
    [[ "$stderr" == *"needs <src>... <dst>"* ]]
}

@test "error: --undo of a multi-file move needs an existing directory" {
    setup_initial_commit
    setup_committed_file "a.txt"
    setup_committed_file "b.txt"

    run -1 --separate-stderr "$SCRIPT_PATH" --undo "a.txt" "b.txt" "missing-dir"
    [[ "$stderr" == *"needs an existing directory"* ]]
}
