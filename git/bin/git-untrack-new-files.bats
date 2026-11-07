# Test suite for `git-untrack-new-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-untrack-new-files"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: makes an intent-to-add file untracked" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_untracked "new.txt"
}

@test "defaults: untracks the destination of an unstaged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_untracked "new.txt"
}

@test "defaults: leaves a staged new file staged" {
    setup_initial_commit
    setup_staged "staged.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_staged_new "staged.txt"
}

@test "defaults: no-op when there are no new files" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: pathspec limits the untracking" {
    setup_initial_commit
    setup_intent_to_add "a.txt"
    setup_intent_to_add "sub/b.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "a.txt"
    assert_untracked "a.txt"
    assert_intent_to_add "sub/b.txt"
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: requires a pathspec" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"usage: git untrack-new-files <pathspec>..."* ]]
}
