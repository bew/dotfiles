# Test suite for `git-unstage-keep-new` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-unstage-keep-new"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: unstages a staged modification" {
    setup_initial_commit
    setup_committed_file "tracked.txt"
    echo "change" >> tracked.txt
    git add tracked.txt

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    [[ "$(git status --porcelain -- tracked.txt)" == " M tracked.txt" ]]
}

@test "defaults: keeps a staged new file as intent-to-add" {
    setup_initial_commit
    setup_staged "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_intent_to_add "new.txt"
}

@test "defaults: turns a staged rename back into an unstaged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_unstaged_rename "old.txt" "new.txt"
}

@test "defaults: leaves a pre-existing intent-to-add entry untouched" {
    setup_initial_commit
    setup_intent_to_add "existing.txt"
    setup_staged "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_intent_to_add "existing.txt"
}

@test "defaults: pathspec limits the reset to the given path" {
    setup_initial_commit
    setup_committed_file "tracked.txt"
    echo "change" >> tracked.txt
    git add tracked.txt
    setup_staged "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "tracked.txt"
    [[ "$(git status --porcelain -- tracked.txt)" == " M tracked.txt" ]]
    assert_staged_new "new.txt"
}

@test "defaults: no-op when nothing is staged" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: works on an unborn branch" {
    setup_staged "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "."
    assert_intent_to_add "new.txt"
}

@test "edge: pathspec '.' scopes to the current directory" {
    setup_initial_commit
    setup_committed_file "sub/x.txt"
    setup_staged "y.txt"
    echo "change" >> sub/x.txt
    git add sub/x.txt

    cd sub
    run -0 --separate-stderr "$SCRIPT_PATH" "."
    cd "$TEST_REPO"
    [[ "$(git status --porcelain -- sub/x.txt)" == " M sub/x.txt" ]]
    assert_staged_new "y.txt"
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: requires a pathspec" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"usage: git unstage <pathspec>..."* ]]
}
