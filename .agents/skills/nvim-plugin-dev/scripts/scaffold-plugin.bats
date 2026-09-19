# Test suite for `scaffold-plugin` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/scaffold-plugin"

# Strip the plugins-root env var so tests never inherit the caller's value.
function setup_file() {
    unset NVIM_BEW_MYPLUGINS_PATH
}

# Assert two files have identical content; print a unified diff on mismatch.
function assert_files_match() {
    local expected_path="$1"
    local actual_path="$2"

    if ! diff -u "$expected_path" "$actual_path"; then
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Tests: helpers

@test "helpers: assert_files_match compares file contents" {
    local expected="$BATS_TEST_TMPDIR/expected"
    local actual="$BATS_TEST_TMPDIR/actual"
    printf 'same\n' >"$expected"
    printf 'same\n' >"$actual"
    assert_files_match "$expected" "$actual"

    printf 'different\n' >"$actual"
    run assert_files_match "$expected" "$actual"
    [[ "$status" -ne 0 ]]
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: creates the full expected tree" {
    local root="$BATS_TEST_TMPDIR/root"

    run -0 "$SCRIPT_PATH" -d "$root" my-thing

    [[ -d "$root/my-thing.nvim" ]]
    [[ -d "$root/my-thing.nvim/lua" ]]
    [[ -f "$root/my-thing.nvim/lua/my-thing.lua" ]]
    [[ -f "$root/my-thing.nvim/stylua.toml" ]]
    [[ -d "$root/my-thing.nvim/tests" ]]
}

@test "defaults: lua module stub has exact content" {
    local root="$BATS_TEST_TMPDIR/root"

    run -0 "$SCRIPT_PATH" -d "$root" my-thing

    local expected="$BATS_TEST_TMPDIR/expected.lua"
    cat >"$expected" <<'EOF'
local M = {}

return M
EOF
    assert_files_match "$expected" "$root/my-thing.nvim/lua/my-thing.lua"
}

@test "defaults: stylua.toml has exact content" {
    local root="$BATS_TEST_TMPDIR/root"

    run -0 "$SCRIPT_PATH" -d "$root" my-thing

    local expected="$BATS_TEST_TMPDIR/expected.toml"
    cat >"$expected" <<'EOF'
# (NOTE: The file is used to find root of a Lua project, to avoid loading too much)
# Reference: https://github.com/JohnnyMorganz/StyLua
indent_type = "Spaces"
indent_width = 2
call_parentheses = "Input"
EOF
    assert_files_match "$expected" "$root/my-thing.nvim/stylua.toml"
}

@test "defaults: tests directory is empty" {
    local root="$BATS_TEST_TMPDIR/root"

    run -0 "$SCRIPT_PATH" -d "$root" my-thing

    [[ -d "$root/my-thing.nvim/tests" ]]
    [[ -z "$(ls -A "$root/my-thing.nvim/tests")" ]]
}

@test "defaults: reports created path on stdout" {
    local root="$BATS_TEST_TMPDIR/root"

    run -0 "$SCRIPT_PATH" -d "$root" my-thing

    [[ "$output" == *"$root/my-thing.nvim"* ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: falls back to NVIM_BEW_MYPLUGINS_PATH" {
    local root="$BATS_TEST_TMPDIR/root"

    NVIM_BEW_MYPLUGINS_PATH="$root" run -0 "$SCRIPT_PATH" my-thing

    [[ -f "$root/my-thing.nvim/lua/my-thing.lua" ]]
}

@test "cli: -d overrides NVIM_BEW_MYPLUGINS_PATH" {
    local env_root="$BATS_TEST_TMPDIR/env-root"
    local flag_root="$BATS_TEST_TMPDIR/flag-root"

    NVIM_BEW_MYPLUGINS_PATH="$env_root" run -0 "$SCRIPT_PATH" -d "$flag_root" my-thing

    [[ -f "$flag_root/my-thing.nvim/lua/my-thing.lua" ]]
    [[ ! -e "$env_root/my-thing.nvim" ]]
}

@test "cli: accepts name after flags" {
    local root="$BATS_TEST_TMPDIR/root"

    run -0 "$SCRIPT_PATH" -d "$root" my-thing

    [[ -f "$root/my-thing.nvim/stylua.toml" ]]
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: --help exits 0 and prints usage" {
    run -0 "$SCRIPT_PATH" --help

    [[ "$output" == *"Usage:"* ]]
}

@test "usage: -h exits 0" {
    run -0 "$SCRIPT_PATH" -h

    [[ "$output" == *"Usage:"* ]]
}

@test "usage: no arguments exits 1 with usage" {
    run -1 --separate-stderr "$SCRIPT_PATH"

    [[ "$stderr" == *"Usage:"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: existing target is refused" {
    local root="$BATS_TEST_TMPDIR/root"
    mkdir -p "$root/my-thing.nvim"

    run -1 --separate-stderr "$SCRIPT_PATH" -d "$root" my-thing

    [[ "$stderr" == *"$root/my-thing.nvim"* ]]
    [[ "$stderr" == *"already exists"* ]]
}

@test "error: existing target is not overwritten" {
    local root="$BATS_TEST_TMPDIR/root"
    mkdir -p "$root/my-thing.nvim"
    printf 'keep me\n' >"$root/my-thing.nvim/sentinel"

    run -1 --separate-stderr "$SCRIPT_PATH" -d "$root" my-thing

    [[ -f "$root/my-thing.nvim/sentinel" ]]
    [[ ! -e "$root/my-thing.nvim/lua" ]]
}

@test "error: missing plugins root is refused" {
    run -1 --separate-stderr "$SCRIPT_PATH" my-thing

    [[ "$stderr" == *"NVIM_BEW_MYPLUGINS_PATH"* ]]
}

@test "error: empty name exits with usage" {
    run -1 --separate-stderr "$SCRIPT_PATH" -d "$BATS_TEST_TMPDIR/root" ""

    [[ "$stderr" == *"Usage:"* ]]
}

@test "error: name containing slash is refused" {
    run -1 --separate-stderr "$SCRIPT_PATH" -d "$BATS_TEST_TMPDIR/root" "a/b"

    [[ "$stderr" == *"invalid plugin name"* ]]
}

@test "error: name containing space is refused" {
    run -1 --separate-stderr "$SCRIPT_PATH" -d "$BATS_TEST_TMPDIR/root" "a b"

    [[ "$stderr" == *"invalid plugin name"* ]]
}

@test "error: bare .nvim name exits with usage" {
    run -1 --separate-stderr "$SCRIPT_PATH" -d "$BATS_TEST_TMPDIR/root" ".nvim"

    [[ "$stderr" == *"Usage:"* ]]
    [[ ! -e "$BATS_TEST_TMPDIR/root/.nvim.nvim" ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: trailing .nvim suffix is stripped, no double suffix" {
    local root="$BATS_TEST_TMPDIR/root"

    run -0 "$SCRIPT_PATH" -d "$root" my-thing.nvim

    [[ -f "$root/my-thing.nvim/lua/my-thing.lua" ]]
    [[ -f "$root/my-thing.nvim/stylua.toml" ]]
    [[ -d "$root/my-thing.nvim/tests" ]]
    [[ ! -e "$root/my-thing.nvim.nvim" ]]
}
