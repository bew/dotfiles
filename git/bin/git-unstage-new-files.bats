# Test suite for `git-unstage-new-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-unstage-new-files"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: prints the staged new files then unstages them" {
    setup_initial_commit
    setup_staged "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    [[ "$output" == $'New files:\nnew.txt\n\nUnstaging...' ]]
    assert_intent_to_add "new.txt"
}

@test "defaults: turns a staged rename back into an unstaged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_unstaged_rename "old.txt" "new.txt"
}

@test "defaults: leaves a staged modification staged" {
    setup_initial_commit
    setup_committed_file "tracked.txt"
    echo "change" >> tracked.txt
    git add tracked.txt

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    [[ "$(git status --porcelain -- tracked.txt)" == "M  tracked.txt" ]]
}

@test "defaults: reports no files when nothing is staged as new" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    [[ "$output" == $'New files:\n\nUnstaging...' ]]
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: requires a pathspec" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"usage: git unstage-new-files <pathspec>..."* ]]
}
