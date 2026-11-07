# Test suite for `git-tracked-new-files` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

load _bats_helpers.sh

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/git-tracked-new-files"

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: shows intent-to-add file with 'new file:' label" {
    setup_intent_to_add "new-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new file: new-file.txt" ]]
}

@test "defaults: shows multiple intent-to-add files with 'new file:' label" {
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == *"new file: alpha.txt"* ]]
    [[ "$output" == *"new file: beta.txt"* ]]
}

@test "defaults: shows unstaged rename with 'renamed:' label" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == " renamed: new.txt" ]]
}

@test "defaults: shows both intent-to-add and renamed files together" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"
    setup_intent_to_add "brand-new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == *"new file: brand-new.txt"* ]]
    [[ "$output" == *"renamed: new.txt"* ]]
}

@test "defaults: no output when no intent-to-add files" {
    setup_initial_commit

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "defaults: empty repo with no files produces no output" {
    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "defaults: staged files (fully added) are not shown" {
    setup_initial_commit
    setup_staged "staged-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "defaults: untracked files are not shown" {
    setup_initial_commit
    setup_untracked "untracked-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

@test "defaults: only intent-to-add shown when mix of file states present" {
    setup_initial_commit
    setup_intent_to_add "new-file.txt"
    setup_staged "staged-file.txt"
    setup_untracked "untracked-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new file: new-file.txt" ]]
    [[ ! "$output" =~ staged-file ]]
    [[ ! "$output" =~ untracked-file ]]
}

@test "defaults: intent-to-add file in subdirectory shows full relative path" {
    setup_intent_to_add "sub/dir/nested.txt"

    run -0 --separate-stderr "$SCRIPT_PATH"
    [[ "$output" == "new file: sub/dir/nested.txt" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: --raw outputs bare paths without XY prefix" {
    setup_intent_to_add "new-file.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == "new-file.txt" ]]
}

@test "cli: --raw with multiple files outputs one path per line" {
    setup_intent_to_add "alpha.txt"
    setup_intent_to_add "beta.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == *"alpha.txt"* ]]
    [[ "$output" == *"beta.txt"* ]]
    # No label prefix on any line
    [[ ! "$output" =~ "new file:" ]]
}

@test "cli: --raw outputs bare new path for unstaged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == "new.txt" ]]
}

@test "cli: --json outputs array with kind and path for intent-to-add file" {
    setup_intent_to_add "new-file.txt"

    run_json "$SCRIPT_PATH" --json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"new-file","path":"new-file.txt"}]' ]]
}

@test "cli: --json outputs kind rename for unstaged rename" {
    setup_initial_commit
    setup_committed_file "old.txt"
    setup_unstaged_rename "old.txt" "new.txt"

    run_json "$SCRIPT_PATH" --json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"rename","path":"new.txt","old_path":"old.txt"}]' ]]
}

@test "cli: --json handles paths with spaces in rename" {
    setup_initial_commit
    setup_committed_file "old file.txt"
    setup_unstaged_rename "old file.txt" "new file.txt"

    run_json "$SCRIPT_PATH" --json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"rename","path":"new file.txt","old_path":"old file.txt"}]' ]]
}

@test "cli: --json handles paths with spaces for intent-to-add" {
    setup_intent_to_add "new file.txt"

    run_json "$SCRIPT_PATH" --json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[{"kind":"new-file","path":"new file.txt"}]' ]]
}

@test "cli: --json outputs empty array when no new files" {
    setup_initial_commit

    run_json "$SCRIPT_PATH" --json
    [[ -z "$stderr" ]]
    [[ "$compact_json_output" == '[]' ]]
}

@test "cli: --raw with subdirectory file shows full relative path" {
    setup_intent_to_add "sub/dir/nested.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw
    [[ "$output" == "sub/dir/nested.txt" ]]
}

@test "cli: pathspec limits the listing" {
    setup_initial_commit
    setup_intent_to_add "a.txt"
    setup_intent_to_add "sub/b.txt"

    run -0 --separate-stderr "$SCRIPT_PATH" --raw "a.txt"
    [[ "$output" == "a.txt" ]]
}

@test "cli: --rel prints paths relative to the current directory" {
    setup_intent_to_add "sub/a.txt"
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "new file: a.txt" ]]
}

@test "cli: --rel prefixes a path outside the current directory with .." {
    setup_intent_to_add "top.txt"
    mkdir -p sub
    cd sub

    run -0 --separate-stderr "$SCRIPT_PATH" --rel
    [[ "$output" == "new file: ../top.txt" ]]
}
