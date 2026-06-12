#!/usr/bin/env bash

# Test suite for `manq` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats tests/manq.bats [--filter foobar]

# Require BATS 1.5.0+ for flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/../manq"

# ------------------------------------------------------------------------------
# toc

@test "toc: exits 0 on known page" {
    run -0 "$SCRIPT_PATH" toc grep
}

@test "toc: shows format tag [mdoc] or [man]" {
    run -0 "$SCRIPT_PATH" toc grep
    [[ "$output" == *"[mdoc]"* ]] || [[ "$output" == *"[man]"* ]]
}

@test "toc: NAME section present" {
    run -0 "$SCRIPT_PATH" toc grep
    [[ "$output" == *"NAME"* ]]
}

@test "toc: DESCRIPTION section present" {
    run -0 "$SCRIPT_PATH" toc grep
    [[ "$output" == *"DESCRIPTION"* ]]
}

@test "toc: shows option count in DESCRIPTION metadata" {
    run -0 "$SCRIPT_PATH" toc grep
    [[ "$output" =~ "options]" ]]
}

@test "toc: shows line count metadata for each section" {
    run -0 "$SCRIPT_PATH" toc grep
    # Each section line ends with something like [N lines]
    [[ "$output" =~ " lines]" ]]
}

@test "toc: prints synopsis on second line" {
    run -0 "$SCRIPT_PATH" toc grep
    # Second non-empty line is synopsis (indented with spaces)
    [[ "$output" == *"grep ["* ]]
}

@test "toc -O: exits 0" {
    run -0 "$SCRIPT_PATH" toc grep -O
}

@test "toc -O: prints Options: header" {
    run -0 "$SCRIPT_PATH" toc grep -O
    [[ "$output" == *"Options:"* ]]
}

@test "toc -O: options list has entries" {
    run -0 "$SCRIPT_PATH" toc grep -O
    # Each entry is indented with two spaces followed by a flag
    [[ "$output" == *"  -"* ]]
}

@test "toc -L: level 1 exits 0" {
    run -0 "$SCRIPT_PATH" toc grep -L 1
}

@test "toc -L: level 1 output has no children indented" {
    run -0 "$SCRIPT_PATH" toc grep -L 1
    # No lines starting with 4+ spaces (subsection indent would be 2 spaces per level)
    [[ ! "$output" =~ $'    [A-Z]' ]]
}

@test "toc -S: scopes output to one section" {
    run -0 "$SCRIPT_PATH" toc grep -S DESCRIPTION
    [[ "$output" == *"DESCRIPTION"* ]]
    # Should not show unrelated top-level sections like EXAMPLES or BUGS
    [[ ! "$output" == *"EXAMPLES"* ]]
    [[ ! "$output" == *"BUGS"* ]]
}

@test "toc: true man page exits 0" {
    run -0 "$SCRIPT_PATH" toc true
}

@test "toc: true man page shows NAME" {
    run -0 "$SCRIPT_PATH" toc true
    [[ "$output" == *"NAME"* ]]
}

@test "error: toc nonexistent page exits non-zero" {
    run --separate-stderr "$SCRIPT_PATH" toc _no_such_manpage_xyzzy_
    [[ "$status" -ne 0 ]]
}

@test "error: toc nonexistent page prints error to stderr" {
    run --separate-stderr "$SCRIPT_PATH" toc _no_such_manpage_xyzzy_
    [[ "$stderr" == *"not found"* ]]
}

# ------------------------------------------------------------------------------
# section

@test "section: exits 0 for known section" {
    run -0 "$SCRIPT_PATH" section grep EXAMPLES
}

@test "section: section header present in output" {
    run -0 "$SCRIPT_PATH" section grep EXAMPLES
    [[ "$output" == *"EXAMPLES"* ]]
}

@test "section: output starts with ## header line" {
    run -0 "$SCRIPT_PATH" section grep EXAMPLES
    [[ "$output" == "## EXAMPLES"* ]]
}

@test "section: header shows total line count" {
    run -0 "$SCRIPT_PATH" section grep EXAMPLES
    [[ "$output" =~ "## EXAMPLES ["[0-9]*" lines]" ]]
}

@test "section --lines: line range shows correct header" {
    run -0 "$SCRIPT_PATH" section grep EXAMPLES --lines 1-5
    [[ "$output" == *"showing lines 1-5"* ]]
}

@test "section --lines: restricts content to requested range" {
    run -0 "$SCRIPT_PATH" section grep EXAMPLES --lines 1-5
    # Output: header line + blank + up to 5 content lines; should be <=8 lines total
    local line_count
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    (( line_count <= 8 ))
}

@test "section: multiple sections in one call" {
    run -0 "$SCRIPT_PATH" section grep EXAMPLES "EXIT STATUS"
    [[ "$output" == *"EXAMPLES"* ]]
    [[ "$output" == *"EXIT STATUS"* ]]
}

@test "error: section unknown name prints not-found message to stderr" {
    run --separate-stderr "$SCRIPT_PATH" section grep _NO_SUCH_SECTION_XYZ_
    [[ "$stderr" == *"not found"* ]]
}

@test "error: section unknown name exits 0 (best-effort, continues)" {
    # manq prints the error but keeps going (exits 0 per current behavior)
    run "$SCRIPT_PATH" section grep _NO_SUCH_SECTION_XYZ_
    [[ "$status" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# flag

@test "flag: exits 0 for known flag" {
    run -0 "$SCRIPT_PATH" flag grep -v
}

@test "flag: output contains the flag itself" {
    run -0 "$SCRIPT_PATH" flag grep -v
    [[ "$output" == *"-v"* ]]
}

@test "flag: -v does not bleed into -V" {
    run -0 "$SCRIPT_PATH" flag grep -v
    [[ "$output" != *"-V,"* ]]
}

@test "flag: -v does not bleed into --recursive" {
    run -0 "$SCRIPT_PATH" flag grep -v
    [[ "$output" != *"--recursive"* ]]
}

@test "flag: long form --invert-match resolves" {
    run -0 "$SCRIPT_PATH" flag grep --invert-match
    [[ "$output" != *"not found"* ]]
}

@test "flag: short and long form together both resolve" {
    run -0 "$SCRIPT_PATH" flag grep -v --invert-match
    [[ "$status" -eq 0 ]]
    # Both should match -v / --invert-match entry; output should not say not found
    [[ "$output" != *"not found"* ]]
}

@test "flag: unknown flag prints not-found" {
    run -0 "$SCRIPT_PATH" flag grep --_no_such_flag_xyz_
    [[ "$output" == *"not found"* ]]
}

@test "flag: multiple flags in one call" {
    run -0 "$SCRIPT_PATH" flag grep -v -c
    [[ "$output" == *"-v"* ]]
    [[ "$output" == *"-c"* ]]
}
