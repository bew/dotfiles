# Test suite for `opencode-artefacts-status` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: bats $this_file [--filter foobar]

# Require BATS 1.5.0+ for --separate-stderr flag support on `run`
bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/opencode-artefacts-status"

# Setup a fake git repo in BATS_TEST_TMPDIR with the opencode/ artefact layout.
# Creates a git repo, adds a base commit with some artefacts, then optionally
# leaves extra files uncommitted so they show up as changes.
#
# Layout created:
#   opencode/
#     skills/my-skill/SKILL.md         (committed)
#     skills/wip-skill/SKILL.md        (uncommitted: new file)
#     commands/my-cmd.md               (committed)
#     commands/wip-cmd.md              (uncommitted: new file)
#     agents/my-agent.md               (committed)
#     snippets/my-snippet.md           (committed)
#     plugins/file-plugin.js           (committed, single-file plugin)
#     plugins/dir-plugin/index.js      (committed, dir-based plugin)
function setup() {
    FAKE_ROOT="$BATS_TEST_TMPDIR/dotfiles"
    mkdir -p "$FAKE_ROOT"

    # Init a real git repo (needed for `git status`)
    git -C "$FAKE_ROOT" init -q
    git -C "$FAKE_ROOT" config user.email "test@test"
    git -C "$FAKE_ROOT" config user.name "Test"

    # Create committed artefacts
    mkdir -p "$FAKE_ROOT/opencode/skills/my-skill"
    echo "# my-skill" > "$FAKE_ROOT/opencode/skills/my-skill/SKILL.md"

    mkdir -p "$FAKE_ROOT/opencode/commands"
    echo "# my-cmd" > "$FAKE_ROOT/opencode/commands/my-cmd.md"

    mkdir -p "$FAKE_ROOT/opencode/agents"
    echo "# my-agent" > "$FAKE_ROOT/opencode/agents/my-agent.md"

    mkdir -p "$FAKE_ROOT/opencode/snippets"
    echo "# my-snippet" > "$FAKE_ROOT/opencode/snippets/my-snippet.md"

    mkdir -p "$FAKE_ROOT/opencode/plugins"
    echo "// file-plugin" > "$FAKE_ROOT/opencode/plugins/file-plugin.js"
    mkdir -p "$FAKE_ROOT/opencode/plugins/dir-plugin"
    echo "// dir-plugin" > "$FAKE_ROOT/opencode/plugins/dir-plugin/index.js"

    git -C "$FAKE_ROOT" add .
    git -C "$FAKE_ROOT" commit -q -m "base"

    # Create uncommitted artefacts (new, untracked)
    mkdir -p "$FAKE_ROOT/opencode/skills/wip-skill"
    echo "# wip-skill" > "$FAKE_ROOT/opencode/skills/wip-skill/SKILL.md"

    echo "# wip-cmd" > "$FAKE_ROOT/opencode/commands/wip-cmd.md"

    export OC_ARTEFACTS_GIT_ROOT="$FAKE_ROOT"
}

# Helper: run the script with success expected, capturing stdout and stderr separately
function run_script() {
    run -0 --separate-stderr "$SCRIPT_PATH" "$@"
}

# Helper: run the script expecting failure
function run_script_failed() {
    run -1 --separate-stderr "$SCRIPT_PATH" "$@"
}

# Strip ANSI escape codes from output for clean text matching
function strip_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# ------------------------------------------------------------------------------
# Tests: --list-types

@test "list-types: prints all known types with descriptions" {
    run_script --list-types
    [[ "$output" == *"skills"* ]]
    [[ "$output" == *"commands"* ]]
    [[ "$output" == *"agents"* ]]
    [[ "$output" == *"snippets"* ]]
    [[ "$output" == *"plugins"* ]]
    # Each line should have a description (non-empty text after the type name)
    local skills_line
    skills_line="$(echo "$output" | grep "skills")"
    [[ "$skills_line" == *"skills"*"  "* ]]  # name + padding + description
}

@test "list-types: no git calls needed (works without repo)" {
    unset OC_ARTEFACTS_GIT_ROOT
    # Point FILE_PWD away from any git repo by overriding git root to a non-repo dir
    # --list-types should exit before ever calling git
    run -0 --separate-stderr "$SCRIPT_PATH" --list-types
    [[ "$output" == *"skills"* ]]
}

