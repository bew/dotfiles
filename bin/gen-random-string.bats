#!/usr/bin/env bats
# Test suite for `gen-random-string` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for --separate-stderr flag support on `run`
bats_require_minimum_version 1.5.0

# Get the directory containing this test file
SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/gen-random-string"

# All char types: letters (mixed case), digits, punctuation, spaces, quotes, ambiguous
MIXED_INPUT="The-Quick.2026;Brown*Fox!Jumps@Over#Lazy\$Dogs%2024^Running&Fast(In)Rain+Snow_More=Text[With]Braces{And}Pipes|Semicolons;Colons:Commas,Angles<>Question?Slash/Backtick\`Quote'Double\"Tilde~ \t"

# Longer version of MIXED_INPUT for tests requiring more chars
LONG_MIXED_INPUT="${MIXED_INPUT}${MIXED_INPUT}${MIXED_INPUT}${MIXED_INPUT}"

# Word-like phrases with digits and symbols
WORD_NUMERIC_INPUT="The2024Brown8Fox!Jumps@Over#Lazy5Dogs9Running3Fast"

# Setup function, runs before each test
function setup() {
  # Ensure script exists and is executable
  [[ -x "$SCRIPT_PATH" ]]
}

# Helper: Setup the default input file with $LONG_MIXED_INPUT
function setup_test_random_input_file() {
  local input="${1:-$LONG_MIXED_INPUT}"
  TEST_INPUT_FILE="$BATS_TEST_TMPDIR/test-input.txt"
  echo -n "$input" > "$TEST_INPUT_FILE"
}

# Helper: Run script with default test input, expecting success
function run_script() {
  setup_test_random_input_file
  GEN_RANDOM_SOURCE_FILE="$TEST_INPUT_FILE" run -0 --separate-stderr "$SCRIPT_PATH" "$@"
}

# Helper: Run script with custom test input, expecting success
function run_script_with_input() {
  local custom_input="$1"; shift
  setup_test_random_input_file "$custom_input"

  GEN_RANDOM_SOURCE_FILE="$TEST_INPUT_FILE" run -0 --separate-stderr "$SCRIPT_PATH" "$@"
}

# Helper: Run script expecting failure
function run_script_failed() {
  setup_test_random_input_file
  GEN_RANDOM_SOURCE_FILE="$TEST_INPUT_FILE" run -1 --separate-stderr "$SCRIPT_PATH" "$@"
}

# Helper: Echo to stderr
function echo_err() {
  echo >&2 "$*"
}

# Helper: Assert that output length matches expected
function assert_length() {
  local output="$1"
  local expected_length="$2"
  [[ "${#output}" -eq "$expected_length" ]]
}

# Helper: Assert that all chars in output match a charset
function assert_all_chars() {
  # Uses tr to delete matching chars - if nothing remains, all chars matched
  local output="$1"
  local charset="$2"
  local filtered
  # Delete all chars that match the charset
  filtered=$(echo -n "$output" | LC_ALL=C tr -d "$charset")
  # If anything remains, those chars didn't match
  if [[ -n "$filtered" ]]; then
    echo_err "Output contains chars not in allowed charset: '$charset'"
    echo_err "Invalid chars: '$filtered'"
    return 1
  fi
  return 0
}

# Helper: Assert that output does NOT contain any of the specified chars
function assert_no_chars() {
  # Uses tr to delete forbidden chars - if output changes, forbidden chars were present
  local output="$1"
  local forbidden_chars="$2"
  local filtered
  filtered=$(echo -n "$output" | LC_ALL=C tr -d "$forbidden_chars")
  if [[ "$output" != "$filtered" ]]; then
    echo_err "Output contains forbidden chars from charset: '$forbidden_chars'"
    return 1
  fi
  return 0
}

# Helper: Assert that output contains at least one of the specified chars
function assert_has_chars() {
  # Uses tr to keep only required chars - if result is non-empty, at least one was present
  local output="$1"
  local required_chars="$2"
  local filtered
  filtered=$(echo -n "$output" | LC_ALL=C tr -cd "$required_chars")
  if [[ -z "$filtered" ]]; then
    echo_err "Output does not contain any chars from required charset: '$required_chars'"
    return 1
  fi
  return 0
}

