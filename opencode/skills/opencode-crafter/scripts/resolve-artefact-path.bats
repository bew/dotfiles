# Test suite for `resolve-artefact-path` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for --separate-stderr flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/resolve-artefact-path"

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
    [[ "$stderr" == *"--get"* ]]
    [[ "$stderr" == *"--artefact"* ]]
    [[ "$stderr" == *"opencode:global"* ]]
    [[ "$stderr" == *"agents:project"* ]]
}

# ------------------------------------------------------------------------------
# Tests: CLI errors

@test "cli: no args prints usage to stderr and exits 1" {
    run -1 --separate-stderr "$SCRIPT_PATH"
    [[ "$stderr" == *"Usage:"* ]]
}

@test "cli: unknown option exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --badoption
    [[ "$stderr" == *"Error: unknown option: --badoption"* ]]
}

@test "cli: unknown scope exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --get badscope
    [[ "$stderr" == *"Error: unknown scope: badscope"* ]]
}

@test "cli: non-existent cwd exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd "$BATS_TEST_TMPDIR/does-not-exist"
    [[ "$stderr" == *"Error: not a directory"* ]]
}

@test "cli: --get without argument exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --get
    [[ "$stderr" == *"Error: --get requires a scope argument"* ]]
}

@test "cli: --artefact without path argument exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --artefact
    [[ "$stderr" == *"Error: --artefact requires a path argument"* ]]
}

@test "cli: --cwd without argument exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd
    [[ "$stderr" == *"Error: --cwd requires a directory argument"* ]]
}

# ------------------------------------------------------------------------------
# Tests: opencode:global — cwd inside dotfiles (shortest path = ~/.dot/opencode)

@test "get opencode:global: cwd inside dotfiles prints ~/.dot/opencode" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    local subdir="$dotfiles/some/nested/dir"
    mkdir -p "$subdir"
    ln -s "$dotfiles" "$HOME/.dot"

    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd "$subdir"
    # ~/.dot/opencode is shorter than the absolute path
    [[ "$output" == "~/.dot/opencode" ]]
}

@test "get opencode:global: cwd at dotfiles root itself prints relative path (shorter than ~/.dot alias)" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    mkdir -p "$dotfiles"
    ln -s "$dotfiles" "$HOME/.dot"

    # From dotfiles root: relative = "./opencode" (11 chars) < "~/.dot/opencode" (16 chars)
    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd "$dotfiles"
    [[ "$output" == "./opencode" ]]
}

# ------------------------------------------------------------------------------
# Tests: opencode:global — cwd outside dotfiles (fallback)

@test "get opencode:global: cwd not in dotfiles outputs relative path (./home/.config/opencode)" {
    # No ~/.dot symlink. HOME=$BATS_TEST_TMPDIR/home, cwd=$BATS_TEST_TMPDIR.
    # Relative = ./home/.config/opencode — shorter than absolute.
    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd "$BATS_TEST_TMPDIR"
    [[ "$output" == "./home/.config/opencode" ]]
}

@test "get opencode:global: ~/.dot missing outputs relative path (./home/.config/opencode)" {
    # Same layout, no ~/.dot at all.
    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd "$BATS_TEST_TMPDIR"
    [[ "$output" == "./home/.config/opencode" ]]
}

@test "get opencode:global: ~/.config/opencode need not exist — path still printed" {
    # No ~/.dot, no ~/.config/opencode dir — still exits 0 and prints shortest path.
    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd "$BATS_TEST_TMPDIR"
    [[ -n "$output" ]]
    [[ ! -d "$HOME/.config/opencode" ]]
}

