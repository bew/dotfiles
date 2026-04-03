# Test suite for `blank-lines` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $BATS_TEST_FILENAME [--filter topic]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/blank-lines"

@test "defaults: prints a single blank line" {
    run -0 --keep-empty-lines "$SCRIPT_PATH"
    [[ "$output" == $'\n' ]]
}

@test "cli: prints multiple blank lines" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" 3
    # 3 requested blank lines
    [[ "$output" == $'\n\n\n' ]]
}

@test "edge: negative number prints nothing" {
    run -0 "$SCRIPT_PATH" -2
    [[ "$output" == "" ]]
}

@test "error: rejects non-numeric argument" {
    run -1 --separate-stderr "$SCRIPT_PATH" foo
    [[ "$stderr" == *"not a valid number of lines"* ]]
}
