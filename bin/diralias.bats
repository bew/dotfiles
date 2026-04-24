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

# Each test gets an isolated HOME & XDG_STATE_HOME so aliases never bleed across tests
function setup() {
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"

    export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
}

# Helper: create a real temporary directory for use as an alias target
function make_target_dir() {
    local name="$1"
    local dir="$BATS_TEST_TMPDIR/targets/$name"
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

    run -0 "$SCRIPT_PATH" add myalias "$target"
    [[ "$output" == *"Added alias 'myalias'"* ]]

    local state_dir="$BATS_TEST_TMPDIR/state/diralias/aliases"
    [[ -L "$state_dir/myalias" ]]
    [[ "$(readlink "$state_dir/myalias")" == "$target" ]]
}

@test "add: increments change-tick after adding alias" {
    local target
    target="$(make_target_dir tick-test)"

    local tick_file="$BATS_TEST_TMPDIR/state/diralias/change-tick"

    run -0 "$SCRIPT_PATH" add first "$target"
    [[ "$(cat "$tick_file")" == "1" ]]

    local target2
    target2="$(make_target_dir tick-test2)"
    run -0 "$SCRIPT_PATH" add second "$target2"
    [[ "$(cat "$tick_file")" == "2" ]]
}

@test "add: resolves relative paths to absolute" {
    local target
    target="$(make_target_dir reldir)"

    # Run add with a relative path by changing to BATS_TEST_TMPDIR first
    run -0 bash -c "cd '$BATS_TEST_TMPDIR/targets/' && '$SCRIPT_PATH' add reltest reldir"

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

    run -0 "$SCRIPT_PATH" add mything "$target"

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

    run -0 "$SCRIPT_PATH" add samename "$target"
    run -0 "$SCRIPT_PATH" add samename "$target2"

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

    run -0 "$SCRIPT_PATH" add gettest "$target"
    run -0 "$SCRIPT_PATH" get "$target"
    [[ "$output" == "gettest" ]]
}

@test "get: returns alias name for current directory (no arg)" {
    local target
    target="$(make_target_dir cwddir)"

    run -0 "$SCRIPT_PATH" add cwdalias "$target"

    # Run get from within the target directory
    run -0 bash -c "cd '$target' && '$SCRIPT_PATH' get"
    [[ "$output" == "cwdalias" ]]
}

@test "get: returns correct alias when multiple aliases exist" {
    local target1 target2
    target1="$(make_target_dir multi1)"
    target2="$(make_target_dir multi2)"

    run -0 "$SCRIPT_PATH" add alias1 "$target1"
    run -0 "$SCRIPT_PATH" add alias2 "$target2"

    run -0 "$SCRIPT_PATH" get "$target1"
    [[ "$output" == "alias1" ]]

    run -0 "$SCRIPT_PATH" get "$target2"
    [[ "$output" == "alias2" ]]
}

@test "get: returns alias and remainder for path inside aliased directory" {
    local target
    target="$(make_target_dir base)"

    run -0 "$SCRIPT_PATH" add mybase "$target"
    run -0 "$SCRIPT_PATH" get "$target/something/else"
    [[ "$output" == "mybase something/else" ]]
}

@test "get: remainder works with single-level subdirectory" {
    local target
    target="$(make_target_dir single)"

    run -0 "$SCRIPT_PATH" add root "$target"
    run -0 "$SCRIPT_PATH" get "$target/child"
    [[ "$output" == "root child" ]]
}

@test "get: returns most specific alias for nested path when aliases overlap" {
    local base child
    base="$(make_target_dir overlap-base)"
    child="$base/sub"
    mkdir -p "$child"

    run -0 "$SCRIPT_PATH" add base "$base"
    run -0 "$SCRIPT_PATH" add sub "$child"

    # Path inside child — should match the more specific alias
    run -0 "$SCRIPT_PATH" get "$child/deep/path"
    [[ "$output" == "sub deep/path" ]]

    # Path directly under base but not under child — should match base
    run -0 "$SCRIPT_PATH" get "$base/other"
    [[ "$output" == "base other" ]]
}

