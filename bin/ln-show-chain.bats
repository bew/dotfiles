# Test suite for `ln-show-chain` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for --separate-stderr flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/ln-show-chain"

# ------------------------------------------------------------------------------
# Tests: usage / help

@test "usage: no args prints usage to stderr and exits 0" {
  run -0 --separate-stderr "$SCRIPT_PATH"
  [[ "$stderr" == "USAGE:"* ]]
}

@test "usage: -h and --help prints usage to stderr and exits 0" {
  run -0 --separate-stderr "$SCRIPT_PATH" -h
  [[ "$stderr" == "USAGE:"* ]]

  run -0 --separate-stderr "$SCRIPT_PATH" --help
  [[ "$stderr" == "USAGE:"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error handling

@test "error: exits 1 and reports missing binary" {
  run -1 --separate-stderr "$SCRIPT_PATH" does-not-exist-binary-xyz
  [[ "$stderr" == "ERROR: 'does-not-exist-binary-xyz' is not in path :/" ]]
}

@test "error: hints to use ./ prefix when name matches a local file" {
  local target="$BATS_TEST_TMPDIR/local-tool"
  touch "$target"

  # Run with the basename only (not a path)
  # FROM the tmp dir, so the file exists in cwd
  cd "$BATS_TEST_TMPDIR"
  run -1 --separate-stderr "$SCRIPT_PATH" local-tool

  [[ "${stderr_lines[0]}" == "ERROR: 'local-tool' is not in path :/" ]]
  [[ "${stderr_lines[1]}" == "  Use './local-tool' to resolve a local path" ]]
}

# ------------------------------------------------------------------------------
# Tests: path resolution

@test "path: resolves an absolute path with no symlinks" {
  local target="$BATS_TEST_TMPDIR/plain-file"
  printf "hello" > "$target"

  run -0 --keep-empty-lines "$SCRIPT_PATH" "$target"

  [[ "${lines[0]}" == "Path: $target" ]]
  [[ "${lines[1]}" == "" ]]
  [[ "${lines[2]}" == "Target file info:" ]]
  [[ "${lines[3]}" == "ASCII text, with no line terminators" ]]
}

@test "path: resolves chained relative symlinks (shown with ./ prefix)" {
  local chain_dir="$BATS_TEST_TMPDIR/chain"
  mkdir -p "$chain_dir"
  # Create: outer-link -> inner-link -> target.txt
  printf "demo" > "$chain_dir/target.txt"
  ln -s target.txt "$chain_dir/inner-link"
  ln -s inner-link "$chain_dir/outer-link"

  # Run from inside chain_dir so relative paths resolve and are shown with ./
  run -0 --keep-empty-lines bash -c "cd '$chain_dir' && '$SCRIPT_PATH' ./outer-link"

  [[ "${lines[0]}" == "Path: ./outer-link (link)" ]]
  [[ "${lines[1]}" == " -->  ./inner-link (link)" ]]
  [[ "${lines[2]}" == " -->  ./target.txt" ]]
  [[ "${lines[3]}" == "" ]]
  [[ "${lines[4]}" == "Target file info:" ]]
  [[ "${lines[5]}" == "ASCII text, with no line terminators" ]]
}

@test "path: resolves an absolute symlink to a plain file" {
  local target="$BATS_TEST_TMPDIR/real-file"
  local link="$BATS_TEST_TMPDIR/the-link"
  printf 'data' > "$target"
  ln -s "$target" "$link"

  run -0 --keep-empty-lines "$SCRIPT_PATH" "$link"

  [[ "${lines[0]}" == "Path: $link (link)" ]]
  [[ "${lines[1]}" == " -->  $target" ]]
  [[ "${lines[2]}" == "" ]]
  [[ "${lines[3]}" == "Target file info:" ]]
  [[ "${lines[4]}" == "ASCII text, with no line terminators" ]]
}

# ------------------------------------------------------------------------------
# Tests: binary resolution from PATH

@test "cli: resolves a binary from PATH" {
  local fake_bin_dir="$BATS_TEST_TMPDIR/bin"
  local fake_bin="$fake_bin_dir/fakecmd"
  mkdir -p "$fake_bin_dir"
  cat <<'EOF' > "$fake_bin"
#!/usr/bin/env bash
exit 42
EOF
  chmod +x "$fake_bin"

  PATH="$fake_bin_dir:$PATH" run -0 --keep-empty-lines "$SCRIPT_PATH" fakecmd

  [[ "${lines[0]}" == "For executable 'fakecmd'" ]]
  [[ "${lines[1]}" == "Path: $fake_bin (exe)" ]]
  [[ "${lines[2]}" == "" ]]
  [[ "${lines[3]}" == "Target file info:" ]]
  [[ "${lines[4]}" == "Bourne-Again shell script, ASCII text executable" ]]
}
