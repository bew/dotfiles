# Test suite for the shared `git/bin/_bats_helpers.sh` test helpers
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"

# ------------------------------------------------------------------------------
# Tests: helpers

@test "helpers: assert_intent_to_add detects intent-to-add file" {
    setup_intent_to_add "new.txt"
    assert_intent_to_add "new.txt"
}

@test "helpers: assert_untracked detects untracked file" {
    setup_untracked "untracked.txt"
    assert_untracked "untracked.txt"
}

@test "helpers: assert_staged_new detects staged new file" {
    setup_staged "new.txt"
    assert_staged_new "new.txt"
}

@test "helpers: assert_staged_rename detects staged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged_rename "old.txt" "new.txt"
    assert_staged_rename "old.txt" "new.txt"
}

@test "helpers: assert_unstaged_rename detects unstaged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"
    assert_unstaged_rename "old.txt" "new.txt"
}