# ------------------------------------------------------------------------------
# Tests: defaults (all types, no filter)

@test "defaults: lists artefacts from all types" {
    run_script
    local clean
    clean="$(strip_ansi "$output")"
    [[ "$clean" == *"skills"*"my-skill"* ]]
    [[ "$clean" == *"commands"*"my-cmd"* ]]
    [[ "$clean" == *"agents"*"my-agent"* ]]
    [[ "$clean" == *"snippets"*"my-snippet"* ]]
    [[ "$clean" == *"plugins"*"file-plugin"* ]]
}

@test "defaults: committed artefacts show no WIP marker" {
    run_script
    local clean
    clean="$(strip_ansi "$output")"
    # my-skill is committed — should show ---- not * WIP
    local my_skill_line
    my_skill_line="$(echo "$clean" | grep "my-skill")"
    [[ "$my_skill_line" == *"----"* ]]
    [[ "$my_skill_line" != *"WIP"* ]]
}

@test "defaults: uncommitted artefacts show WIP marker" {
    run_script
    local clean
    clean="$(strip_ansi "$output")"
    local wip_skill_line wip_cmd_line
    wip_skill_line="$(echo "$clean" | grep "wip-skill")"
    wip_cmd_line="$(echo "$clean" | grep "wip-cmd")"
    [[ "$wip_skill_line" == *"* WIP"* ]]
    [[ "$wip_cmd_line" == *"* WIP"* ]]
}

