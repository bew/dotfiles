# Test suite for `git-stage-rename` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-stage-rename"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: stages a 100% rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    [[ "$(git diff --cached --name-status -M)" == "R100"$'\t'"old.txt"$'\t'"new.txt" ]]
}

@test "defaults: keeps the destination's edits unstaged" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"
    echo "edited" >> new.txt

    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    [[ "$(git status --porcelain)" == "RM old.txt -> new.txt" ]]
    # The index holds the committed content, the edit stays in the work tree.
    [[ "$(git cat-file -p :new.txt)" == "content" ]]
    [[ "$(git diff --name-only -- new.txt)" == "new.txt" ]]
}

@test "defaults: keeps the source file mode" {
    setup_initial_commit
    setup_committed_file "run.sh"
    chmod +x run.sh
    git add run.sh
    git commit -q -m "make executable"
    setup_unstaged_rename "run.sh" "tool.sh"

    run -0 --separate-stderr "$SCRIPT_PATH" "run.sh" "tool.sh"
    [[ "$(git ls-files --stage -- tool.sh)" == 100755* ]]
}

@test "defaults: leaves other staged changes untouched" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_staged "unrelated.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    assert_staged_rename "old.txt" "new.txt"
    assert_staged_new "unrelated.txt"
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: handles paths with spaces" {
    setup_initial_commit
    setup_committed_file "old file.txt"
    setup_unstaged_rename "old file.txt" "new file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" "old file.txt" "new file.txt"
    assert_staged_rename "old file.txt" "new file.txt"
}

@test "cli: resolves paths from a subdirectory" {
    setup_initial_commit
    setup_committed_file "sub/old.txt"
    setup_unstaged_rename "sub/old.txt" "sub/new.txt"

    cd sub
    run -0 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    assert_staged_rename "sub/old.txt" "sub/new.txt"
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: rejects a missing path" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH" "old.txt"
    [[ "$stderr" == *"usage: git stage-rename <old-path> <new-path>"* ]]
}

@test "usage: rejects extra arguments" {
    setup_initial_commit

    run -1 --separate-stderr "$SCRIPT_PATH" "a" "b" "c"
    [[ "$stderr" == *"usage: git stage-rename <old-path> <new-path>"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: refuses a source with no index entry" {
    setup_initial_commit
    setup_untracked "new.txt"

    run -1 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    [[ "$stderr" == *"old.txt has no index entry"* ]]
    [[ -z "$(git diff --cached --name-only)" ]]
}

@test "error: refuses a destination holding staged content" {
    setup_initial_commit
    setup_committed_file "old.txt"
    mv old.txt new.txt
    echo "different content" > new.txt
    git add new.txt

    run -1 --separate-stderr "$SCRIPT_PATH" "old.txt" "new.txt"
    [[ "$stderr" == *"new.txt already has staged content"* ]]
    [[ "$(git cat-file -p :new.txt)" == "different content" ]]
}
