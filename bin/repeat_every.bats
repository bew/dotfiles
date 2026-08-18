# Test suite for `repeat_every` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/repeat_every"

# Run the script in the background and stop it with SIGTERM after $1 seconds.
# The script traps both SIGINT and SIGTERM; TERM is used because background
# jobs in non-interactive shells ignore SIGINT.
# The repeated command must append one line per run to $COUNTER_FILE.
# Populates globals: $output (script stdout+stderr) and $count (number of runs).
function run_and_stop() {
  local duration="$1"; shift
  COUNTER_FILE="$BATS_TEST_TMPDIR/counter"
  : > "$COUNTER_FILE"
  export COUNTER_FILE

  local output_file="$BATS_TEST_TMPDIR/output"
  "$SCRIPT_PATH" "$@" >"$output_file" 2>&1 &
  local pid=$!
  sleep "$duration"
  kill -TERM "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true

  output="$(cat "$output_file")"
  count="$(wc -l < "$COUNTER_FILE" | tr -d ' ')"
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: shows help with --help" {
  run -0 --separate-stderr "$SCRIPT_PATH" --help
  [[ "$stderr" == *"usage:"* ]]
  [[ "$stderr" == *"repeat_every"* ]]
}

@test "usage: shows help with -h" {
  run -0 --separate-stderr "$SCRIPT_PATH" -h
  [[ "$stderr" == *"usage:"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: exits 1 with no arguments" {
  run -1 "$SCRIPT_PATH"
}

@test "error: exits 1 with interval but no command" {
  run -1 "$SCRIPT_PATH" 1
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: runs the command repeatedly" {
  run_and_stop 0.6 0.1 sh -c 'echo x >> "$COUNTER_FILE"'
  [[ "$count" -ge 2 ]]
}

@test "cli: repeats despite non-zero exit of the command" {
  run_and_stop 0.6 0.1 sh -c 'echo x >> "$COUNTER_FILE"; exit 1'
  [[ "$count" -ge 2 ]]
}

@test "cli: -- separates flags from the command" {
  run_and_stop 0.6 0.1 -- sh -c 'echo x >> "$COUNTER_FILE"'
  [[ "$count" -ge 2 ]]
}

@test "cli: runs a lone spaced argument via sh -c" {
  run_and_stop 0.6 0.1 'echo x >> "$COUNTER_FILE"'
  [[ "$count" -ge 2 ]]
}

@test "cli: --end-after stops on its own" {
  run_and_stop 1.5 0.2 --end-after 0.5 sh -c 'echo x >> "$COUNTER_FILE"'
  [[ "$count" -ge 1 ]]
  [[ "$count" -lt 5 ]]
}

@test "cli: --end-after accepts fractional seconds" {
  run_and_stop 1.5 0.2 --end-after 0.4 sh -c 'echo x >> "$COUNTER_FILE"'
  [[ "$count" -ge 1 ]]
  [[ "$count" -lt 5 ]]
}

@test "cli: shows separator with --sep" {
  run_and_stop 1.2 0.5 --sep sh -c 'echo x >> "$COUNTER_FILE"'
  [[ "$output" == *"[repeat_every"* ]]
  [[ "$output" == *"Run #1"* ]]
  [[ "$count" -ge 2 ]]
}

@test "cli: compact separator omits blank lines" {
  run_and_stop 1.2 0.5 --compact-sep sh -c 'echo x >> "$COUNTER_FILE"'
  [[ "$output" != *$'\n\n'* ]]
}