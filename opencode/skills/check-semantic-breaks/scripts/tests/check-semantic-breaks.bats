# Test suite for `check-semantic-breaks` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats check-semantic-breaks.bats [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/../check-semantic-breaks"

# Create a fake HOME plus two shared input files for all tests.
# Mocking HOME ensures display_path() never touches the real home directory.
function setup() {
    HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"

    # Lines: 1 single short sentence (clean)
    CLEAN_FILE="$BATS_TEST_TMPDIR/clean.txt"
    printf '%s\n' \
        "Tighten the ship gate." \
        > "$CLEAN_FILE"

    # Lines: 1 single short sentence; 2 a hit (trailing sentence over the
    # shared-word limit)
    HIT_FILE="$BATS_TEST_TMPDIR/hit.txt"
    printf '%s\n' \
        "Tighten the ship gate." \
        "Tighten the ship gate. It now refuses to run entirely." \
        > "$HIT_FILE"
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: no args exits with usage" {
    run -2 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"Usage:"* ]]
}

@test "cli: rejects more than one '-' (stdin) argument" {
    run -2 --separate-stderr "$SCRIPT_PATH" - - <<< $'One. Two.\n'
    [[ "$stderr" == *"Usage:"* ]]
}

@test "cli: accepts multiple files" {
    run -0 "$SCRIPT_PATH" "$CLEAN_FILE" "$CLEAN_FILE"
    [[ "$output" == *"(OK)"* ]]
}

# ------------------------------------------------------------------------------
# Tests: stdin

@test "stdin: reads lines from stdin when given '-'" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten the ship gate. It now refuses to run entirely.\n'
    [[ "$output" == *"1: "* ]]
    [[ "$output" == *"┃"* ]]
}

@test "stdin: no path header printed for single stdin input" {
    run -0 "$SCRIPT_PATH" - <<< $'Tighten the ship gate.\n'
    [[ "$output" == *"(OK)"* ]]
    [[ "$output" != *"<stdin>"* ]]
}

@test "stdin: '<stdin>' header shown when mixed with files" {
    run -0 "$SCRIPT_PATH" "$CLEAN_FILE" - <<< $'Tighten the ship gate.\n'
    [[ "$output" == *"<stdin>:"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: missing file exits 2 with an error message" {
    run -2 --separate-stderr "$SCRIPT_PATH" /nonexistent/file.txt
    [[ "$stderr" == *"ERROR"* ]]
    [[ "$stderr" == *"/nonexistent/file.txt"* ]]
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: clean source prints (OK) and exits 0" {
    run -0 "$SCRIPT_PATH" "$CLEAN_FILE"
    [[ "$output" == *"(OK)"* ]]
    [[ "$output" != *"┃"* ]]
}

@test "defaults: flags a line holding two sentences" {
    run -1 "$SCRIPT_PATH" "$HIT_FILE"
    [[ "$output" == *"2: "* ]]
    [[ "$output" == *"┃"* ]]
}

@test "defaults: line number of a clean line is not reported" {
    run -1 "$SCRIPT_PATH" "$HIT_FILE"
    [[ "$output" != *"1: "* ]]
}

@test "defaults: prints boundary hint when a hit exists" {
    run -1 "$SCRIPT_PATH" "$HIT_FILE"
    [[ "$output" == *"sentence boundary"* ]]
}

@test "defaults: no path header printed for a single file" {
    run -1 "$SCRIPT_PATH" "$HIT_FILE"
    [[ "$output" != *"hit.txt:"* ]]
}

@test "defaults: flags an under-width line holding two sentences" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten the gate. Then run the whole suite now.\n'
    [[ "$output" == *"gate. ┃Then run"* ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: a short trailing sentence may share a line that fits the width" {
    run -0 "$SCRIPT_PATH" - <<< $'Tighten the gate. Done.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: a five-word trailing sentence may share a line that fits the width" {
    run -0 "$SCRIPT_PATH" - <<< $'Fix the gate. That keeps every release honest.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: flags a line whose trailing sentence holds six words" {
    run -1 "$SCRIPT_PATH" - <<< $'Fix the gate. That keeps every release honest too.\n'
    [[ "$output" == *"1: Fix the gate. ┃That keeps every ……"* ]]
}

@test "edge: flags an over-wide line even when the trailing sentence is short" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten the ship gate so it refuses to run whenever the working tree holds any uncommitted or untracked change. Done.\n'
    [[ "$output" == *"change. ┃Done."* ]]
}

@test "edge: flags an over-wide line whose trailing sentence is five words" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten the ship gate so it refuses to run whenever the working tree holds any uncommitted or untracked change. That keeps every release honest.\n'
    [[ "$output" == *"change. ┃That keeps"* ]]
}

@test "edge: flags an over-wide line whose trailing sentence is six words" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten the ship gate so it refuses to run whenever the working tree holds any uncommitted or untracked change. That keeps every release honest too.\n'
    [[ "$output" == *"change. ┃That keeps"* ]]
}

