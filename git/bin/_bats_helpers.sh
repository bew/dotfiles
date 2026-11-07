# Shared setup and assertion helpers for the `git/bin/` test suites.
#
# Each per-command `.bats` file sources this module with `load _bats_helpers.sh`.
# It provides a fresh-repo `setup()`, repository fixtures, porcelain assertions,
# and a JSON-output wrapper.
#
# The loading test file must define `SCRIPT_DIR` before `setup()` runs;
# the helper prepends it to `PATH` so the scripts under test can invoke each
# other as git subcommands (e.g. `git unstage-keep-new` runs `git staged-files`).

# Each test runs in a fresh repo so index state never leaks between tests.
function setup() {
    TEST_REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TEST_REPO"
    # shellcheck disable=SC2164 # bats runs tests under `set -e`
    cd "$TEST_REPO"
    git init -q -b main
    git config user.email "test@example.com"
    git config user.name "Test"
    export PATH="$SCRIPT_DIR:$PATH"
}

# Create an initial commit so the repo has a HEAD to diff against
function setup_initial_commit() {
    echo "init" > README
    git add README
    git commit -q -m "init"
}

# Commit a tracked file, so a later move has a HEAD version to rename from
function setup_committed_file() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    echo "content" > "$path"
    git add "$path"
    git commit -q -m "add $path"
}

# Add a file with intent-to-add (git add -N)
function setup_intent_to_add() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    touch "$path"
    git add -N "$path"
}

# Stage a file fully (git add)
function setup_staged() {
    local path="$1"
    local content="${2:-staged content}"
    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
    git add "$path"
}

# Leave a file untracked
function setup_untracked() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    touch "$path"
}

# Simulate an unstaged rename: mv + add -N (the old path must be committed)
function setup_unstaged_rename() {
    local old_path="$1"
    local new_path="$2"
    mv "$old_path" "$new_path"
    git add -N "$new_path"
}

# Simulate a staged rename: mv + add both paths (the old path must be committed)
function setup_staged_rename() {
    local old_path="$1"
    local new_path="$2"
    mv "$old_path" "$new_path"
    git add "$old_path" "$new_path"
}

# Assert a path is tracked as intent-to-add (porcelain " A")
function assert_intent_to_add() {
    local path="$1"
    local status
    status="$(git status --porcelain -- "$path")"
    [[ "$status" == " A $path" ]]
}

# Assert a path is untracked (porcelain "??")
function assert_untracked() {
    local path="$1"
    local status
    status="$(git status --porcelain -- "$path")"
    [[ "$status" == "?? $path" ]]
}

# Assert a path is staged as a new file (porcelain "A ")
function assert_staged_new() {
    local path="$1"
    local status
    status="$(git status --porcelain -- "$path")"
    [[ "$status" == "A  $path" ]]
}

# Assert the index reports a staged rename.
# `-z` records a rename destination-first and NUL-separated, which keeps paths
# with spaces intact (the plain ` -> ` format quotes them).
function assert_staged_rename() {
    local old_path="$1"
    local new_path="$2"
    local status
    status="$(git status --porcelain -z)"
    [[ "$status" == *"R  $new_path"$'\0'"$old_path"$'\0'* ]]
}

# Assert the work tree reports an unstaged rename (see assert_staged_rename)
function assert_unstaged_rename() {
    local old_path="$1"
    local new_path="$2"
    local status
    status="$(git status --porcelain -z)"
    [[ "$status" == *" R $new_path"$'\0'"$old_path"$'\0'* ]]
}

# Run a script with --json and expose its compact JSON as $compact_json_output
function run_json() {
    run -0 --separate-stderr "$@"
    compact_json_output="$(jq -c '.' <<< "$output")"
}
