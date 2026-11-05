# Test suite for `mechanical-checks` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/mechanical-checks"
FIXTURES_DIR="$SCRIPT_DIR/test-fixtures"

# ------------------------------------------------------------------------------
# Tests: helpers

# Assert that the given haystack contains the needle.
function assert_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Expected output to contain: $needle"
        echo "Actual output:"
        echo "$haystack"
        return 1
    fi
}

# Assert that the given haystack does not contain the needle.
function assert_not_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "Expected output NOT to contain: $needle"
        echo "Actual output:"
        echo "$haystack"
        return 1
    fi
}

@test "helpers: assert_contains accepts matching text" {
    run assert_contains "hello world" "world"
    [[ "$status" -eq 0 ]]
}

@test "helpers: assert_contains rejects non-matching text" {
    run assert_contains "hello world" "nope"
    [[ "$status" -eq 1 ]]
}

@test "helpers: assert_not_contains accepts absent text" {
    run assert_not_contains "hello world" "nope"
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: errors with usage when --dir is missing" {
    run -1 --separate-stderr "$SCRIPT_PATH"
    assert_contains "$stderr" "Usage:"
    assert_contains "$stderr" "--dir"
}

@test "cli: accepts an explicit --readme path" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg" \
        --readme "$FIXTURES_DIR/cargo-pkg/README.md"
    assert_contains "$output" "README references"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: reports the Cargo package name" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_contains "$output" "Manifest: Cargo.toml"
    assert_contains "$output" "Name: demo-crate"
}

@test "defaults: reports the npm package name" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/npm-pkg"
    assert_contains "$output" "Manifest: package.json"
    assert_contains "$output" "Name: demo-npm"
}

@test "defaults: reports the pyproject package name" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/py-pkg"
    assert_contains "$output" "Manifest: pyproject.toml"
    assert_contains "$output" "Name: demo-py"
}

@test "defaults: counts source files by extension and excludes target" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_contains "$output" ".rs: 3"
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: exits 1 for a non-existent directory" {
    run -1 --separate-stderr "$SCRIPT_PATH" --dir "$BATS_TEST_TMPDIR/nope"
    assert_contains "$stderr" "not a directory"
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: reports a missing README path reference" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_contains "$output" '`missing.rs`'
}

@test "edge: does not report existing README path references" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_not_contains "$output" '`main.rs`'
    assert_not_contains "$output" 'docs/guide.md`'
}

@test "edge: flags an existing file referenced with a src/ prefix" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_contains "$output" '`src/lib.rs`'
}

@test "edge: skips URLs, commands, globs, and fenced code" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_not_contains "$output" "example.com"
    assert_not_contains "$output" "cargo build"
    assert_not_contains "$output" 'src/*.rs`'
    assert_not_contains "$output" "inside-fence.rs"
}

@test "edge: resolves bare filenames against src/" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_not_contains "$output" '`main.rs`'
    assert_not_contains "$output" '`lib.rs`'
}

@test "edge: skips slash identifiers with no file extension" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_not_contains "$output" "window/wayland"
}

@test "edge: exits 0 even when missing references exist" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/cargo-pkg"
    assert_contains "$output" "Missing references: 1"
}

@test "edge: reports an absent README without failing" {
    run -0 "$SCRIPT_PATH" --dir "$FIXTURES_DIR/npm-pkg"
    assert_contains "$output" "README not found"
}
