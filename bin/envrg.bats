#!/usr/bin/env bash

# Test suite for `envrg` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for flag support on `run`

bats_require_minimum_version 1.5.0

# Get the directory where this test file is located
SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/envrg"

# Runs once before all tests
function setup_file() {
    # Unset all environment variables except PATH, HOME, and BATS_* variables
    for var in $(compgen -e); do
        case "$var" in
            PATH|HOME|BATS_*|SCRIPT_PATH)
                # Keep these variables
                ;;
            *)
                unset "$var"
                ;;
        esac
    done
}

function setup() {
    # Disable colors by default for most tests
    # Individual tests can override by unsetting NO_COLOR
    export NO_COLOR=1
}

@test "usage: shows usage when no arguments provided" {
    run -1 "$SCRIPT_PATH"
    [[ "$output" =~ "Usage:" ]]
}

@test "matching: matches variable names containing pattern" {
    export PATH_RELATED="some path value"
    export MY_PATH="/usr/bin"

    run -0 "$SCRIPT_PATH" PATH
    [[ "$output" =~ "PATH_RELATED=some path value" ]]
    [[ "$output" =~ "MY_PATH=/usr/bin" ]]
}

@test "matching: does not match pattern in values, only in names" {
    export TEST_VAR_ONE="contains_PATH_in_value"
    export PATH_RELATED="some path value"

    run -0 "$SCRIPT_PATH" PATH
    # Should NOT match TEST_VAR_ONE even though its value contains "PATH"
    [[ ! "$output" =~ "TEST_VAR_ONE=" ]]
    [[ "$output" =~ "PATH_RELATED=" ]]
}

@test "smart-case: lowercase pattern is case-insensitive" {
    export DB_HOST="localhost"
    export db_user="admin"

    run -0 "$SCRIPT_PATH" db
    [[ "$output" =~ "DB_HOST=" ]]
    [[ "$output" =~ "db_user=" ]]
}

@test "smart-case: uppercase pattern is case-sensitive" {
    export DB_HOST="localhost"
    export db_user="admin"

    run -0 "$SCRIPT_PATH" DB
    [[ "$output" =~ "DB_HOST=" ]]
    # Should NOT match lowercase db_user because pattern has uppercase
    [[ ! "$output" =~ "db_user=" ]]
}

@test "flags: -s enables explicit case-sensitive search" {
    export DB_HOST="localhost"
    export db_user="admin"

    run -0 "$SCRIPT_PATH" -s db
    [[ "$output" =~ "db_user=" ]]
    # Should NOT match uppercase DB_HOST
    [[ ! "$output" =~ "DB_HOST=" ]]
}

@test "matching: matches FOO in HELLO_FOO_STUFF" {
    export HELLO_FOO_STUFF="test value"

    run -0 "$SCRIPT_PATH" foo
    [[ "$output" =~ "HELLO_FOO_STUFF=" ]]
}

@test "regex: supports regex patterns" {
    export API_KEY="secret123"
    export API_TOKEN="token456"
    export NOT_API="other"

    run -0 "$SCRIPT_PATH" ^api_
    [[ "$output" =~ "API_KEY=" ]]
    [[ "$output" =~ "API_TOKEN=" ]]
    [[ ! "$output" =~ "NOT_API=" ]]
}

@test "regex: matches complete variable names with anchors" {
    export PATH_RELATED="some path value"
    export MY_PATH="/usr/bin"

    run -0 "$SCRIPT_PATH" ^PATH$
    # Should match PATH exactly
    [[ "$output" =~ ^PATH= ]]
    # Should NOT match PATH_RELATED or MY_PATH
    [[ ! "$output" =~ "PATH_RELATED=" ]]
    [[ ! "$output" =~ "MY_PATH=" ]]
}

@test "flags: -v inverts match" {
    export TEST_VAR_ONE="value1"
    export TEST_VAR_TWO="value2"
    export DATABASE_URL="postgres://localhost"
    export API_KEY="secret"

    run -0 "$SCRIPT_PATH" -v TEST
    # Should NOT contain TEST_VAR_ONE or TEST_VAR_TWO
    [[ ! "$output" =~ "TEST_VAR_ONE=" ]]
    [[ ! "$output" =~ "TEST_VAR_TWO=" ]]
    # Should contain other variables
    [[ "$output" =~ "DATABASE_URL=" ]]
    [[ "$output" =~ "API_KEY=" ]]
}