################################################################################
# Tests: Helper Function

@test "helpers: check assert_length works" {
  assert_length "hello" 5

  run -1 assert_length "hello" 4
  run -1 assert_length "hello" 6
}

@test "helpers: check assert_all_chars works" {
  assert_all_chars "abc123" "a-z0-9"
  assert_all_chars "ABC" "A-Z"
  assert_all_chars "cafe1234" "0-9a-f"

  run -1 --separate-stderr assert_all_chars "abc:123!" "a-z0-9"
  [[ "$stderr" == "Output contains chars not in allowed charset"* ]]
}

@test "helpers: check assert_no_chars works" {
  assert_no_chars "hello" "0-9"
  assert_no_chars "abc123" "!@#"

  run -1 --separate-stderr assert_no_chars "hello123" "0-9"
  [[ "$stderr" == "Output contains forbidden chars from charset"* ]]
}

@test "helpers: check assert_has_chars works" {
  assert_has_chars "hello123" "0-9"
  assert_has_chars "test" "aeiou"

  run -1 --separate-stderr assert_has_chars "hello" "0-9"
  [[ "$stderr" == "Output does not contain any chars from required charset"* ]]
}

################################################################################
# Tests: Basic Functionality with defaults

@test "defaults: generates 32-chars string" {
  run_script
  assert_length "$output" 32
}

@test "defaults: includes letters and numbers" {
  run_script
  assert_has_chars "$output" "a-z"
}

@test "defaults: excludes spaces, quotes and ambiguous chars" {
  run_script
  # Check spaces exclusion
  assert_no_chars "$output" " "
  assert_no_chars "$output" $'\t'

  # Check quotes exclusion
  assert_no_chars "$output" "'\"\`"

  # Check ambiguous chars exclusion (short list)
  assert_no_chars "$output" "0O1lI"
}

################################################################################
# Tests: source warning

@test "warning: custom random source produces warning on stderr" {
  setup_test_random_input_file
  GEN_RANDOM_SOURCE_FILE="$TEST_INPUT_FILE" run -0 --separate-stderr "$SCRIPT_PATH" 10
  [[ "$stderr" == *"WARNING: Using custom random source"* ]]
  assert_length "$output" 10
}

@test "warning: no warning when using default random source" {
  # note: no test random input file, will use /dev/urandom
  run -0 --separate-stderr "$SCRIPT_PATH" 10
  [[ -z "$stderr" ]] # empty stderr (no warning)
  assert_length "$output" 10
}

################################################################################
# Tests: Length

@test "length: accepts positional length argument" {
  run_script 16
  assert_length "$output" 16
}

@test "length: accepts --len flag" {
  run_script --len 24
  assert_length "$output" 24
}

@test "length: generates very short string (1 char)" {
  run_script 1
  assert_length "$output" 1
}

@test "length: generates long string (1024 chars)" {
  # Generate enough input data for a 1024-chars string
  local very_long_input=""
  for i in {1..10}; do
    very_long_input+="${LONG_MIXED_INPUT}"
  done
  run_script_with_input "$very_long_input" 1024
  assert_length "$output" 1024
}

################################################################################
# Rule Tests: Additive Rules

@test "rule: +quotes includes quote chars" {
  # Phrases with quote chars (' " `)
  local input="hello'world\"test\`more'quote\"chars\`here"
  run_script_with_input "$input" 50 +quotes
  assert_has_chars "$output" "'\"\`"
}

@test "rule: +noambig/+noambigall excludes ambiguous chars" {
  # Chars with ambiguous lookalikes
  local input="test0O1lI2Z5S8B6Gmore0O1lI2Z5S8B6Gagain"

  run_script_with_input "$input" 50 +noambig
  assert_no_chars "$output" "0O1lI" # no ambig from short list
  assert_has_chars "$output" "25ZB8" # but doesn't filter ambig from long list

  run_script_with_input "$input" 50 +noambigall
  assert_no_chars "$output" "0O1lI2Z5S8B6G" # no ambig from long list
}

@test "rule: +space includes space chars" {
  # Words with spaces for testing space handling
  local input="hello   world\ttest more       words \t with spaces here"
  run_script_with_input "$input" 50 +space
  assert_has_chars "$output" " "
}

