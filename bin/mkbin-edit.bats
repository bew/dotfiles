# Test suite for `mkbin-edit` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for --separate-stderr flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/mkbin-edit"

# Creates a fake editor at $BATS_TEST_TMPDIR/fake-editor that records its
# arguments (one per line) to $BATS_TEST_TMPDIR/editor-args.txt, then sets
# $FAKE_EDITOR. BATS_TEST_TMPDIR is unique per test so each test is isolated.
function create_fake_editor() {
  local editor_path="$BATS_TEST_TMPDIR/fake-editor"
  # Single-quoted 'EOF' so $@ is not expanded by the current shell
  cat <<'EOF' > "$editor_path"
#!/usr/bin/env bash
set -euo pipefail
LOG="${0%/*}/editor-args.txt"
for arg in "$@"; do
  echo "$arg" >> "$LOG"
done
EOF
  chmod +x "$editor_path"
  FAKE_EDITOR="$editor_path"
}

# Assert that the lines of $content match exactly the expected lines given as
# remaining arguments, in order.
#
# Usage: assert_lines "$content" "expected line 1" "expected line 2" ...
function assert_lines() {
  local content="$1"; shift
  local expected=("$@")
  local actual
  mapfile -t actual <<< "$content"
  # mapfile from a here-string always appends a trailing empty element if
  # content ends with a newline; remove it to match what the user passed.
  if [[ "${actual[-1]}" == "" ]]; then
    unset 'actual[-1]'
  fi

  if (( ${#actual[@]} != ${#expected[@]} )); then
    echo "assert_lines: expected ${#expected[@]} lines, got ${#actual[@]}" >&2
    return 1
  fi

  local i
  for i in "${!expected[@]}"; do
    if [[ "${actual[$i]}" != "${expected[$i]}" ]]; then
      echo "assert_lines: line $i mismatch" >&2
      echo "  expected: '${expected[$i]}'" >&2
      echo "  actual:   '${actual[$i]}'" >&2
      return 1
    fi
  done
}

# ------------------------------------------------------------------------------

function setup() {
  create_fake_editor
  export EDITOR="$FAKE_EDITOR"
}

# ------------------------------------------------------------------------------
# Tests: helpers

@test "helpers: assert_lines passes when lines match" {
  run -0 assert_lines $'foo\nbar' "foo" "bar"
}

@test "helpers: assert_lines fails on wrong number of lines" {
  run -1 assert_lines $'foo\nbar' "foo"
}

@test "helpers: assert_lines fails on wrong content" {
  run -1 assert_lines $'foo\nbar' "foo" "other"
}

# ------------------------------------------------------------------------------
# Tests: usage / error handling

@test "usage: prints usage to stderr and exits 1 when no argument given" {
  run -1 --separate-stderr "$SCRIPT_PATH"
  [[ "$stderr" == "USAGE: mkbin-edit <file> [<args for \$EDITOR>]" ]]
}

# ------------------------------------------------------------------------------
# Tests: file creation

@test "file: creates file and makes it executable" {
  local target="$BATS_TEST_TMPDIR/new-script.sh"

  run -0 "$SCRIPT_PATH" "$target"

  [[ -f "$target" ]]
  [[ -x "$target" ]]
}

@test "file: works when target file already exists" {
  local target="$BATS_TEST_TMPDIR/existing.sh"
  echo "existing content" > "$target"

  run -0 "$SCRIPT_PATH" "$target"

  [[ -f "$target" ]]
  [[ -x "$target" ]]
}

# ------------------------------------------------------------------------------
# Tests: editor invocation

@test "cli: opens editor with the target file as only argument" {
  local target="$BATS_TEST_TMPDIR/my-script.sh"

  run -0 "$SCRIPT_PATH" "$target"

  local recorded_args
  recorded_args=$(cat "$BATS_TEST_TMPDIR/editor-args.txt")
  assert_lines "$recorded_args" "$target"
}

@test "cli: passes extra arguments to the editor after the file" {
  local target="$BATS_TEST_TMPDIR/my-script.sh"

  run -0 "$SCRIPT_PATH" "$target" +"setf sh"

  local recorded_args
  recorded_args=$(cat "$BATS_TEST_TMPDIR/editor-args.txt")
  assert_lines "$recorded_args" "$target" "+setf sh"
}

@test "cli: falls back to nvim when EDITOR is unset" {
  # Create a fake nvim in a temp bin dir and prepend it to PATH
  local fake_bin_dir="$BATS_TEST_TMPDIR/fake-bin"
  mkdir -p "$fake_bin_dir"
  cat <<'EOF' > "$fake_bin_dir/nvim"
#!/usr/bin/env bash
set -euo pipefail
LOG="${0%/*}/nvim-args.txt"
for arg in "$@"; do
  echo "$arg" >> "$LOG"
done
EOF
  chmod +x "$fake_bin_dir/nvim"

  local target="$BATS_TEST_TMPDIR/no-editor.sh"

  PATH="$fake_bin_dir:$PATH" EDITOR="" run -0 "$SCRIPT_PATH" "$target"

  local recorded_args
  recorded_args=$(cat "$fake_bin_dir/nvim-args.txt")
  assert_lines "$recorded_args" "$target"
}