@test "edge: marks the boundary right before the second sentence" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten when the tree is dirty. That keeps it honest and clear.\n'
    [[ "$output" == *"dirty. ┃That keeps"* ]]
}

@test "edge: reports every offending boundary in compacted form" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten the gate first. Then run the whole suite quickly. Finally publish the notes to the team.\n'
    [[ "$output" == *"1: …… gate first. ┃Then run …… suite quickly. ┃Finally publish ……"* ]]
}

@test "edge: a lone boundary keeps three words of context" {
    run -1 "$SCRIPT_PATH" - <<< $'Tighten the ship gate. It now refuses to run entirely.\n'
    [[ "$output" == *"1: …… the ship gate. ┃It now refuses ……"* ]]
}

@test "edge: ignores an ordered-list marker" {
    run -0 "$SCRIPT_PATH" - <<< $'1. Tighten the ship gate so it refuses everything.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: ignores a bold ordered-list marker" {
    run -0 "$SCRIPT_PATH" - <<< $'**1. Tighten the ship gate so it refuses everything.**\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: still flags a second sentence inside a bold list item" {
    run -1 "$SCRIPT_PATH" - <<< $'**1. Tighten the gate. It now refuses to run entirely.**\n'
    [[ "$output" == *"gate. ┃It now refuses"* ]]
}

@test "edge: ignores a trailing abbreviation" {
    run -0 "$SCRIPT_PATH" - <<< $'Add approx. items here so the list stays tidy.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: flags a removed abbreviation" {
    run -1 "$SCRIPT_PATH" - <<< $'Add etc. items here so the list stays tidy.\n'
    [[ "$output" == *"etc. ┃items here"* ]]
}

@test "edge: ignores a dotted abbreviation" {
    run -0 "$SCRIPT_PATH" - <<< $'Use e.g. this form when the document needs it.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: ignores an ellipsis" {
    run -0 "$SCRIPT_PATH" - <<< $'Wait ... then go and finish the whole task.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: ignores a decimal number" {
    run -0 "$SCRIPT_PATH" - <<< $'Released in 1.2 today so everyone should update soon.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: ignores a filename" {
    run -0 "$SCRIPT_PATH" - <<< $'Edit SKILL.md now so the reader finds every section.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: ignores a dotted hostname" {
    run -0 "$SCRIPT_PATH" - <<< $'Visit example.com now to read the whole story.\n'
    [[ "$output" == *"(OK)"* ]]
}

@test "edge: '!' and '?' also end a sentence" {
    run -1 "$SCRIPT_PATH" - <<< $'Stop! Then go and ship it now. Go? Then finish the whole job up\n'
    [[ "$output" == *"Stop! ┃Then go"* ]]
    [[ "$output" == *"Go? ┃Then finish"* ]]
}

@test "edge: empty source prints (OK)" {
    local empty="$BATS_TEST_TMPDIR/empty.txt"
    touch "$empty"
    run -0 "$SCRIPT_PATH" "$empty"
    [[ "$output" == *"(OK)"* ]]
}

# ------------------------------------------------------------------------------
# Tests: display path

@test "display path: relative path shown when file is nested under CWD (multi-file)" {
    local work="$BATS_TEST_TMPDIR/work"
    local nested="$work/sub/input.txt"
    local extra="$work/extra.txt"
    mkdir -p "$work/sub"
    printf '%s\n' "Tighten the ship gate. It now refuses to run entirely." > "$nested"
    printf '%s\n' "Tighten the ship gate." > "$extra"
    cd "$work"
    run -1 "$SCRIPT_PATH" sub/input.txt extra.txt
    [[ "$output" == *"sub/input.txt:"* ]]
    # Must not show the absolute path.
    [[ "$output" != *"$work/sub"* ]]
}
