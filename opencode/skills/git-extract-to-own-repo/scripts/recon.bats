# Test suite for `recon` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/recon"

# Shared setup.
function setup() {
    # Ambient GIT_* vars would override `git -C` and leak the caller's repo into fixtures.
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
        GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
}

# Create a git repo at $1 with local identity so commits work in a clean environment.
function setup_repo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q -b main
    git -C "$repo" config user.name "Recon Test"
    git -C "$repo" config user.email "recon-test@example.com"
    git -C "$repo" config commit.gpgsign false
    git -C "$repo" config diff.renames true
}

# Stage all changes in repo $1 and commit them with message $2.
function commit_all() {
    local repo="$1"
    local msg="$2"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "$msg"
}

# Assert the captured stdout contains the literal string $1.
function assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        printf 'stdout did not contain: %s\n--- stdout ---\n%s\n' "$expected" "$output" >&2
        return 1
    fi
}

# Assert the captured stdout does NOT contain the literal string $1.
function assert_output_lacks() {
    local unexpected="$1"
    if [[ "$output" == *"$unexpected"* ]]; then
        printf 'stdout unexpectedly contained: %s\n--- stdout ---\n%s\n' "$unexpected" "$output" >&2
        return 1
    fi
}

# Assert that at least one captured stdout line matches the glob pattern $1.
function assert_output_line_matches() {
    local pattern="$1"
    local line
    while IFS= read -r line; do
        # Pattern is intentionally unquoted so [[ ]] treats it as a glob.
        if [[ "$line" == $pattern ]]; then
            return 0
        fi
    done <<< "$output"
    printf 'no stdout line matched: %s\n--- stdout ---\n%s\n' "$pattern" "$output" >&2
    return 1
}

# Assert the captured stderr contains the literal string $1.
function assert_stderr_contains() {
    local expected="$1"
    if [[ "$stderr" != *"$expected"* ]]; then
        printf 'stderr did not contain: %s\n--- stderr ---\n%s\n' "$expected" "$stderr" >&2
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Tests: helpers

@test "helpers: assert_output_contains passes on match" {
    output="the quiet brown fox"
    assert_output_contains "brown"
}

@test "helpers: assert_output_contains fails on miss" {
    output="the quiet brown fox"
    ! assert_output_contains "loud"
}

@test "helpers: assert_output_lacks passes when absent" {
    output="the quiet brown fox"
    assert_output_lacks "loud"
}

@test "helpers: assert_output_line_matches passes on glob match" {
    output=$'noise\n  earliest commit:        123abcd first-touch\nmore noise'
    assert_output_line_matches "  earliest commit:        *first-touch"
}

@test "helpers: assert_output_line_matches fails when no line matches" {
    output="  earliest commit:        123abcd second-touch"
    ! assert_output_line_matches "  earliest commit:        *first-touch"
}

@test "helpers: assert_stderr_contains passes on match" {
    stderr="!! ERROR: boom"
    assert_stderr_contains "ERROR"
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: no arguments prints usage to stderr and exits 1" {
    run -1 --separate-stderr bash "$SCRIPT_PATH"
    assert_stderr_contains "Usage: recon SOURCE_ROOT PATH..."
}

@test "usage: single argument (missing PATH) prints usage and exits 1" {
    run -1 --separate-stderr bash "$SCRIPT_PATH" "$BATS_TEST_TMPDIR"
    assert_stderr_contains "Usage: recon SOURCE_ROOT PATH..."
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: non-directory SOURCE_ROOT reports error on stderr and exits 1" {
    local missing="$BATS_TEST_TMPDIR/does-not-exist"
    run -1 --separate-stderr bash "$SCRIPT_PATH" "$missing" "pkg"
    assert_stderr_contains "!! ERROR:"
    assert_stderr_contains "is not a directory"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: reports repo state for a git repo" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/pkg"
    printf 'one\n' > "$repo/pkg/a.nix"
    commit_all "$repo" "c1"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "== Repo state =="
    assert_output_contains "git-dir:    .git"
    assert_output_contains "common-dir: .git"
    assert_output_contains "branch:     main"
    assert_output_contains "dirty files: 0"
}

@test "defaults: reports tracked files and count for a part" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/pkg/sub"
    printf 'one\n' > "$repo/pkg/a.nix"
    printf 'two\n' > "$repo/pkg/sub/b.nix"
    printf 'top\n' > "$repo/top.txt"
    commit_all "$repo" "c1"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "  tracked files:"
    assert_output_contains "    pkg/a.nix"
    assert_output_contains "    pkg/sub/b.nix"
    assert_output_contains "  count: 2"
    assert_output_lacks "    top.txt"
}

