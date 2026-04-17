# Test suite for `diralias` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

# Require BATS 1.5.0+ for flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/diralias"

# Each test gets an isolated XDG_STATE_HOME so aliases never bleed across tests
function setup() {
    export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
}

# Helper: run the script, expect success (exit 0)
function run_script() {
    run -0 "$SCRIPT_PATH" "$@"
}

# Helper: run the script, expect failure (non-zero exit)
function run_script_failed() {
    run -1 "$SCRIPT_PATH" "$@"
}

# Helper: create a real temporary directory for use as an alias target
function make_target_dir() {
    local name="$1"
    local dir="$BATS_TEST_TMPDIR/$name"
    mkdir -p "$dir"
    echo "$dir"
}

# ------------------------------------------------------------------------------
# cli

@test "cli: no args shows usage on stderr and exits non-zero" {
    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"Usage: diralias"* ]]
}

@test "cli: --help prints usage and exits 0" {
    run -0 --separate-stderr "$SCRIPT_PATH" --help
    [[ "$stderr" == *"Usage: diralias"* ]]
}

@test "cli: -h prints usage and exits 0" {
    run -0 --separate-stderr "$SCRIPT_PATH" -h
    [[ "$stderr" == *"Usage: diralias"* ]]
}

@test "cli: help subcommand prints usage and exits 0" {
    run -0 --separate-stderr "$SCRIPT_PATH" help
    [[ "$stderr" == *"Usage: diralias"* ]]
}

@test "cli: unknown command exits non-zero with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" bogus-cmd
    [[ "$stderr" == *"Unknown command: bogus-cmd"* ]]
}

# ------------------------------------------------------------------------------
# add

@test "add: creates symlink for a valid directory" {
    local target
    target="$(make_target_dir mydir)"

    run_script add myalias "$target"
    [[ "$output" == *"Added alias 'myalias'"* ]]

    local state_dir="$BATS_TEST_TMPDIR/state/diralias/aliases"
    [[ -L "$state_dir/myalias" ]]
    [[ "$(readlink "$state_dir/myalias")" == "$target" ]]
}

@test "add: increments change-tick after adding alias" {
    local target
    target="$(make_target_dir tick-test)"

    local tick_file="$BATS_TEST_TMPDIR/state/diralias/change-tick"

    run_script add first "$target"
    [[ "$(cat "$tick_file")" == "1" ]]

    local target2
    target2="$(make_target_dir tick-test2)"
    run_script add second "$target2"
    [[ "$(cat "$tick_file")" == "2" ]]
}