################################################################################
# Rule Tests: Subtractive Rules

@test "rule: +nonum excludes numbers" {
  run_script 32 +nonum
  assert_no_chars "$output" "0-9"
}

@test "rule: +nopunct excludes punctuation" {
  run_script 32 +nopunct
  assert_no_chars "$output" "!@#\$%^&*()"
}

@test "rule: +noupper excludes uppercase letters" {
  run_script 32 +noupper
  assert_no_chars "$output" "A-Z"
}

@test "rule: +nolower excludes lowercase letters" {
  run_script 32 +nolower
  assert_no_chars "$output" "a-z"
}

################################################################################
# Tests: --only Mode

@test "--only: +num generates numeric-only string" {
  # Letters and digits with punctuation (tests numeric filtering)
  local input="pass2024word8secure6data7test5more3numbers1again9end0"
  run_script_with_input "$input" 8 --only +num
  # Deterministic: first 8 digits extracted from mixed input
  [[ "$output" == "20248675" ]]
  # Verify no letters made it through
  assert_all_chars "$output" "0-9"
}

@test "--only: +alpha generates letters-only string" {
  run_script_with_input "$WORD_NUMERIC_INPUT" 16 --only +alpha
  # Deterministic: first 16 letters from mixed input (numbers/punctuation filtered out)
  [[ "$output" == "TheBrownFoxJumps" ]]
  # Verify no digits or punctuation made it through
  assert_all_chars "$output" "a-zA-Z"
}

@test "--only: +alpha +num generates alphanumeric string" {
  # Heavy punctuation for testing punctuation filtering
  local input='Quick!2024@Brown#8Fox$Jumps%3Over&Lazy*5Dogs(9Test)'
  run_script_with_input "$input" 20 --only +alpha +num
  # Deterministic: first 20 alphanumeric chars (punctuation filtered out)
  [[ "$output" == "Quick2024Brown8FoxJu" ]]
  # Verify no punctuation made it through
  assert_all_chars "$output" "a-zA-Z0-9"
}

@test "--only: +printable includes all types of printable chars" {
  run_script 100 --only +printable
  # Should contain various char types from the mixed input
  assert_has_chars "$output" "a-z"  # lowercase letters
  assert_has_chars "$output" "A-Z"  # uppercase letters
  assert_has_chars "$output" "0-9"  # digits
  # Should contain at least some punctuation from the input
  assert_has_chars "$output" "!@#$%^&*()"
}

HEX_hex_INPUT="cafe!1234@babe#5678\$DEAD%9012^BEEF&3456*FACE(7890)zzz"

@test "--only: +hex generates lowercase hex string" {
  # Hex-like with non-hex chars mixed in (lowercase)
  run_script_with_input "$HEX_hex_INPUT" 16 --only +hex
  # Deterministic: first 16 hex chars (non-hex letters and punctuation filtered out)
  [[ "$output" == "cafe1234babe5678" ]]
  # Verify only hex chars made it through
  assert_all_chars "$output" "0-9a-f"
  assert_no_chars "$output" "A-Z"
}

@test "--only: +HEX generates uppercase hex string" {
  # Hex-like with non-hex chars mixed in (uppercase)
  run_script_with_input "$HEX_hex_INPUT" 32 --only +HEX
  # Deterministic: first 16 uppercase hex chars (non-hex letters and punctuation filtered out)
  [[ "$output" == "12345678DEAD9012BEEF3456FACE7890" ]]
  # Verify only uppercase hex chars made it through
  assert_all_chars "$output" "0-9A-F"
  assert_no_chars "$output" "a-z"
}

@test "--only: +b64 generates base64-compatible string" {
  # Base64 chars with invalid chars mixed in
  local input="Quick!Brown@4Fox#8Jumps\$+Over%/Lazy^=Dogs&2Run*+Fast(/More)=Data~"
  run_script_with_input "$input" 32 --only +b64
  # Deterministic: first 32 base64 chars (invalid b64 chars filtered out)
  [[ "$output" == "QuickBrown4Fox8Jumps+Over/Lazy=D" ]]
  # Verify only base64 chars made it through
  assert_all_chars "$output" "a-zA-Z0-9+/="
}

