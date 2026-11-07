# Test suite for `git-without-new-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-without-new-files"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: runs wrapped command successfully" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$output" == $'On branch main\nnothing to commit, working tree clean' ]]
    [[ "$stderr" == *"Running: git status"* ]]
    [[ "$stderr" == *"Wrapped git command succeeded"* ]]
}

@test "defaults: logs to stderr, not stdout" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$output" == $'On branch main\nnothing to commit, working tree clean' ]]
    [[ -n "$stderr" ]]
}

@test "defaults: reports no new files when none present" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$stderr" == *"No new files found"* ]]
}

@test "defaults: temporarily removes intent-to-add files before running command" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$stderr" == *"Temporarily removing 1 new files from index"* ]]
}

@test "defaults: restores intent-to-add files after successful command" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    assert_intent_to_add "new.txt"
}

@test "defaults: restores multiple intent-to-add files after successful command" {
    setup_initial_commit
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    assert_intent_to_add "alpha.txt"
    assert_intent_to_add "beta.txt"
}

@test "defaults: logs restore action on success" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$stderr" == *"Restoring intent-to-add files to index"* ]]
}

@test "defaults: temporarily removes unstaged rename before running command" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$stderr" == *"Temporarily removing 1 new files from index"* ]]
}

@test "defaults: restores unstaged rename as intent-to-add after successful command" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    assert_intent_to_add "new.txt"
}

@test "defaults: exits 0 when wrapped command succeeds" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" status
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: does NOT restore unstaged rename when wrapped command fails" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    assert_untracked "new.txt"
}

@test "error: lists unrestored rename path in stderr on failure" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"new.txt"* ]]
}

@test "error: propagates exit code from wrapped command on failure" {
    setup_initial_commit

    # `git show nonexistent-ref` exits 128
    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$status" -eq 128 ]]
}

@test "error: does NOT restore intent-to-add files when wrapped command fails" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    assert_untracked "new.txt"
}

@test "error: logs warning that new files were not restored" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"New files were NOT restored"* ]]
    [[ "$stderr" == *"new.txt"* ]]
}

@test "error: lists each unrestored file in stderr" {
    setup_initial_commit
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"alpha.txt"* ]]
    [[ "$stderr" == *"beta.txt"* ]]
}

@test "error: reports (none) when no new files were present" {
    setup_initial_commit

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"(none)"* ]]
}
