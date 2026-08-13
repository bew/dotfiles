# Test suite for `check-long-lines` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats check-long-lines.bats [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/../check-long-lines"

# Create a temp file with known content and a fake HOME for all tests.
# Mocking HOME ensures display_path() never touches the real home directory.
function setup() {
    HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"

    TEST_FILE="$BATS_TEST_TMPDIR/input.txt"
    # Lines:
    #   1: 10 chars  — under limit
    #   2: 20 chars  — exactly at limit=20 (not over)
    #   3: 25 chars  — over limit=20 by 5
    printf '%s\n' \
        "0123456789" \
        "01234567890123456789" \
        "0123456789012345678901234" \
        > "$TEST_FILE"
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: requires at least 2 args" {
    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"Usage:"* ]]
}

@test "cli: requires at least a file arg" {
    run -1 --separate-stderr "$SCRIPT_PATH" 80
    [[ "$stderr" == *"Usage:"* ]]
}

@test "cli: accepts multiple files" {
    run -0 "$SCRIPT_PATH" 20 "$TEST_FILE" "$TEST_FILE"
    [[ "$output" == *"input.txt"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: non-numeric limit" {
    run -1 --separate-stderr "$SCRIPT_PATH" abc "$TEST_FILE"
    [[ "$stderr" == *"Error:"* ]]
    [[ "$stderr" == *"abc"* ]]
}

@test "error: zero limit" {
    run -1 --separate-stderr "$SCRIPT_PATH" 0 "$TEST_FILE"
    [[ "$stderr" == *"Error:"* ]]
}

@test "error: negative limit" {
    run -1 --separate-stderr "$SCRIPT_PATH" -5 "$TEST_FILE"
    [[ "$stderr" == *"Error:"* ]]
}

@test "error: missing file exits non-zero" {
    run -1 --separate-stderr "$SCRIPT_PATH" 80 /nonexistent/file.txt
    [[ "$stderr" == *"Error:"* ]]
    [[ "$stderr" == *"/nonexistent/file.txt"* ]]
}

@test "error: continues scanning valid files when one is missing" {
    # Valid file is scanned; missing file is reported to stderr after.
    run -1 --separate-stderr "$SCRIPT_PATH" 80 "$TEST_FILE" /nonexistent/file.txt
    [[ "$output" == *"(OK)"* ]]
    [[ "$stderr" == *"/nonexistent/file.txt"* ]]
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: prints header line with limit" {
    run -0 "$SCRIPT_PATH" 20 "$TEST_FILE"
    [[ "$output" == *"column 20"* ]]
}

@test "defaults: no output for lines within limit" {
    # Only line 3 (25 chars) exceeds limit=20; lines 1 and 2 must not appear.
    run -0 "$SCRIPT_PATH" 20 "$TEST_FILE"
    # Line 1 content starts with "0123456789\n" — 10 chars, well under.
    # Line 2 is exactly 20 chars — not over, must be absent.
    [[ "$output" != *"2: "* ]]
}

@test "defaults: reports over-limit line with marker" {
    run -0 "$SCRIPT_PATH" 20 "$TEST_FILE"
    # Line 3 is 25 chars; context before=last 15 chars up to col 20, overflow=5 chars.
    [[ "$output" == *"┃"* ]]
    [[ "$output" == *"3: "* ]]
}

@test "defaults: shows within-limit message when no violations" {
    # limit=100 — all lines are under.
    run -0 "$SCRIPT_PATH" 100 "$TEST_FILE"
    # Single file: no path header is printed.
    [[ "$output" != *"input.txt:"* ]]
    [[ "$output" == *"(OK)"* ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: empty file shows within-limit message" {
    local empty="$BATS_TEST_TMPDIR/empty.txt"
    touch "$empty"
    run -0 "$SCRIPT_PATH" 10 "$empty"
    # Single file: no path header is printed.
    [[ "$output" != *"empty.txt:"* ]]
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: line exactly at limit is not reported" {
    # Line 2 is exactly 20 chars — must not appear with limit=20.
    run -0 "$SCRIPT_PATH" 20 "$TEST_FILE"
    [[ "$output" != *"2: "* ]]
}

@test "edge: context truncated when line shorter than CONTEXT_CHARS before limit" {
    # Line 1 is 10 chars; with limit=15, start=max(0,15-15)=0, before=line[0:15]=full line.
    local short_file="$BATS_TEST_TMPDIR/short.txt"
    printf '%s\n' "0123456789xxxxxx" > "$short_file"   # 16 chars, over limit=15
    run -0 "$SCRIPT_PATH" 15 "$short_file"
    [[ "$output" == *"┃"* ]]
}

# ------------------------------------------------------------------------------
# Tests: display path

@test "display path: no path header printed for single file" {
    run -0 "$SCRIPT_PATH" 20 "$TEST_FILE"
    [[ "$output" != *"input.txt:"* ]]
}

@test "display path: relative path shown when file is nested under CWD (multi-file)" {
    local work="$BATS_TEST_TMPDIR/work"
    local nested="$work/sub/input.txt"
    local extra="$work/extra.txt"
    mkdir -p "$work/sub"
    printf '%s\n' "this line is over twenty chars long" > "$nested"
    printf '%s\n' "short" > "$extra"
    # Run from $work — file is at sub/input.txt relative to it.
    cd "$work"
    run -0 "$SCRIPT_PATH" 20 sub/input.txt extra.txt
    [[ "$output" == *"sub/input.txt:"* ]]
    # Must not show absolute path.
    [[ "$output" != *"$work/sub"* ]]
}

@test "display path: absolute path shown with ~ when file is outside CWD but under HOME (multi-file)" {
    # Uses the fake HOME set in setup() — no real home dir touched.
    local home_sub="$HOME/docs"
    mkdir -p "$home_sub"
    local home_file="$home_sub/input.txt"
    local extra="$BATS_TEST_TMPDIR/extra.txt"
    printf '%s\n' "this line is over twenty chars long" > "$home_file"
    printf '%s\n' "short" > "$extra"

    # CWD set outside fake HOME so relative-to-CWD display doesn't trigger.
    local other="$BATS_TEST_TMPDIR/other"
    mkdir -p "$other"
    cd "$other"
    run -0 "$SCRIPT_PATH" 20 "$home_file" "$extra"
    [[ "$output" == *"~/docs/input.txt:"* ]]
}

@test "display path: absolute path shown when file is outside CWD and outside HOME (multi-file)" {
    local abs_file="$BATS_TEST_TMPDIR/input.txt"
    local extra="$BATS_TEST_TMPDIR/extra.txt"
    printf '%s\n' "this line is over twenty chars long" > "$abs_file"
    printf '%s\n' "short" > "$extra"
    # CWD set to a sibling dir so relative_to(CWD) fails; /tmp is outside HOME.
    local other="$BATS_TEST_TMPDIR/other"
    mkdir -p "$other"
    cd "$other"
    run -0 "$SCRIPT_PATH" 20 "$abs_file" "$extra"
    [[ "$output" == *"$abs_file:"* ]]
}
