# Test suite for `git-restore-from` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-restore-from"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: restores a path from the given revision" {
    setup_initial_commit
    setup_committed_file "tracked.txt"
    echo "second" > tracked.txt
    git commit -qam "second"

    run -0 --separate-stderr "$SCRIPT_PATH" "HEAD~1" "tracked.txt"
    [[ "$(cat tracked.txt)" == "content" ]]
}

@test "defaults: pathspec limits the restore" {
    setup_initial_commit
    setup_committed_file "a.txt"
    setup_committed_file "b.txt"
    echo "changed a" > a.txt
    echo "changed b" > b.txt
    git add a.txt b.txt
    git commit -qm "change both"

    run -0 --separate-stderr "$SCRIPT_PATH" "HEAD~1" "a.txt"
    [[ "$(cat a.txt)" == "content" ]]
    [[ "$(cat b.txt)" == "changed b" ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: reports an unknown revision" {
    setup_initial_commit
    setup_committed_file "tracked.txt"

    run -1 --separate-stderr "$SCRIPT_PATH" "no-such-rev" "tracked.txt"
    [[ "$stderr" == *"!! ERROR: could not restore from no-such-rev:"* ]]
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: requires a revision and a pathspec" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"usage: git restore-from <rev> <pathspec>..."* ]]
}

@test "usage: requires a pathspec" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH" "HEAD"
    [[ "$stderr" == *"usage: git restore-from <rev> <pathspec>..."* ]]
}