@test "defaults: reports current-branch and all-branch commit counts" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/pkg"
    printf 'one\n' > "$repo/pkg/main.txt"
    commit_all "$repo" "c1"
    printf 'two\n' > "$repo/pkg/main.txt"
    commit_all "$repo" "c2"
    printf 'other\n' > "$repo/other.txt"
    commit_all "$repo" "c3"
    git -C "$repo" checkout -q -b feature
    printf 'feat\n' > "$repo/pkg/feat.txt"
    commit_all "$repo" "c4"
    git -C "$repo" checkout -q main

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "  current-branch commits: 2"
    assert_output_contains "  all-branch commits:     3"
}

@test "defaults: reports earliest commit for the part" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/pkg"
    printf 'one\n' > "$repo/pkg/a.txt"
    commit_all "$repo" "first-touch"
    printf 'two\n' > "$repo/pkg/a.txt"
    commit_all "$repo" "second-touch"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_line_matches "  earliest commit:        *first-touch"
    ! assert_output_line_matches "  earliest commit:        *second-touch"
}

@test "defaults: reports consumer references and lockfile hits" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/pkg"
    printf 'payload\n' > "$repo/pkg/thing.txt"
    printf 'see pkg/thing.txt\n' > "$repo/README.md"
    printf '{"owner":"pkg"}\n' > "$repo/flake.lock"
    commit_all "$repo" "c1"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "  references to 'pkg':"
    assert_output_contains "README.md"
    assert_output_contains "  lockfile hit: flake.lock"
}

@test "defaults: reports a rename within the part" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/pkg"
    printf 'same content\n' > "$repo/pkg/old.txt"
    commit_all "$repo" "c1"
    git -C "$repo" mv pkg/old.txt pkg/new.txt
    git -C "$repo" commit -q -m "c2"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "  renames:"
    assert_output_contains "R100	pkg/old.txt	pkg/new.txt"
}

@test "defaults: reports history under a prior unrelated location" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/vendor/pkgstuff" "$repo/pkg"
    printf 'thing\n' > "$repo/vendor/pkgstuff/thing.txt"
    commit_all "$repo" "c1"
    git -C "$repo" mv vendor/pkgstuff/thing.txt pkg/thing.txt
    git -C "$repo" commit -q -m "c2"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "  history under other paths matching '*pkg*':"
    assert_output_contains "vendor/pkgstuff/thing.txt"
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: non-git directory is handled gracefully" {
    local plain="$BATS_TEST_TMPDIR/plain"
    mkdir -p "$plain"
    printf 'loose\n' > "$plain/loose.txt"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$plain" pkg

    assert_output_contains "== Repo state =="
    assert_output_contains "dirty files: 0"
    assert_output_contains "(no tracked files under 'pkg')"
    assert_output_contains "  current-branch commits: 0"
    assert_output_contains "  earliest commit:        (none)"
}

@test "edge: dirty working tree counts modified files" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    mkdir -p "$repo/pkg"
    printf 'one\n' > "$repo/pkg/a.txt"
    commit_all "$repo" "c1"
    printf 'changed\n' > "$repo/pkg/a.txt"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "dirty files: 1"
}

@test "edge: part with no tracked files prints a notice" {
    local repo="$BATS_TEST_TMPDIR/repo"
    setup_repo "$repo"
    printf 'other\n' > "$repo/other.txt"
    commit_all "$repo" "c1"
    mkdir -p "$repo/pkg"
    printf 'untracked\n' > "$repo/pkg/untracked.txt"

    run -0 --keep-empty-lines --separate-stderr bash "$SCRIPT_PATH" "$repo" pkg

    assert_output_contains "(no tracked files under 'pkg')"
}