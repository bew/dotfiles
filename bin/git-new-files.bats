# Test suite for `git-new-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# shellcheck disable=SC2164 # bats ensures `set -e`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-new-files"

# Setup a fresh git repo and cd into it for each test
function setup() {
    TEST_REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
}

# Add a file with intent-to-add (git add -N)
function setup_intent_to_add() {
    local file="$1"
    touch "$file"
    git add -N "$file"
}

# Stage a file fully (git add)
function setup_staged() {
    local file="$1"
    local content="${2:-staged content}"
    echo "$content" > "$file"
    git add "$file"
}

# Leave a file untracked
function setup_untracked() {
    local file="$1"
    touch "$file"
}

# Create an initial commit so the repo is not empty
function setup_initial_commit() {
    echo "init" > README
    git add README
    git commit -q -m "init"
}

# Run script with --json and expose compact output as $compact_json_output
function run_script_json() {
    run -0 --separate-stderr "$SCRIPT_PATH" --json
    compact_json_output="$(jq -c '.' <<< "$output")"
}

# Simulate an unstaged rename: mv + git add -N (requires old file to be committed)
function setup_rename() {
    local old_file="$1"
    local new_file="$2"
    mv "$old_file" "$new_file"
    git add -N "$new_file"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: shows intent-to-add file with 'new file:' label" {
    setup_intent_to_add "new-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new file: new-file.txt" ]]
}

@test "defaults: shows multiple intent-to-add files with 'new file:' label" {
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == *"new file: alpha.txt"* ]]
    [[ "$output" == *"new file: beta.txt"* ]]
}

@test "defaults: shows unstaged rename with 'renamed:' label" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == " renamed: new.txt" ]]
}

@test "defaults: shows both intent-to-add and renamed files together" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"
    setup_intent_to_add "brand-new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == *"new file: brand-new.txt"* ]]
    [[ "$output" == *"renamed: new.txt"* ]]
}

@test "defaults: no output when no intent-to-add files" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "defaults: empty repo with no files produces no output" {
    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: --raw outputs bare paths without XY prefix" {
    setup_intent_to_add "new-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == "new-file.txt" ]]
}


@test "cli: --raw with multiple files outputs one path per line" {
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == *"alpha.txt"* ]]
    [[ "$output" == *"beta.txt"* ]]
    # No label prefix on any line
    [[ ! "$output" =~ "new file:" ]]
}

@test "cli: --raw outputs bare new path for unstaged rename" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == "new.txt" ]]
}

# ------------------------------------------------------------------------------
# Tests: json

@test "json: --json outputs array with kind and path for intent-to-add file" {
    setup_intent_to_add "new-file.txt"

    run_script_json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"new-file","path":"new-file.txt"}]' ]]
}

@test "json: --json outputs kind rename for unstaged rename" {
    setup_initial_commit
    echo "content" > old.txt
    git add old.txt && git commit -q -m "add old.txt"
    setup_rename "old.txt" "new.txt"

    run_script_json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"rename","path":"new.txt","old_path":"old.txt"}]' ]]
}

@test "json: --json handles paths with spaces in rename" {
    setup_initial_commit
    echo "content" > "old file.txt"
    git add "old file.txt" && git commit -q -m "add old file"
    setup_rename "old file.txt" "new file.txt"

    run_script_json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"rename","path":"new file.txt","old_path":"old file.txt"}]' ]]
}

@test "json: --json handles paths with spaces for intent-to-add" {
    setup_intent_to_add "new file.txt"

    run_script_json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"new-file","path":"new file.txt"}]' ]]
}

@test "json: --json outputs empty array when no new files" {
    setup_initial_commit

    run_script_json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[]' ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: staged files (fully added) are not shown" {
    setup_initial_commit
    setup_staged "staged-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "edge: untracked files are not shown" {
    setup_initial_commit
    setup_untracked "untracked-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "edge: only intent-to-add shown when mix of file states present" {
    setup_initial_commit
    setup_intent_to_add "new-file.txt"
    setup_staged "staged-file.txt"
    setup_untracked "untracked-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new file: new-file.txt" ]]
    [[ ! "$output" =~ staged-file ]]
    [[ ! "$output" =~ untracked-file ]]
}

@test "edge: intent-to-add file in subdirectory shows full relative path" {
    mkdir -p sub/dir
    touch sub/dir/nested.txt
    git add -N sub/dir/nested.txt

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new file: sub/dir/nested.txt" ]]
}

@test "edge: --raw with subdirectory file shows full relative path" {
    mkdir -p sub/dir
    touch sub/dir/nested.txt
    git add -N sub/dir/nested.txt

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == "sub/dir/nested.txt" ]]
}
