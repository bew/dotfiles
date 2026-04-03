# Test suite for `sep` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $BATS_TEST_FILENAME [--filter topic]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/sep"

@test "defaults: prints separator with surrounding blank lines" {
    run -0 --keep-empty-lines "$SCRIPT_PATH"
    # Leading blank line + separator line + trailing blank line, trailing newline trimmed by Bats
    [[ "$output" == $'\n<---------------------->\n\n' ]]
}

@test "cli: --compact omits blank lines" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" --compact
    [[ "$output" == $'<---------------------->\n' ]]
}