@test "get opencode:global: defaulting cwd to PWD works (no --cwd)" {
    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:global
    [[ -n "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: agents:global — alias for opencode:global

@test "get agents:global: same output as opencode:global from same cwd" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    local subdir="$dotfiles/some/nested/dir"
    mkdir -p "$subdir"
    ln -s "$dotfiles" "$HOME/.dot"

    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:global --cwd "$subdir"
    local oc_out="$output"

    run -0 --separate-stderr "$SCRIPT_PATH" --get agents:global --cwd "$subdir"
    [[ "$output" == "$oc_out" ]]
}

# ------------------------------------------------------------------------------
# Tests: opencode:project

@test "get opencode:project: cwd inside git repo outputs relative path (../../.opencode)" {
    # cwd=$repo/sub/dir, target=$repo/.opencode — relative is ../../.opencode, shorter than absolute.
    local repo="$BATS_TEST_TMPDIR/my-repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "t@t"
    git -C "$repo" config user.name "T"

    local subdir="$repo/sub/dir"
    mkdir -p "$subdir"

    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:project --cwd "$subdir"
    [[ "$output" == "../../.opencode" ]]
}

@test "get opencode:project: cwd at git root outputs ./.opencode (relative is shortest)" {
    local repo="$BATS_TEST_TMPDIR/my-repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "t@t"
    git -C "$repo" config user.name "T"

    run -0 --separate-stderr "$SCRIPT_PATH" --get opencode:project --cwd "$repo"
    # From the repo root, "./.opencode" (11 chars) is always shorter than the absolute path.
    [[ "$output" == "./.opencode" ]]
}

@test "get opencode:project: cwd outside any git repo exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --get opencode:project --cwd "$BATS_TEST_TMPDIR"
    [[ "$stderr" == *"Error:"* ]]
    [[ "$stderr" == *"not inside a git repository"* ]]
}

# ------------------------------------------------------------------------------
# Tests: agents:project

@test "get agents:project: cwd at git root outputs ./.agents" {
    local repo="$BATS_TEST_TMPDIR/my-repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "t@t"
    git -C "$repo" config user.name "T"

    run -0 --separate-stderr "$SCRIPT_PATH" --get agents:project --cwd "$repo"
    [[ "$output" == "./.agents" ]]
}

@test "get agents:project: cwd inside git repo outputs relative path (../../.agents)" {
    local repo="$BATS_TEST_TMPDIR/my-repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "t@t"
    git -C "$repo" config user.name "T"

    local subdir="$repo/sub/dir"
    mkdir -p "$subdir"

    run -0 --separate-stderr "$SCRIPT_PATH" --get agents:project --cwd "$subdir"
    [[ "$output" == "../../.agents" ]]
}

@test "get agents:project: dotfiles git repo uses ~/.dot/.agents alias when shortest" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    mkdir -p "$dotfiles"
    git -C "$dotfiles" init -q
    git -C "$dotfiles" config user.email "t@t"
    git -C "$dotfiles" config user.name "T"
    ln -s "$dotfiles" "$HOME/.dot"

    # Use a deeply nested subdir so absolute and relative are long, making ~/.dot/.agents (13 chars) win.
    local subdir="$dotfiles/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p"
    mkdir -p "$subdir"

    run -0 --separate-stderr "$SCRIPT_PATH" --get agents:project --cwd "$subdir"
    [[ "$output" == "~/.dot/.agents" ]]
}

@test "get agents:project: cwd outside any git repo exits 1 with error" {
    run -1 --separate-stderr "$SCRIPT_PATH" --get agents:project --cwd "$BATS_TEST_TMPDIR"
    [[ "$stderr" == *"Error:"* ]]
    [[ "$stderr" == *"not inside a git repository"* ]]
}

# ------------------------------------------------------------------------------
# Tests: artefact mode (path shortening)

@test "artefact: absolute path inside dotfiles is shortened to ~/.dot/… alias" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    mkdir -p "$dotfiles/skills/my-skill"
    ln -s "$dotfiles" "$HOME/.dot"

    local abs_path="$dotfiles/skills/my-skill/SKILL.md"

    # cwd is /tmp — relative would be long, ~/.dot alias wins
    run -0 --separate-stderr "$SCRIPT_PATH" --artefact "$abs_path" --cwd "$BATS_TEST_TMPDIR"
    [[ "$output" == "~/.dot/skills/my-skill/SKILL.md" ]]
}

@test "artefact: path near cwd is shortened to relative" {
    local dotfiles="$BATS_TEST_TMPDIR/dotfiles"
    mkdir -p "$dotfiles/skills/my-skill"
    ln -s "$dotfiles" "$HOME/.dot"

    local abs_path="$dotfiles/skills/my-skill/SKILL.md"

    # cwd at dotfiles root — relative "./skills/my-skill/SKILL.md" (26 chars) < "~/.dot/skills/my-skill/SKILL.md" (31 chars)
    run -0 --separate-stderr "$SCRIPT_PATH" --artefact "$abs_path" --cwd "$dotfiles"
    [[ "$output" == "./skills/my-skill/SKILL.md" ]]
}

@test "artefact: path not under dotfiles outputs relative or absolute (shortest)" {
    # No ~/.dot. cwd=$BATS_TEST_TMPDIR, path=$BATS_TEST_TMPDIR/some/file.md
    local target="$BATS_TEST_TMPDIR/some/file.md"

    run -0 --separate-stderr "$SCRIPT_PATH" --artefact "$target" --cwd "$BATS_TEST_TMPDIR"
    [[ "$output" == "./some/file.md" ]]
}