@test "--only: +b64url generates URL-safe base64 string" {
  # URL-safe base64 with invalid chars mixed in
  local input='Quick!_Brown@4Fox#8Jumps$-Over%_Lazy^-Dogs&2Run*_Fast(-More)_Data~'
  run_script_with_input "$input" 32 --only +b64url
  # Deterministic: first 32 URL-safe base64 chars (invalid chars filtered out)
  [[ "$output" == "Quick_Brown4Fox8Jumps-Over_Lazy-" ]]
  # Verify only URL-safe base64 chars made it through
  assert_all_chars "$output" "a-zA-Z0-9_-"
}

################################################################################
# Tests: args parsing & error handling

@test "cli: options can be given in any order" {
  run_script +nonum --len 16 +noupper
  assert_length "$output" 16
  assert_no_chars "$output" "0-9A-Z"
}

@test "cli: --only flag can be placed anywhere (with --len)" {
  run_script_with_input "$WORD_NUMERIC_INPUT" +alpha --only --len 16
  assert_length "$output" 16
  assert_all_chars "$output" "a-zA-Z"
}

@test "cli: multiple flags can be mixed with rules" {
  run_script_with_input "$WORD_NUMERIC_INPUT" --only --len 16 +alpha
  assert_length "$output" 16
  assert_all_chars "$output" "a-zA-Z"
}

@test "cli: --help works regardless of position" {
  # --help at the beginning
  run_script --help 16 +nonum
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"Examples:"* ]]

  # --help in the middle
  run_script 16 --help +nonum
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"Examples:"* ]]

  # --help at the end
  run_script 16 +nonum --help
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"Examples:"* ]]
}

@test "error: rejects invalid length (non-numeric)" {
  run_script_failed abc
  [[ "$stderr" == *"Unknown argument"* ]]
}

@test "error: rejects zero length" {
  run_script_failed 0
  [[ "$stderr" == *"positive integer"* ]]
}

@test "error: rejects negative length" {
  run_script_failed -5
  [[ "$stderr" == *"Unknown argument: -5"* ]]

  run_script_failed --len -5
  [[ "$stderr" == *"Length must be a positive integer"* ]]
}

@test "error: rejects unknown rule" {
  run_script_failed +foobar
  [[ "$stderr" == *"Unknown charset rule"* ]]
}

@test "error: --only without rules fails" {
  run_script_failed --only
  [[ "$stderr" == *"No charset rules"* ]]
}

@test "error: --len without argument fails" {
  run_script_failed --len
  [[ "$stderr" == *"--len requires an argument"* ]]
}

################################################################################
# Tests: Help and Usage

@test "help: -h/--help displays usage message" {
  run_script -h
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"Examples:"* ]]

  run_script --help
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"Examples:"* ]]
}

################################################################################
# Edge Cases and Complex Combinations

@test "edge: multiple subtractive rules work together" {
  run_script 32 +nonum +noupper +nopunct
  assert_no_chars "$output" "0-9"
  assert_no_chars "$output" "A-Z"
  assert_no_chars "$output" "!@#\$%^&*()"
}

@test "edge: combining additive and subtractive rules" {
  # Use quoted input with numbers to test both additive and subtractive rules
  run_script_with_input "'\"\`'\"\`'\"\`'\"\`'\"\`${LONG_MIXED_INPUT}" 32 +quotes +nonum
  # Should have quotes but no numbers
  assert_has_chars "$output" "'\"\`"
  assert_no_chars "$output" "0-9"
}

@test "edge: very long string with limited charset" {
  # Use repeated word/numeric input to verify filtering works over long sequences
  local repeated_input=""
  for i in {1..20}; do
    repeated_input="${repeated_input}${WORD_NUMERIC_INPUT}"
  done
  run_script_with_input "$repeated_input" 100 --only +alpha
  assert_length "$output" 100
  # Verify only letters made it through despite numbers/punctuation in input
  assert_all_chars "$output" "a-zA-Z"
}

@test "integration: realistic use case - alphanumeric no ambiguous" {
  run_script 20 --only +alpha +num +noambig
  assert_length "$output" 20
  assert_all_chars "$output" "a-zA-Z0-9"
  assert_no_chars "$output" "0O1lI"
}