@test "get: exact match takes priority over prefix match" {
    local target
    target="$(make_target_dir exact)"

    run -0 "$SCRIPT_PATH" add exact "$target"
    run -0 "$SCRIPT_PATH" get "$target"
    [[ "$output" == "exact" ]]
}

@test "get: get with PWD inside aliased directory returns alias and remainder" {
    local target
    target="$(make_target_dir cwdpre)"
    local subdir="$target/a/b"
    mkdir -p "$subdir"

    run -0 "$SCRIPT_PATH" add cwdbase "$target"

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

    run -0 "$SCRIPT_PATH" add known "$target"

    run -1 --separate-stderr "$SCRIPT_PATH" get "$other"
    [[ "$stderr" == *"No alias found for path"* ]]
}

# ------------------------------------------------------------------------------
# status

@test "status: shows change-tick and no aliases when empty" {
    run -0 "$SCRIPT_PATH" status
    [[ "$output" == *"change-tick: 0"* ]]
    [[ "$output" == *"(no aliases defined)"* ]]
}

@test "status: shows all aliases after adding them" {
    local target1 target2
    target1="$(make_target_dir s1)"
    target2="$(make_target_dir s2)"

    run -0 "$SCRIPT_PATH" add alpha "$target1"
    run -0 "$SCRIPT_PATH" add beta "$target2"

    run -0 "$SCRIPT_PATH" status
    [[ "$output" == *"alpha"* ]]
    [[ "$output" == *"$target1"* ]]
    [[ "$output" == *"beta"* ]]
    [[ "$output" == *"$target2"* ]]
}

@test "status: shows updated change-tick after adds" {
    local target
    target="$(make_target_dir tick)"

    run -0 "$SCRIPT_PATH" add one "$target"
    run -0 "$SCRIPT_PATH" add two "$(make_target_dir tick2)"

    run -0 "$SCRIPT_PATH" status
    [[ "$output" == *"change-tick: 2"* ]]
}

@test "status: aliases are listed in alphabetical order" {
    run -0 "$SCRIPT_PATH" add zebra "$(make_target_dir z)"
    run -0 "$SCRIPT_PATH" add apple "$(make_target_dir a)"
    run -0 "$SCRIPT_PATH" add mango "$(make_target_dir m)"

    run -0 "$SCRIPT_PATH" status
    # Extract alias names from output lines (lines containing " -> ")
    local alias_names
    alias_names=$(echo "$output" | grep " -> " | awk '{print $2}')
    local first second third
    first=$(echo "$alias_names" | sed -n '1p')
    second=$(echo "$alias_names" | sed -n '2p')
    third=$(echo "$alias_names" | sed -n '3p')

    [[ "$first" == "apple" ]]
    [[ "$second" == "mango" ]]
    [[ "$third" == "zebra" ]]
}

@test "status: displays paths under HOME with ~ prefix" {
    # note: HOME is a custom dir in test tmp path!
    echo "HOME is at '$HOME'"
    # Create a directory under HOME to test ~ expansion
    local home_subdir="$HOME/diralias-test-$$"
    mkdir -p "$home_subdir"

    run -0 "$SCRIPT_PATH" add homealias "$home_subdir"
    run -0 "$SCRIPT_PATH" status

    # Output should contain ~ instead of $HOME
    [[ "$output" == *"homealias -> ~/diralias-test-$$"* ]]
    ! [[ "$output" == *"$HOME"* ]]
}

@test "status: displays HOME itself as just ~" {
    run -0 "$SCRIPT_PATH" add homedir "$HOME"
    run -0 "$SCRIPT_PATH" status

    # $HOME itself should be displayed as just ~
    [[ "$output" == *"homedir -> ~"* ]]
}

@test "status: displays paths outside HOME with full path" {
    # Using BATS_TEST_TMPDIR which is outside HOME in tests
    local outside_dir
    outside_dir="$(make_target_dir outside)"

    run -0 "$SCRIPT_PATH" add outsidealias "$outside_dir"
    run -0 "$SCRIPT_PATH" status

    # Path outside HOME should show full path (no ~ substitution)
    [[ "$output" == *"outsidealias -> $outside_dir"* ]]
}

