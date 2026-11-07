# Test suite for `git-untrack` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-untrack"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: drops a committed path from the index, keeping the file" {
    setup_initial_commit
    setup_committed_file "tracked.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "tracked.txt"

    # Dropping a committed path from the index also records a staged deletion,
    # so the path shows up twice: `D` (index vs HEAD) and `??` (work tree).
    local porcelain
    porcelain="$(git status --porcelain -- tracked.txt)"
    [[ "$porcelain" == *"D  tracked.txt"* ]]
    [[ "$porcelain" == *"?? tracked.txt"* ]]
    [[ -f "tracked.txt" ]]
}

@test "defaults: drops an intent-to-add entry" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "new.txt"
    assert_untracked "new.txt"
}

@test "defaults: forwards flags to git rm" {
    setup_initial_commit
    setup_staged "file.txt"
    echo "more" >> file.txt

    run -1 --separate-stderr "$SCRIPT_PATH" "file.txt"
    run -0 --separate-stderr "$SCRIPT_PATH" "-f" "file.txt"
    assert_untracked "file.txt"
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: reports a git rm failure" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH" "missing.txt"
    [[ "$stderr" == *"!! ERROR: could not untrack:"* ]]
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: requires a pathspec" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"usage: git untrack <pathspec>..."* ]]
}

@test "usage: rejects flags without a pathspec" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH" "-r"
    [[ "$stderr" == *"usage: git untrack <pathspec>..."* ]]
}