@test "defaults: no output when no artefact dirs exist" {
    # Point to a repo with no opencode/ subdirs
    local empty_root="$BATS_TEST_TMPDIR/empty-dotfiles"
    mkdir -p "$empty_root"
    git -C "$empty_root" init -q
    git -C "$empty_root" config user.email "t@t" && git -C "$empty_root" config user.name "t"
    touch "$empty_root/.gitkeep"
    git -C "$empty_root" add . && git -C "$empty_root" commit -q -m "init"

    OC_ARTEFACTS_GIT_ROOT="$empty_root" run -0 --separate-stderr "$SCRIPT_PATH"
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: --wip flag

@test "wip: only shows artefacts with uncommitted changes" {
    run_script --wip
    local clean
    clean="$(strip_ansi "$output")"
    # WIP artefacts must appear
    [[ "$clean" == *"wip-skill"* ]]
    [[ "$clean" == *"wip-cmd"* ]]
    # Clean artefacts must not appear
    [[ "$clean" != *"my-skill"* ]]
    [[ "$clean" != *"my-cmd"* ]]
    [[ "$clean" != *"my-agent"* ]]
}

@test "wip: all lines have WIP marker" {
    run_script --wip
    local clean
    clean="$(strip_ansi "$output")"
    # Every non-empty line must contain "* WIP"
    while IFS= read -r line; do
        [[ -z "$line" ]] || [[ "$line" == *"* WIP"* ]]
    done <<< "$clean"
}

@test "wip: empty output when nothing is uncommitted" {
    # Commit the wip artefacts so nothing is dirty
    git -C "$FAKE_ROOT" add .
    git -C "$FAKE_ROOT" commit -q -m "commit wip"

    run_script --wip
    [[ -z "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: positional type filter

@test "type-filter: single type limits output" {
    run_script skills
    local clean
    clean="$(strip_ansi "$output")"
    [[ "$clean" == *"skills"* ]]
    [[ "$clean" != *"commands"* ]]
    [[ "$clean" != *"agents"* ]]
}

@test "type-filter: multiple types listed together" {
    run_script skills commands
    local clean
    clean="$(strip_ansi "$output")"
    [[ "$clean" == *"skills"* ]]
    [[ "$clean" == *"commands"* ]]
    [[ "$clean" != *"agents"* ]]
    [[ "$clean" != *"snippets"* ]]
}

@test "type-filter: combined with --wip" {
    run_script --wip skills
    local clean
    clean="$(strip_ansi "$output")"
    [[ "$clean" == *"wip-skill"* ]]
    [[ "$clean" != *"wip-cmd"* ]]   # commands excluded by type filter
    [[ "$clean" != *"my-skill"* ]]  # clean skill excluded by --wip
}

# ------------------------------------------------------------------------------
# Tests: error handling

@test "error: unknown type gives error message" {
    run_script_failed badtype
    [[ "$stderr" == *"Unknown artefact type: 'badtype'"* ]]
    [[ "$stderr" == *"Known types:"* ]]
}

@test "error: error message lists all known types" {
    run_script_failed badtype
    [[ "$stderr" == *"skills"* ]]
    [[ "$stderr" == *"commands"* ]]
    [[ "$stderr" == *"agents"* ]]
}

# ------------------------------------------------------------------------------
# Tests: skills are dir-based (whole dir = one artefact)

@test "skills: changing a nested file marks the skill as WIP" {
    # Modify a file inside an already-committed skill
    echo "modified" >> "$FAKE_ROOT/opencode/skills/my-skill/SKILL.md"

    run_script skills
    local clean
    clean="$(strip_ansi "$output")"
    local my_skill_line
    my_skill_line="$(echo "$clean" | grep "my-skill")"
    [[ "$my_skill_line" == *"* WIP"* ]]
}

@test "skills: adding a sub-file to committed skill marks it WIP" {
    echo "# extra" > "$FAKE_ROOT/opencode/skills/my-skill/extra.md"

    run_script skills
    local clean
    clean="$(strip_ansi "$output")"
    local my_skill_line
    my_skill_line="$(echo "$clean" | grep "my-skill")"
    [[ "$my_skill_line" == *"* WIP"* ]]
}

@test "skills: clean skill is not WIP even when other skills are" {
    run_script skills
    local clean
    clean="$(strip_ansi "$output")"
    local my_skill_line
    my_skill_line="$(echo "$clean" | grep "my-skill")"
    [[ "$my_skill_line" == *"----"* ]]
}

# ------------------------------------------------------------------------------
# Tests: plugins are mixed (file or dir per artefact)

@test "plugins: single-file plugin appears without extension" {
    run_script plugins
    local clean
    clean="$(strip_ansi "$output")"
    [[ "$clean" == *"file-plugin"* ]]
    # extension must be stripped
    [[ "$clean" != *"file-plugin.js"* ]]
}

@test "plugins: dir-based plugin appears by dir name" {
    run_script plugins
    local clean
    clean="$(strip_ansi "$output")"
    [[ "$clean" == *"dir-plugin"* ]]
}

@test "plugins: modifying file-plugin marks it WIP" {
    echo "changed" >> "$FAKE_ROOT/opencode/plugins/file-plugin.js"

    run_script plugins
    local clean
    clean="$(strip_ansi "$output")"
    local line
    line="$(echo "$clean" | grep "file-plugin")"
    [[ "$line" == *"* WIP"* ]]
}

@test "plugins: modifying a file inside dir-plugin marks it WIP" {
    echo "changed" >> "$FAKE_ROOT/opencode/plugins/dir-plugin/index.js"

    run_script plugins
    local clean
    clean="$(strip_ansi "$output")"
    local line
    line="$(echo "$clean" | grep "dir-plugin")"
    [[ "$line" == *"* WIP"* ]]
}

@test "plugins: new dir-plugin (uncommitted) shows WIP" {
    mkdir -p "$FAKE_ROOT/opencode/plugins/wip-dir-plugin"
    echo "// new" > "$FAKE_ROOT/opencode/plugins/wip-dir-plugin/index.js"

    run_script plugins
    local clean
    clean="$(strip_ansi "$output")"
    local line
    line="$(echo "$clean" | grep "wip-dir-plugin")"
    [[ "$line" == *"* WIP"* ]]
}

@test "plugins: clean plugin is not WIP when others are dirty" {
    echo "changed" >> "$FAKE_ROOT/opencode/plugins/file-plugin.js"

    run_script plugins
    local clean
    clean="$(strip_ansi "$output")"
    local dir_plugin_line
    dir_plugin_line="$(echo "$clean" | grep "dir-plugin")"
    [[ "$dir_plugin_line" == *"----"* ]]
}
