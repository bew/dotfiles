# Test suite for `human-size` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $BATS_TEST_FILENAME [--filter topic]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/human-size"

@test "usage: requires exactly one argument" {
    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == "Usage: human-size [-]NUMBER_OF_BYTES" ]]
}

@test "defaults: formats bytes using numfmt" {
    local expected
    expected=$(numfmt --to=iec-i --format="%.1f" -- 1024 2>/dev/null || numfmt --to=iec-i -- 1024)

    run -0 "$SCRIPT_PATH" 1024

    [[ "$output" == "$expected" ]]
}

@test "cli: accepts negative numbers" {
    run -0 "$SCRIPT_PATH" -1024
    [[ -n "$output" ]]
}
