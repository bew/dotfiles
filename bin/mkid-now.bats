# Test suite for `mkid-now` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for --separate-stderr flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/mkid-now"

@test "defaults: output matches YYYYmmddTHHMM format" {
  run -0 "$SCRIPT_PATH"
  [[ "$output" =~ ^[0-9]{4}[0-9]{2}[0-9]{2}T[0-9]{2}[0-9]{2}$ ]]
}

@test "defaults: output matches the current minute" {
  local expected_before expected_after
  expected_before=$(date +%Y%m%dT%H%M)
  run -0 "$SCRIPT_PATH"
  expected_after=$(date +%Y%m%dT%H%M)

  # Accept either value to handle a minute rollover between the two `date` calls
  [[ "$output" == "$expected_before" || "$output" == "$expected_after" ]]
}
