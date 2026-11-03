# Test suite for `tag-please` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $BATS_TEST_FILENAME [--filter topic]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/tag-please"

# Fresh tagged repo before each test, so tag/commit state is isolated.
function setup() {
    TEST_REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    git config commit.gpgsign false
    printf '1.2.3\n' > VERSION
    git add VERSION
    git commit -qm "initial"
    git tag v1.2.3
}

# Drop VERSION from the test repo, committing the removal.
function setup_repo_without_version() {
    git rm -q VERSION
    git commit -qm "drop VERSION"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: empty input bumps minor" {
    run -0 "$SCRIPT_PATH" <<< $'\n\n'
    [[ "$(git tag --list v1.3.0)" == "v1.3.0" ]]
    [[ "$(cat VERSION)" == "1.3.0" ]]
}

@test "defaults: default commit message names the release" {
    run -0 "$SCRIPT_PATH" <<< $'\n\n'
    [[ "$(git log -1 --format=%s)" == "misc: release v1.3.0" ]]
}

@test "defaults: first section shows the detected last tag" {
    run -0 "$SCRIPT_PATH" <<< 'q'
    [[ "$output" == *"Last tag: v1.2.3"* ]]
}

@test "defaults: section headers use the :: prefix" {
    run -0 "$SCRIPT_PATH" <<< 'q'
    [[ "$output" == *":: Commits since v1.2.3:"* ]]
}

@test "defaults: missing VERSION is skipped" {
    setup_repo_without_version
    run -0 "$SCRIPT_PATH" <<< $'\n\n'
    [[ "$(git tag --list v1.3.0)" == "v1.3.0" ]]
    [[ ! -e VERSION ]]
    [[ "$(git rev-list --count HEAD)" == "2" ]]
}

@test "defaults: warns and assumes v0.0.0 when no tag exists" {
    git tag -d v1.2.3 >/dev/null
    run -0 --separate-stderr "$SCRIPT_PATH" <<< $'m\n\n'
    [[ "$stderr" == *"WARNING"* ]]
    [[ "$(git tag --list v0.1.0)" == "v0.1.0" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: literal tag is used verbatim" {
    run -0 "$SCRIPT_PATH" <<< $'v9.9.9\n\n'
    [[ "$(git tag --list v9.9.9)" == "v9.9.9" ]]
    [[ "$(cat VERSION)" == "9.9.9" ]]
}

@test "cli: m and minor bump minor" {
    run -0 "$SCRIPT_PATH" <<< $'m\n\n'
    [[ "$(git tag --list v1.3.0)" == "v1.3.0" ]]
}

@test "cli: M and major bump major" {
    run -0 "$SCRIPT_PATH" <<< $'M\n\n'
    [[ "$(git tag --list v2.0.0)" == "v2.0.0" ]]
}

@test "cli: p and patch bump patch" {
    run -0 "$SCRIPT_PATH" <<< $'p\n\n'
    [[ "$(git tag --list v1.2.4)" == "v1.2.4" ]]
}

@test "cli: custom commit message is used" {
    run -0 "$SCRIPT_PATH" <<< $'p\ny\n\nchore: cut release\n'
    [[ "$(git log -1 --format=%s)" == "chore: cut release" ]]
}

@test "cli: literal tag is not confirmed" {
    run -0 "$SCRIPT_PATH" <<< $'v9.9.9\n\nchore: cut release\n'
    [[ "$(git tag --list v9.9.9)" == "v9.9.9" ]]
    [[ "$(git log -1 --format=%s)" == "chore: cut release" ]]
}

@test "cli: declining a bump re-asks for the tag" {
    run -0 "$SCRIPT_PATH" <<< $'p\nn\nM\ny\n\n'
    [[ "$(git tag --list v2.0.0)" == "v2.0.0" ]]
    [[ "$(git tag --list v1.2.4)" == "" ]]
}

@test "cli: accepting VERSION creation writes and commits it" {
    setup_repo_without_version
    run -0 "$SCRIPT_PATH" <<< $'\n\ny\n'
    [[ "$(git show HEAD:VERSION)" == "1.3.0" ]]
    [[ -z "$(git status --porcelain)" ]]
}

@test "cli: declining VERSION update tags HEAD without a commit" {
    run -0 "$SCRIPT_PATH" <<< $'\n\nn\n'
    [[ "$(git tag --list v1.3.0)" == "v1.3.0" ]]
    [[ "$(cat VERSION)" == "1.2.3" ]]
    [[ "$(git rev-list --count HEAD)" == "1" ]]
    [[ "$(git rev-parse v1.3.0)" == "$(git rev-parse HEAD)" ]]
}

@test "cli: q aborts without changes" {
    run -0 "$SCRIPT_PATH" <<< 'q'
    [[ "$(git tag --list | wc -l | tr -d ' ')" == "1" ]]
    [[ "$(cat VERSION)" == "1.2.3" ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: dirty worktree aborts" {
    touch dirtyfile
    run -1 --separate-stderr "$SCRIPT_PATH" <<< $'m\n\n'
    [[ "$(git tag --list | wc -l | tr -d ' ')" == "1" ]]
    [[ "$stderr" == *"ERROR"* ]]
}

@test "error: last tag not starting with v aborts" {
    git tag -d v1.2.3 >/dev/null
    git tag bad-tag
    run -1 --separate-stderr "$SCRIPT_PATH" <<< $'m\n\n'
    [[ "$stderr" == *"does not start with"* ]]
    [[ "$(git tag --list | wc -l | tr -d ' ')" == "1" ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: VERSION already at the target is not re-committed" {
    printf '1.3.0\n' > VERSION
    git commit -qam "bump VERSION"
    run -0 "$SCRIPT_PATH" <<< 'v1.3.0'
    [[ "$(git rev-list --count HEAD)" == "2" ]]
    [[ "$(git rev-parse v1.3.0)" == "$(git rev-parse HEAD)" ]]
    [[ -z "$(git status --porcelain)" ]]
}

# ------------------------------------------------------------------------------
# Tests: integration

@test "integration: action log lines use the → prefix" {
    run -0 "$SCRIPT_PATH" <<< $'\n\n'
    [[ "$output" == *":: Releasing as v1.3.0"* ]]
    [[ "$output" == *"→ Writing VERSION 1.3.0"* ]]
    [[ "$output" == *"→ Staging VERSION"* ]]
    [[ "$output" == *"→ Committing VERSION"* ]]
    [[ "$output" == *"→ Tagging v1.3.0"* ]]
}

@test "integration: skipped VERSION logs the skip action" {
    run -0 "$SCRIPT_PATH" <<< $'\n\nn\n'
    [[ "$output" == *"→ Skipping VERSION; tagging HEAD directly"* ]]
}

@test "integration: tag points at the release commit" {
    run -0 "$SCRIPT_PATH" <<< $'\n\n'
    [[ "$(git rev-parse v1.3.0)" == "$(git rev-parse HEAD)" ]]
}

@test "integration: VERSION is committed in the release commit" {
    run -0 "$SCRIPT_PATH" <<< $'\n\n'
    [[ "$(git show HEAD:VERSION)" == "1.3.0" ]]
    [[ -z "$(git status --porcelain)" ]]
}