@test "add: resolves relative paths to absolute" {
    local target
    target="$(make_target_dir reldir)"

    # Run add with a relative path by changing to BATS_TEST_TMPDIR first
    run -0 bash -c "cd '$BATS_TEST_TMPDIR' && '$SCRIPT_PATH' add reltest reldir"

    local link_target
    link_target="$(readlink "$BATS_TEST_TMPDIR/state/diralias/aliases/reltest")"
    # Must be an absolute path
    [[ "$link_target" == /* ]]
    [[ "$link_target" == "$target" ]]
}

@test "add: warns and overwrites an existing alias" {
    local target
    target="$(make_target_dir orig)"
    local target2
    target2="$(make_target_dir new)"

    run_script add mything "$target"

    run -0 --separate-stderr "$SCRIPT_PATH" add mything "$target2"
    [[ "$stderr" == *"Warning: Alias 'mything' already exists, overwriting"* ]]

    local link_target
    link_target="$(readlink "$BATS_TEST_TMPDIR/state/diralias/aliases/mything")"
    [[ "$link_target" == "$target2" ]]
}

@test "add: overwriting an alias still increments tick" {
    local target
    target="$(make_target_dir over)"
    local target2
    target2="$(make_target_dir over2)"

    run_script add samename "$target"
    run_script add samename "$target2"

    local tick
    tick="$(cat "$BATS_TEST_TMPDIR/state/diralias/change-tick")"
    [[ "$tick" == "2" ]]
}

# ------------------------------------------------------------------------------
# add/error

@test "add/error: missing both NAME and PATH" {
    run -1 --separate-stderr "$SCRIPT_PATH" add
    [[ "$stderr" == *"'add' requires NAME and PATH"* ]]
}

@test "add/error: missing PATH argument" {
    run -1 --separate-stderr "$SCRIPT_PATH" add myname
    [[ "$stderr" == *"'add' requires NAME and PATH"* ]]
}

@test "add/error: non-existent path" {
    run -1 --separate-stderr "$SCRIPT_PATH" add myalias /no/such/directory/ever
    [[ "$stderr" == *"not an existing directory"* ]]
}

@test "add/error: alias name with slash is rejected" {
    local target
    target="$(make_target_dir slash-test)"
    run -1 --separate-stderr "$SCRIPT_PATH" add "foo/bar" "$target"
    [[ "$stderr" == *"must not contain '/'"* ]]
}

@test "add/error: alias name with whitespace is rejected" {
    local target
    target="$(make_target_dir ws-test)"
    run -1 --separate-stderr "$SCRIPT_PATH" add "foo bar" "$target"
    [[ "$stderr" == *"must not contain whitespace"* ]]
}

@test "add/error: empty alias name is rejected" {
    local target
    target="$(make_target_dir empty-name-test)"
    run -1 --separate-stderr "$SCRIPT_PATH" add "" "$target"
    [[ "$stderr" == *"must not be empty"* ]]
}

# ------------------------------------------------------------------------------
# get

@test "get: returns alias name for a given path" {
    local target
    target="$(make_target_dir getdir)"

    run_script add gettest "$target"
    run_script get "$target"
    [[ "$output" == "gettest" ]]
}

@test "get: returns alias name for current directory (no arg)" {
    local target
    target="$(make_target_dir cwddir)"

    run_script add cwdalias "$target"

    # Run get from within the target directory
    run -0 bash -c "cd '$target' && '$SCRIPT_PATH' get"
    [[ "$output" == "cwdalias" ]]
}

@test "get: returns correct alias when multiple aliases exist" {
    local target1 target2
    target1="$(make_target_dir multi1)"
    target2="$(make_target_dir multi2)"

    run_script add alias1 "$target1"
    run_script add alias2 "$target2"

    run_script get "$target1"
    [[ "$output" == "alias1" ]]

    run_script get "$target2"
    [[ "$output" == "alias2" ]]
}

@test "get: returns alias and remainder for path inside aliased directory" {
    local target
    target="$(make_target_dir base)"

    run_script add mybase "$target"
    run_script get "$target/something/else"
    [[ "$output" == "mybase something/else" ]]
}

@test "get: remainder works with single-level subdirectory" {
    local target
    target="$(make_target_dir single)"

    run_script add root "$target"
    run_script get "$target/child"
    [[ "$output" == "root child" ]]
}

@test "get: returns most specific alias for nested path when aliases overlap" {
    local base child
    base="$(make_target_dir overlap-base)"
    child="$base/sub"
    mkdir -p "$child"

    run_script add base "$base"
    run_script add sub "$child"

    # Path inside child — should match the more specific alias
    run_script get "$child/deep/path"
    [[ "$output" == "sub deep/path" ]]

    # Path directly under base but not under child — should match base
    run_script get "$base/other"
    [[ "$output" == "base other" ]]
}

@test "get: exact match takes priority over prefix match" {
    local target
    target="$(make_target_dir exact)"

    run_script add exact "$target"
    run_script get "$target"
    [[ "$output" == "exact" ]]
}

@test "get: get with PWD inside aliased directory returns alias and remainder" {
    local target
    target="$(make_target_dir cwdpre)"
    local subdir="$target/a/b"
    mkdir -p "$subdir"

    run_script add cwdbase "$target"

    run -0 bash -c "cd '$subdir' && '$SCRIPT_PATH' get"
    [[ "$output" == "cwdbase a/b" ]]
}

# ------------------------------------------------------------------------------
# get/error

@test "get/error: exits non-zero and prints error when no alias found" {
    local target
    target="$(make_target_dir nope)"

    run -1 --separate-stderr "$SCRIPT_PATH" get "$target"
    [[ "$stderr" == *"No alias found for path"* ]]
    [[ "$stderr" == *"$target"* ]]
}

@test "get/error: exits non-zero for unknown path even with other aliases defined" {
    local target other
    target="$(make_target_dir known)"
    other="$(make_target_dir unknown)"

    run_script add known "$target"

    run -1 --separate-stderr "$SCRIPT_PATH" get "$other"
    [[ "$stderr" == *"No alias found for path"* ]]
}

# ------------------------------------------------------------------------------
# status

@test "status: shows change-tick and no aliases when empty" {
    run_script status
    [[ "$output" == *"change-tick: 0"* ]]
    [[ "$output" == *"(no aliases defined)"* ]]
}

@test "status: shows all aliases after adding them" {
    local target1 target2
    target1="$(make_target_dir s1)"
    target2="$(make_target_dir s2)"

    run_script add alpha "$target1"
    run_script add beta "$target2"

    run_script status
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"$target1"* ]]
    [[ "$output" == *"beta"* ]]
    [[ "$output" == *"$target2"* ]]
}

@test "status: shows updated change-tick after adds" {
    local target
    target="$(make_target_dir tick)"

    run_script add one "$target"
    run_script add two "$(make_target_dir tick2)"

    run_script status
    [[ "$output" == *"change-tick: 2"* ]]
}

@test "status: aliases are listed in alphabetical order" {
    run_script add zebra "$(make_target_dir z)"
    run_script add apple "$(make_target_dir a)"
    run_script add mango "$(make_target_dir m)"

    run_script status
    # Extract alias names from output lines (lines containing " -> ")
    local alias_names
    alias_names=$(echo "$output" | grep " -> " | awk '{print $1}' | tr -d ' ')
    local first second third
    first=$(echo "$alias_names" | sed -n '1p')
    second=$(echo "$alias_names" | sed -n '2p')
    third=$(echo "$alias_names" | sed -n '3p')

    [[ "$first" == "apple" ]]
    [[ "$second" == "mango" ]]
    [[ "$third" == "zebra" ]]
}

# ------------------------------------------------------------------------------
# tick-file

@test "tick-file: prints the path to the change-tick file" {
    local expected_tick_file="$BATS_TEST_TMPDIR/state/diralias/change-tick"
    run_script tick-file
    [[ "$output" == "$expected_tick_file" ]]
}

@test "tick-file: creates storage on first use" {
    local state_dir="$BATS_TEST_TMPDIR/state/diralias"
    [[ ! -d "$state_dir" ]]

    run_script tick-file
    [[ -f "$BATS_TEST_TMPDIR/state/diralias/change-tick" ]]
}

@test "tick-file: printed path is the actual file that holds the tick value" {
    run_script add one "$(make_target_dir tf1)"
    run_script add two "$(make_target_dir tf2)"

    run_script tick-file
    local tick_path="$output"

    [[ "$(cat "$tick_path")" == "2" ]]
}

# ------------------------------------------------------------------------------
# edge

@test "edge: storage directories are created automatically on first use" {
    local state_dir="$BATS_TEST_TMPDIR/state/diralias"
    [[ ! -d "$state_dir" ]]

    run_script status
    [[ -d "$state_dir/aliases" ]]
    [[ -f "$state_dir/change-tick" ]]
}

@test "edge: tick file initializes to 0" {
    run_script status
    local tick
    tick="$(cat "$BATS_TEST_TMPDIR/state/diralias/change-tick")"
    [[ "$tick" == "0" ]]
}

@test "edge: path with spaces is handled correctly" {
    local target
    target="$(make_target_dir "dir with spaces")"

    run_script add spacey "$target"
    run_script get "$target"
    [[ "$output" == "spacey" ]]
}
