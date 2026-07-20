# Test suite for `git-without-new-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# shellcheck disable=SC2164 # bats ensures `set -e`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-without-new-files"

# Setup a fresh git repo and cd into it for each test.
# Also prepend SCRIPT_DIR to PATH so `git new-files` resolves as a git subcommand.
function setup() {
    TEST_REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    export PATH="$SCRIPT_DIR:$PATH"
}

# Add a file with intent-to-add (git add -N)
function setup_intent_to_add() {
    local file="$1"
    touch "$file"
    git add -N "$file"
}

# Create an initial commit so the repo is not empty
function setup_initial_commit() {
    echo "init" > README
    git add README
    git commit -q -m "init"
}

# Simulate an ununstaged rename: mv + git add -N (requires old file to be committed)
function setup_rename() {
    local old_file="$1"
    local new_file="$2"
    mv "$old_file" "$new_file"
    git add -N "$new_file"
}

# Assert that a file is intent-to-add in the index (porcelain status " A")
function assert_intent_to_add() {
    local file="$1"
    local status
    status="$(git status --porcelain "$file")"
    [[ "$status" == " A $file" ]]
}

# Assert that a file is NOT in the index at all (untracked "??")
function assert_not_in_index() {
    local file="$1"
    local status
    status="$(git status --porcelain "$file")"
    [[ "$status" == "?? $file" ]]
}

# ------------------------------------------------------------------------------
# Tests: helpers

@test "helpers: assert_intent_to_add detects intent-to-add file" {
    setup_intent_to_add "new.txt"
    assert_intent_to_add "new.txt"
}

@test "helpers: assert_not_in_index detects untracked file" {
    touch "untracked.txt"
    assert_not_in_index "untracked.txt"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: runs wrapped command successfully" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" status
    # echo "output: '$output'"
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

# ------------------------------------------------------------------------------
# Tests: new file handling (success path)

@test "new-files: temporarily removes intent-to-add files before running command" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    # Use `git status --porcelain` as the wrapped command and capture its output
    # via stderr (since wrapped stdout is not propagated)
    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$stderr" == *"Temporarily removing 1 new files from index"* ]]
}

@test "new-files: restores intent-to-add files after successful command" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    assert_intent_to_add "new.txt"
}

@test "new-files: restores multiple intent-to-add files after successful command" {
    setup_initial_commit
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    assert_intent_to_add "alpha.txt"
    assert_intent_to_add "beta.txt"
}

@test "new-files: logs restore action on success" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$stderr" == *"Restoring intent-to-add files to index"* ]]
}

# ------------------------------------------------------------------------------
# Tests: rename handling (success path)

@test "renames: temporarily removes unstaged rename before running command" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    [[ "$stderr" == *"Temporarily removing 1 new files from index"* ]]
}

@test "renames: restores unstaged rename as intent-to-add after successful command" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" status
    assert_intent_to_add "new.txt"
}

@test "renames: does NOT restore unstaged rename when wrapped command fails" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    assert_not_in_index "new.txt"
}

@test "renames: lists unrestored rename path in stderr on failure" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"new.txt"* ]]
}

# ------------------------------------------------------------------------------
# Tests: exit code propagation

@test "exit-code: propagates exit code from wrapped command on failure" {
    setup_initial_commit

    # `git show nonexistent-ref` exits 128
    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$status" -eq 128 ]]
}

@test "exit-code: exits 0 when wrapped command succeeds" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH" status
}

# ------------------------------------------------------------------------------
# Tests: failure path

@test "failure: does NOT restore intent-to-add files when wrapped command fails" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    assert_not_in_index "new.txt"
}

@test "failure: logs warning that new files were not restored" {
    setup_initial_commit
    setup_intent_to_add "new.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"New files were NOT restored"* ]]
    [[ "$stderr" == *"new.txt"* ]]
}

@test "failure: lists each unrestored file in stderr" {
    setup_initial_commit
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"alpha.txt"* ]]
    [[ "$stderr" == *"beta.txt"* ]]
}

@test "failure: reports (none) when no new files were present" {
    setup_initial_commit

    run --separate-stderr "$SCRIPT_PATH" show nonexistent-ref
    [[ "$stderr" == *"(none)"* ]]
}
