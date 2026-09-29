# Test suite for `echolines` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $BATS_TEST_FILENAME [--filter topic]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/echolines"

@test "defaults: exits successfully with no args" {
    run -0 --keep-empty-lines "$SCRIPT_PATH"
    [[ "$output" == "" ]]
}

@test "cli: prints each argument on its own line" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" foo bar baz
    [[ "$output" == $'foo\nbar\nbaz\n' ]]
}

@test "cli: preserves empty-string arguments" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" "" aaa "" bbb ""
    [[ "$output" == $'\naaa\n\nbbb\n\n' ]]
}

@test "cli: -n prefixes each line with its 1-based line number" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" -n foo bar baz
    [[ "$output" == $'1: foo\n2: bar\n3: baz\n' ]]
}

@test "cli: -n numbers empty-string arguments too" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" -n "" aaa ""
    [[ "$output" == $'1: \n2: aaa\n3: \n' ]]
}

@test "cli: -n alone prints nothing" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" -n
    [[ "$output" == "" ]]
}

@test "edge: -n as a later argument is printed literally" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" a -n b
    [[ "$output" == $'a\n-n\nb\n' ]]
}
