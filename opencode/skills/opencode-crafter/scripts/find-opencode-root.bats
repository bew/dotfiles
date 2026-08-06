# Test suite for `find-opencode-root` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for --separate-stderr flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/find-opencode-root"

# All tests override HOME to a controlled tmp dir for isolation.
# Tests that need ~/.dot or ~/.config/opencode create them explicitly.
function setup() {
    HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    export HOME
    unset XDG_CONFIG_HOME
}

# ------------------------------------------------------------------------------
# Tests: usage / help

@test "usage: --help prints usage to stderr and exits 0" {
    run -0 --separate-stderr "$SCRIPT_PATH" --help
    [[ "$stderr" == *"Usage:"* ]]
    [[ "$stderr" == *"global"* ]]
    [[ "$stderr" == *"project"* ]]
}

# ------------------------------------------------------------------------------
# Tests: CLI errors

@test "cli: no args prints usage to stderr and exits 1" {
    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"Usage:"* ]]
}

@test "cli: too many args exits 1 with usage" {
    run -1 --separate-stderr "$SCRIPT_PATH" global /tmp extra
    [[ "$stderr" == *"Usage:"* ]]
}

@test "cli: unknown scope exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" badscope
    [[ "$stderr" == *"Error: unknown scope: badscope"* ]]
}

@test "cli: non-existent cwd exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" global "$BATS_TEST_TMPDIR/does-not-exist"
    [[ "$stderr" == *"Error: not a directory"* ]]
}

# ------------------------------------------------------------------------------
# Tests: global scope — cwd inside dotfiles

@test "global: cwd inside dotfiles prints <dotfiles_root>/opencode" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    local subdir="$dotfiles/some/nested/dir"
    mkdir -p "$subdir"
    ln -s "$dotfiles" "$HOME/.dot"

    run -0 --separate-stderr "$SCRIPT_PATH" global "$subdir"
    [[ "$output" == "$(realpath "$dotfiles")/opencode" ]]
}

@test "global: cwd at dotfiles root itself prints <dotfiles_root>/opencode" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    mkdir -p "$dotfiles"
    ln -s "$dotfiles" "$HOME/.dot"

    run -0 --separate-stderr "$SCRIPT_PATH" global "$dotfiles"
    [[ "$output" == "$(realpath "$dotfiles")/opencode" ]]
}

# ------------------------------------------------------------------------------
# Tests: global scope — cwd outside dotfiles (fallback)

@test "global: cwd not in dotfiles prints ~/.config/opencode" {
    # No ~/.dot symlink → always falls back
    run -0 --separate-stderr "$SCRIPT_PATH" global "$BATS_TEST_TMPDIR"
    [[ "$output" == "$HOME/.config/opencode" ]]
}

@test "global: ~/.dot missing prints ~/.config/opencode" {
    # HOME has no .dot symlink at all
    run -0 --separate-stderr "$SCRIPT_PATH" global "$BATS_TEST_TMPDIR"
    [[ "$output" == "$HOME/.config/opencode" ]]
}

@test "global: ~/.config/opencode need not exist — path still printed" {
    # No ~/.dot, no ~/.config/opencode dir — still exits 0 and prints it
    run -0 --separate-stderr "$SCRIPT_PATH" global "$BATS_TEST_TMPDIR"
    [[ "$output" == "$HOME/.config/opencode" ]]
    [[ ! -d "$HOME/.config/opencode" ]]
}

@test "global: defaulting cwd to PWD works (no cwd arg)" {
    run -0 --separate-stderr "$SCRIPT_PATH" global
    [[ "$output" == "$HOME/.config/opencode" ]]
}

# ------------------------------------------------------------------------------
# Tests: project scope

@test "project: cwd inside git repo prints <git_root>/.opencode" {
    local repo="$BATS_TEST_TMPDIR/my-repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "t@t"
    git -C "$repo" config user.name "T"

    local subdir="$repo/sub/dir"
    mkdir -p "$subdir"

    run -0 --separate-stderr "$SCRIPT_PATH" project "$subdir"
    [[ "$output" == "$(realpath "$repo")/.opencode" ]]
}

@test "project: cwd at git root itself prints <git_root>/.opencode" {
    local repo="$BATS_TEST_TMPDIR/my-repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "t@t"
    git -C "$repo" config user.name "T"

    run -0 --separate-stderr "$SCRIPT_PATH" project "$repo"
    [[ "$output" == "$(realpath "$repo")/.opencode" ]]
}

@test "project: cwd outside any git repo exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" project "$BATS_TEST_TMPDIR"
    [[ "$stderr" == *"Error:"* ]]
    [[ "$stderr" == *"not inside a git repository"* ]]
}