@test "output: uses standard env format" {
    export MY_PATH="/usr/bin"

    run -0 "$SCRIPT_PATH" MY_PATH
    [[ "$output" == "MY_PATH=/usr/bin" ]]
}

@test "edge: handles variables with equals signs in values" {
    export COMPLEX_VAR="key=value&foo=bar"

    run -0 "$SCRIPT_PATH" COMPLEX_VAR
    [[ "$output" == "COMPLEX_VAR=key=value&foo=bar" ]]
}

@test "edge: preserves multiple equals signs in values" {
    export CONNECTION_STRING="server=localhost;user=admin;password=p@ss=word;port=5432"

    run -0 "$SCRIPT_PATH" CONNECTION_STRING
    [[ "$output" == "CONNECTION_STRING=server=localhost;user=admin;password=p@ss=word;port=5432" ]]
}

@test "edge: does not match pattern in value with equals signs" {
    export MY_CONFIG="path=/usr/bin/app"
    export MY_PATH="/usr/local"

    run -0 "$SCRIPT_PATH" ^MY_PATH$
    # Should only match MY_PATH, not MY_CONFIG (even though value contains "path=")
    [[ "$output" == "MY_PATH=/usr/local" ]]
    [[ ! "$output" =~ "MY_CONFIG" ]]
}

@test "edge: handles empty variable values" {
    export EMPTY_VAR=""

    run -0 "$SCRIPT_PATH" EMPTY_VAR
    [[ "$output" == "EMPTY_VAR=" ]]
}

@test "isolation: only shows variables from current environment" {
    export ONLY_THIS="should appear"

    run -0 "$SCRIPT_PATH" .
    # Should contain our test variable
    [[ "$output" =~ "ONLY_THIS=" ]]
    # Should also contain PATH and HOME (essentials kept in setup)
    [[ "$output" =~ "PATH=" ]]
    [[ "$output" =~ "HOME=" ]]
    # Should NOT contain random system variables that were unset
    [[ ! "$output" =~ "TERM=" ]]
    [[ ! "$output" =~ "SHELL=" ]]
}

@test "color: --color=never disables colors" {
    export MY_VAR="value"

    run -0 "$SCRIPT_PATH" --color=never MY_VAR
    # Output should not contain ANSI escape codes
    [[ ! "$output" =~ $'\e' ]]
    [[ "$output" == "MY_VAR=value" ]]
}

@test "color: NO_COLOR environment variable disables colors" {
    export MY_VAR="value"
    export NO_COLOR=1

    run -0 "$SCRIPT_PATH" MY_VAR
    # Output should not contain ANSI escape codes
    [[ ! "$output" =~ $'\e' ]]
    [[ "$output" == "MY_VAR=value" ]]
}

@test "color: --color=always enables colors" {
    export MY_VAR="value"
    unset NO_COLOR

    run -0 "$SCRIPT_PATH" --color=always MY_VAR
    # Output should contain ANSI escape codes (bold and dim)
    [[ "$output" =~ $'\e[1m' ]]  # Bold
    [[ "$output" =~ $'\e[2m' ]]  # Dim
    [[ "$output" =~ "MY_VAR" ]]
    [[ "$output" =~ "value" ]]
}

@test "stdin: supports reading from stdin with - argument" {
    export API_KEY="secret"
    export API_TOKEN="token"

    # First get all API vars, then filter by KEY
    run -0 bats_pipe "$SCRIPT_PATH" api \| "$SCRIPT_PATH" - key
    [[ "$output" == "API_KEY=secret" ]]
}

@test "stdin: can chain multiple filters" {
    export TEST_FOO="value1"
    export TEST_BAR="value2"
    export PROD_FOO="value3"
    export PROD_BAR="value4"

    # Filter on PROD, then remove FOO
    run -0 bats_pipe "$SCRIPT_PATH" prod \| "$SCRIPT_PATH" - -v FOO
    [[ "$output" == "PROD_BAR=value4" ]]
}

@test "error: requires pattern after - argument" {
    run -1 bats_pipe echo TEST=value \| "$SCRIPT_PATH" -
    [[ "$output" =~ "Usage:" ]]
}
