# Test suite for `countdown` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $BATS_TEST_FILENAME [--filter topic]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/countdown"

function setup() {
    # Shared setup for all tests
    export TZ=UTC
}

@test "cli: counts down specified number of seconds" {
    # Use a small value so the test completes quickly.
    run -0 "$SCRIPT_PATH" 2

    [[ "$output" == *"Counting down from 2s.."* ]]
    [[ "$output" == *"Finished!"* ]]
}

@test "cli: prints time updates while counting down" {
    # Another short countdown to ensure multiple timer updates are printed.
    run -0 "$SCRIPT_PATH" 3

    [[ "$output" == *"Counting down from 3s.."* ]]

    # At least one MM:SS timer update should appear in the output.
    local count
    count=$(grep -c '00:' <<<"$output")
    [[ "$count" -ge 1 ]]
}

# Run the script in the background, interrupt it after WAIT_SECONDS, and
# store its output in OUTPUT_LOG. The caller can then read OUTPUT_LOG.
function run_and_interrupt() {
    local wait_seconds="$1"
    local output_log="$2"

    "$SCRIPT_PATH" 30 >"$output_log" 2>&1 &
    local pid=$!
    sleep "$wait_seconds"
    kill -INT "$pid"
    wait "$pid"
}

@test "signal: stopping early prints correct elapsed time and no Finished" {
    local log output
    log="$BATS_TEST_TMPDIR/countdown-sigint.log"

    run_and_interrupt 3 "$log"
    output=$(cat "$log")

    [[ "$output" == *"Counting down from 30s.."* ]]
    # Only check the integer part; the decimal digit varies with timing.
    [[ "$output" == *"Stopped early! Elapsed: 3."* ]]
    [[ "$output" != *"Finished!"* ]]
}