# ------------------------------------------------------------------------------
# path/tick-file

@test "path/tick-file: prints the path to the change-tick file" {
    local expected_tick_file="$BATS_TEST_TMPDIR/state/diralias/change-tick"
    run -0 "$SCRIPT_PATH" path tick-file
    [[ "$output" == "$expected_tick_file" ]]
}

@test "path/tick-file: creates storage on first use" {
    local state_dir="$BATS_TEST_TMPDIR/state/diralias"
    [[ ! -d "$state_dir" ]]

    run -0 "$SCRIPT_PATH" path tick-file
    [[ -f "$BATS_TEST_TMPDIR/state/diralias/change-tick" ]]
}

@test "path/tick-file: printed path is the actual file that holds the tick value" {
    run -0 "$SCRIPT_PATH" add one "$(make_target_dir tf1)"
    run -0 "$SCRIPT_PATH" add two "$(make_target_dir tf2)"

    run -0 "$SCRIPT_PATH" path tick-file
    local tick_path="$output"

    [[ "$(cat "$tick_path")" == "2" ]]
}

# ------------------------------------------------------------------------------
# path/aliases-dir

@test "path/aliases-dir: prints the path to the aliases directory" {
    local expected_aliases_dir="$BATS_TEST_TMPDIR/state/diralias/aliases"
    run -0 "$SCRIPT_PATH" path aliases-dir
    [[ "$output" == "$expected_aliases_dir" ]]
}

@test "path/aliases-dir: creates storage on first use" {
    local state_dir="$BATS_TEST_TMPDIR/state/diralias"
    [[ ! -d "$state_dir" ]]

    run -0 "$SCRIPT_PATH" path aliases-dir
    [[ -d "$BATS_TEST_TMPDIR/state/diralias/aliases" ]]
}

@test "path/aliases-dir: printed path is the actual directory that holds aliases" {
    local target
    target="$(make_target_dir ad1)"
    run -0 "$SCRIPT_PATH" add myalias "$target"

    run -0 "$SCRIPT_PATH" path aliases-dir
    local aliases_dir="$output"

    [[ -L "$aliases_dir/myalias" ]]
    [[ "$(readlink "$aliases_dir/myalias")" == "$target" ]]
}

# ------------------------------------------------------------------------------
# path/error

@test "path/error: calling path without sub-command shows error and exits non-zero" {
    run -1 --separate-stderr "$SCRIPT_PATH" path
    [[ "$stderr" == *"'path' requires a sub-command"* ]]
    [[ "$stderr" == *"tick-file|aliases-dir"* ]]
}

@test "path/error: unknown sub-command shows error and exits non-zero" {
    run -1 --separate-stderr "$SCRIPT_PATH" path bogus-subcmd
    [[ "$stderr" == *"Unknown path sub-command: bogus-subcmd"* ]]
    [[ "$stderr" == *"tick-file|aliases-dir"* ]]
}

# ------------------------------------------------------------------------------
# edge

@test "edge: storage directories are created automatically on first use" {
    local state_dir="$BATS_TEST_TMPDIR/state/diralias"
    [[ ! -d "$state_dir" ]]

    run -0 "$SCRIPT_PATH" status
    [[ -d "$state_dir/aliases" ]]
    [[ -f "$state_dir/change-tick" ]]
}

@test "edge: tick file initializes to 0" {
    run -0 "$SCRIPT_PATH" status
    local tick
    tick="$(cat "$BATS_TEST_TMPDIR/state/diralias/change-tick")"
    [[ "$tick" == "0" ]]
}

@test "edge: path with spaces is handled correctly" {
    local target
    target="$(make_target_dir "dir with spaces")"

    run -0 "$SCRIPT_PATH" add spacey "$target"
    run -0 "$SCRIPT_PATH" get "$target"
    [[ "$output" == "spacey" ]]
}
