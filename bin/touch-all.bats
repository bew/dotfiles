# Test suite for `touch-all` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $BATS_TEST_FILENAME [--filter topic]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/touch-all"

@test "defaults: no args does nothing" {
    run -0 "$SCRIPT_PATH"
    [[ "$output" == "" ]]
}

@test "cli: touches given file and prints message" {
    local file
    file="$BATS_TEST_TMPDIR/simple-file"

    run -0 "$SCRIPT_PATH" "$file"

    [[ -f "$file" ]]
    [[ "$output" == "touch-all: touched '$file'" ]]
}

@test "cli: creates parent directories" {
    local file dir
    file="$BATS_TEST_TMPDIR/subdir/nested/file.txt"
    dir="$(dirname "$file")"

    [[ ! -d "$dir" ]]

    run -0 "$SCRIPT_PATH" "$file"

    [[ -d "$dir" ]]
    [[ -f "$file" ]]
    [[ "$output" == *"touch-all: touched '$file'"* ]]
}

@test "cli: touches multiple files including nested paths" {
    local top_level nested deep
    top_level="$BATS_TEST_TMPDIR/top-level"
    nested="$BATS_TEST_TMPDIR/nested/file"
    deep="$BATS_TEST_TMPDIR/multiple/nesting/to/file"

    run -0 "$SCRIPT_PATH" "$top_level" "$nested" "$deep"

    [[ -f "$top_level" ]]
    [[ -f "$nested" ]]
    [[ -f "$deep" ]]

    # All three files reported as touched
    [[ "$output" == *"touch-all: touched '$top_level'"* ]]
    [[ "$output" == *"touch-all: touched '$nested'"* ]]
    [[ "$output" == *"touch-all: touched '$deep'"* ]]
}
