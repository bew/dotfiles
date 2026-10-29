# Test suite for `manage-spec` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/manage-spec"

LOADER_IMPORTANT_LINE="> IMPORTANT: Before any drafting/planning/editing of this spec,"
LOADER_ACTION_LINE="> agents MUST load one of the spec-writing skills first."
EXPLO_POINTER_LINE="> the \`design-exploration\` skill owns it until the spec is promoted to draft."

function setup() {
    # Resolve symlinks so paths match what the script derives from the real cwd.
    export PROJECT_DIR="$(cd "$BATS_TEST_TMPDIR" && pwd -P)/project"
    mkdir -p "$PROJECT_DIR"
}

# Print the canonical spec fixture for a tag: the loader paragraph is present for
# every tag except READY, matching the skill contract.
function expected_spec_content() {
    local tag="$1"
    local title="${2:-Sample Spec}"

    printf '# [%s] %s\n\n' "$tag" "$title"
    if [[ "$tag" != "READY" ]]; then
        printf '%s\n' "$LOADER_IMPORTANT_LINE"
        printf '%s\n\n' "$LOADER_ACTION_LINE"
    fi
    printf '## Introduction\n\nBody text.\n'
}

# Print the frontmatter block `init` writes, carrying the given timestamp.
function expected_frontmatter_block() {
    local stamp="$1"

    printf -- '---\ncreated-at: %s\n---\n\n' "$stamp"
}

# Write <PROJECT_DIR>/<dir>/SPEC.md holding the canonical fixture for the given tag.
function setup_spec() {
    local dir_name="$1"
    local tag="$2"
    local title="${3:-Sample Spec}"
    local specdir="$PROJECT_DIR/$dir_name"

    mkdir -p "$specdir"
    expected_spec_content "$tag" "$title" > "$specdir/SPEC.md"
}

# Print the canonical legacy fixture: DISCOVERY.md still carries the tag and the loader.
function expected_legacy_discovery_content() {
    local tag="$1"
    local title="${2:-Sample Spec}"

    printf '# [%s] %s\n\n' "$tag" "$title"
    printf '%s\n' "$LOADER_IMPORTANT_LINE"
    printf '%s\n' "$LOADER_ACTION_LINE"
    if [[ "$tag" == "EXPLO" ]]; then
        printf '>\n> IMPORTANT: This spec is still in exploration.\n'
        printf '> Exploration material lives in `EXPLO-BRIEF.md`;\n'
        printf '%s\n' "$EXPLO_POINTER_LINE"
    fi
    printf '\nNotes.\n'
}

# Write <PROJECT_DIR>/<dir>/DISCOVERY.md holding the legacy tag-carrying fixture.
function setup_legacy_discovery_spec() {
    local dir_name="$1"
    local tag="$2"
    local title="${3:-Sample Spec}"
    local specdir="$PROJECT_DIR/$dir_name"

    mkdir -p "$specdir"
    expected_legacy_discovery_content "$tag" "$title" > "$specdir/DISCOVERY.md"
}

# Initialise a git repo in PROJECT_DIR and commit everything currently there.
function setup_git_repo() {
    git -C "$PROJECT_DIR" init -q
    git -C "$PROJECT_DIR" config user.email "test@example.com"
    git -C "$PROJECT_DIR" config user.name "Test"
    git -C "$PROJECT_DIR" add -A
    git -C "$PROJECT_DIR" commit -qm "initial"
}

# Assert stdout contains the phrase, which must carry the values under test.
function assert_output_contains() {
    local phrase="$1"

    if [[ "$output" != *"$phrase"* ]]; then
        printf 'stdout missing phrase: %s\n--- actual ---\n%s\n---\n' "$phrase" "$output" >&3
        return 1
    fi
}

# Assert stderr contains the phrase, which must carry the values under test.
function assert_stderr_contains() {
    local phrase="$1"

    if [[ "$stderr" != *"$phrase"* ]]; then
        printf 'stderr missing phrase: %s\n--- actual ---\n%s\n---\n' "$phrase" "$stderr" >&3
        return 1
    fi
}

# Assert a file contains the literal phrase.
function assert_file_contains() {
    local filepath="$1"
    local phrase="$2"

    if ! grep -Fq -- "$phrase" "$filepath"; then
        printf 'file missing phrase: %s\n  in: %s\n' "$phrase" "$filepath" >&3
        return 1
    fi
}

# Assert a file does not contain the literal phrase.
function assert_file_lacks() {
    local filepath="$1"
    local phrase="$2"

    if grep -Fq -- "$phrase" "$filepath"; then
        printf 'file should not contain: %s\n  in: %s\n' "$phrase" "$filepath" >&3
        return 1
    fi
}

# Assert stdout is empty, so a failure never reports success.
function assert_output_empty() {
    if [[ -n "$output" ]]; then
        printf 'stdout should be empty\n--- actual ---\n%s\n---\n' "$output" >&3
        return 1
    fi
}

# Assert stdout names the expected lifecycle state.
function assert_state() {
    local state="$1"

    assert_output_contains "State: $state"
}

# Assert the vars block header and every bullet it lists, each carrying a value.
function assert_session_vars() {
    local header="$1"
    shift

    assert_output_contains "$header"
    local bullet
    for bullet in "$@"; do
        assert_output_contains "$bullet"
    done
}

# Assert stdout does not contain the phrase, e.g. bookkeeping the tool keeps silent.
function assert_output_lacks() {
    local phrase="$1"

    if [[ "$output" == *"$phrase"* ]]; then
        printf 'stdout should not contain: %s\n--- actual ---\n%s\n---\n' "$phrase" "$output" >&3
        return 1
    fi
}

# Assert the spec exists at the given path with the tag, title, body, and loader state.
function assert_spec_tree() {
    local specdir="$1"
    local tag="$2"
    local title="${3:-Sample Spec}"
    local specpath="$specdir/SPEC.md"

    assert_file_contains "$specpath" "# [$tag] $title"
    assert_file_contains "$specpath" "## Introduction"
    if [[ "$tag" == "READY" ]]; then
        assert_file_lacks "$specpath" "$LOADER_IMPORTANT_LINE"
    else
        assert_file_contains "$specpath" "$LOADER_ACTION_LINE"
    fi
}

# Assert DISCOVERY.md carries the tag, title, and loader block of a legacy carrier.
function assert_legacy_discovery_carrier() {
    local specdir="$1"
    local tag="$2"
    local title="${3:-Sample Spec}"
    local discoverypath="$specdir/DISCOVERY.md"

    assert_file_contains "$discoverypath" "# [$tag] $title"
    assert_file_contains "$discoverypath" "$LOADER_ACTION_LINE"
}

# Assert DISCOVERY.md is a plain notes file: fixed heading, no status tag.
function assert_discovery_notes() {
    local specdir="$1"
    local discoverypath="$specdir/DISCOVERY.md"

    assert_file_contains "$discoverypath" "# Discovery notes"
    assert_file_lacks "$discoverypath" "$LOADER_ACTION_LINE"
    if grep -Eq '^# \[' "$discoverypath"; then
        printf 'DISCOVERY.md should carry no status tag\n  in: %s\n' "$discoverypath" >&3
        return 1
    fi
}

# Assert the file opens with the `---` frontmatter fence and a created-at timestamp.
function assert_created_at_block() {
    local specpath="$1"
    local fence_count stamp_line

    fence_count="$(sed -n '1p;3p' "$specpath" | grep -c '^---$')"
    [[ "$fence_count" -eq 2 ]]
    stamp_line="$(sed -n '2p' "$specpath")"
    [[ "$stamp_line" =~ ^created-at:\ [0-9]{8}T[0-9]{4}$ ]]
    [[ "$(sed -n '4p' "$specpath")" == "" ]]
}

# Assert nothing exists at the given path.
function assert_path_missing() {
    local path="$1"

    if [[ -e "$path" ]]; then
        printf 'path should not exist: %s\n' "$path" >&3
        return 1
    fi
}

# Assert the repository at PROJECT_DIR reports a status line carrying the given paths.
function assert_git_status_contains() {
    local phrase="$1"
    local status_output

    status_output="$(git -C "$PROJECT_DIR" status --porcelain)"
    if [[ "$status_output" != *"$phrase"* ]]; then
        printf 'git status missing phrase: %s\n--- actual ---\n%s\n---\n' \
            "$phrase" "$status_output" >&3
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: rejects an unknown command" {
    cd "$PROJECT_DIR"

    # Fixed width keeps argparse's usage line unwrapped and comparable.
    COLUMNS=200 run -2 --separate-stderr "$SCRIPT_PATH" shipped
    assert_stderr_contains "invalid choice: 'shipped'"
    assert_stderr_contains "choose from init, rename, rebase, discovery, explo, draft"
    assert_stderr_contains "maybe-ready, ready, abandoned"
    assert_output_empty
}

@test "cli: exposes init, rename, and every state in help" {
    run -0 "$SCRIPT_PATH" --help
    assert_output_contains "init         create a spec directory in the discovery state"
    assert_output_contains "rename       rename the spec slug, or retitle it"
    assert_output_contains "discovery    move the spec to the discovery state"
    assert_output_contains "explo        move the spec to the explo state"
    assert_output_contains "draft        move the spec to the draft state"
    assert_output_contains "ready        move the spec to the ready state"
    assert_output_contains "abandoned    move the spec to the abandoned state"
    assert_output_lacks "migrate"
}

@test "cli: rejects the retired --force flag" {
    setup_spec "SPEC-READY-sample" "READY"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -2 --separate-stderr "$SCRIPT_PATH" abandoned --force
    assert_stderr_contains "unrecognized arguments: --force"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
}

# ------------------------------------------------------------------------------
# Tests: migrate

@test "migrate: moves a legacy spec into the new layout" {
    setup_spec "_WIP_SPECS/alpha" "DRAFT"
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" migrate _WIP_SPECS/alpha
    assert_output_contains "Migrated: _WIP_SPECS/alpha -> SPEC-DRAFT-alpha"
    assert_state "draft"
    assert_output_lacks "Session vars:"
    assert_output_contains "Removed empty _WIP_SPECS/"
    assert_path_missing "$PROJECT_DIR/_WIP_SPECS"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-alpha" "DRAFT"
}

@test "migrate: honours the H1 tag of a legacy spec" {
    setup_spec "_SPECS/gamma" "READY"
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" migrate _SPECS/gamma
    assert_output_contains "Migrated: _SPECS/gamma -> SPEC-READY-gamma"
    assert_state "ready"
    assert_output_lacks "Session vars:"
    assert_path_missing "$PROJECT_DIR/_SPECS"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-gamma" "READY"
}

@test "migrate: keeps a legacy container that still holds specs" {
    setup_spec "_WIP_SPECS/alpha" "DRAFT"
    setup_spec "_WIP_SPECS/beta" "DRAFT"
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" migrate _WIP_SPECS/alpha
    assert_output_contains "Migrated: _WIP_SPECS/alpha -> SPEC-DRAFT-alpha"
    assert_output_lacks "Removed empty"
    [[ -d "$PROJECT_DIR/_WIP_SPECS/beta" ]]
}

@test "migrate: defaults a tagless H1 to draft" {
    mkdir -p "$PROJECT_DIR/_WIP_SPECS/delta"
    printf '# Delta\n\n## Introduction\n\nBody text.\n' \
        > "$PROJECT_DIR/_WIP_SPECS/delta/SPEC.md"
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" migrate _WIP_SPECS/delta
    assert_output_contains "NOTE: H1 has no status tag"
    assert_output_contains "migrating as draft"
    assert_output_contains "Migrated: _WIP_SPECS/delta -> SPEC-DRAFT-delta"
    assert_state "draft"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-delta" "DRAFT" "Delta"
}

@test "migrate: seeds SPEC.md and DISCOVERY.md for a legacy dir that has neither" {
    mkdir -p "$PROJECT_DIR/_WIP_SPECS/epsilon"
    printf '# Exploration brief\n\nNotes.\n' \
        > "$PROJECT_DIR/_WIP_SPECS/epsilon/EXPLO-BRIEF.md"
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" migrate _WIP_SPECS/epsilon
    assert_output_contains "NOTE: no SPEC.md; seeded SPEC.md and DISCOVERY.md in the explo state."
    assert_output_contains "Migrated: _WIP_SPECS/epsilon -> SPEC-DRAFT-epsilon"
    assert_state "explo"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-epsilon/SPEC.md" "# [EXPLO] epsilon"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-epsilon/SPEC.md" "$EXPLO_POINTER_LINE"
    # The stamp comes from the oldest file the legacy dir still holds, not from the clock.
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-epsilon/SPEC.md" "created-at: "
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-epsilon"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-epsilon/EXPLO-BRIEF.md" "Notes."
}

@test "migrate: renames EXPLORATION-* files and their references" {
    setup_spec "_WIP_SPECS/eta" "DRAFT"
    printf '# Exploration brief\n\nSee `EXPLORATION-cli-surface.md`.\n' \
        > "$PROJECT_DIR/_WIP_SPECS/eta/EXPLORATION-BRIEF.md"
    printf '# CLI surface\n' > "$PROJECT_DIR/_WIP_SPECS/eta/EXPLORATION-cli-surface.md"
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" migrate _WIP_SPECS/eta
    assert_output_contains "Renamed: EXPLORATION-BRIEF.md -> EXPLO-BRIEF.md"
    assert_output_contains "Renamed: EXPLORATION-cli-surface.md -> EXPLO-cli-surface.md"
    assert_output_contains "Updated exploration references in 1 file(s)."
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-eta/EXPLORATION-BRIEF.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-eta/EXPLO-BRIEF.md" "`EXPLO-cli-surface.md`"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-eta/EXPLO-cli-surface.md" "# CLI surface"
}

@test "migrate: refuses to overwrite an existing EXPLO-* file" {
    setup_spec "_WIP_SPECS/theta" "DRAFT"
    printf '# Old brief\n' > "$PROJECT_DIR/_WIP_SPECS/theta/EXPLORATION-BRIEF.md"
    printf '# New brief\n' > "$PROJECT_DIR/_WIP_SPECS/theta/EXPLO-BRIEF.md"
    cd "$PROJECT_DIR"

    run -1 --separate-stderr "$SCRIPT_PATH" migrate _WIP_SPECS/theta
    assert_stderr_contains "cannot rename EXPLORATION-BRIEF.md"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-theta"
    assert_file_contains "$PROJECT_DIR/_WIP_SPECS/theta/EXPLORATION-BRIEF.md" "# Old brief"
}

@test "migrate: refuses a directory that is not a legacy spec" {
    mkdir -p "$PROJECT_DIR/SPEC-DRAFT-sample"
    printf '# [DRAFT] Sample Spec\n' > "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
    cd "$PROJECT_DIR"

    run -1 --separate-stderr "$SCRIPT_PATH" migrate SPEC-DRAFT-sample
    assert_stderr_contains "not a legacy spec directory"
    assert_output_empty
}

# ------------------------------------------------------------------------------
# Tests: init

@test "init: creates a discovery spec and prints its paths" {
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" init demo-spec
    assert_session_vars "Session vars: 3 new" \
        "- \$slug = demo-spec" \
        "- \$specdir = SPEC-DRAFT-demo-spec/" \
        "- \$specpath = SPEC-DRAFT-demo-spec/SPEC.md"
    assert_output_contains "Next: record the discovery notes in SPEC-DRAFT-demo-spec/DISCOVERY.md"
    [[ -d "$PROJECT_DIR/SPEC-DRAFT-demo-spec" ]]
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md" "# [DISCOVERY] demo-spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md" "$LOADER_ACTION_LINE"
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-demo-spec"
}

@test "init: writes the frontmatter block above the H1" {
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" init demo-spec "Demo Title"
    assert_created_at_block "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md" "# [DISCOVERY] Demo Title"
}

@test "init: seeds SPEC.md with the supplied title and leaves DISCOVERY.md untitled" {
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" init demo-spec "Demo Title"
    assert_session_vars "Session vars: 3 new" \
        "- \$slug = demo-spec" \
        "- \$specdir = SPEC-DRAFT-demo-spec/" \
        "- \$specpath = SPEC-DRAFT-demo-spec/SPEC.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md" "# [DISCOVERY] Demo Title"
    assert_file_lacks "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md" "## Introduction"
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-demo-spec"
    assert_file_lacks "$PROJECT_DIR/SPEC-DRAFT-demo-spec/DISCOVERY.md" "Demo Title"
}

@test "init: refuses a slug that already exists" {
    cd "$PROJECT_DIR"
    mkdir -p "$PROJECT_DIR/SPEC-DRAFT-demo-spec"

    run -1 --separate-stderr "$SCRIPT_PATH" init demo-spec
    assert_stderr_contains "spec 'demo-spec' already exists at"
    assert_stderr_contains "pick another slug"
    assert_output_empty
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-demo-spec/DISCOVERY.md"
}

@test "error: refuses invalid slugs" {
    local -a slugs=("bad slug" "bad/slug" "-lead")
    local slug index=0

    for slug in "${slugs[@]}"; do
        index=$((index + 1))
        PROJECT_DIR="$BATS_TEST_TMPDIR/project-$index"
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR"

        run -1 --separate-stderr "$SCRIPT_PATH" init -- "$slug"
        [[ "$status" -eq 1 ]]
        assert_stderr_contains "invalid slug"
        assert_stderr_contains "no whitespace, path separator, or leading dash"
        assert_output_empty
        assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-$slug"
    done
}

@test "init: refuses a slug already present in another state" {
    cd "$PROJECT_DIR"
    setup_spec "SPEC-READY-demo-spec" "READY"

    run -1 --separate-stderr "$SCRIPT_PATH" init demo-spec
    assert_stderr_contains "spec 'demo-spec' already exists at"
    assert_output_empty
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-demo-spec"
}

@test "init: offers revival when the slug is only an abandoned spec" {
    cd "$PROJECT_DIR"
    setup_spec "SPEC-KO-demo-spec" "ABANDONED"

    run -1 --separate-stderr "$SCRIPT_PATH" init demo-spec
    assert_stderr_contains "spec 'demo-spec' already exists at"
    assert_stderr_contains "run \`manage-spec draft\` from inside it to revive it"
    assert_output_empty
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-demo-spec"
}

@test "init: accepts an uppercase slug" {
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" init Demo-Spec
    assert_session_vars "Session vars: 3 new" \
        "- \$slug = Demo-Spec" \
        "- \$specdir = SPEC-DRAFT-Demo-Spec/" \
        "- \$specpath = SPEC-DRAFT-Demo-Spec/SPEC.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-Demo-Spec/SPEC.md" "# [DISCOVERY] Demo-Spec"
}

@test "init: refuses to nest a spec inside a spec directory" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" init nested
    assert_stderr_contains "that location sits inside a spec tree"
    assert_output_empty
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC-DRAFT-nested"
}

@test "init: refuses to nest a spec inside a legacy container" {
    mkdir -p "$PROJECT_DIR/_WIP_SPECS/legacy-spec"
    cd "$PROJECT_DIR/_WIP_SPECS"

    run -1 --separate-stderr "$SCRIPT_PATH" init nested
    assert_stderr_contains "that location sits inside a spec tree"
    assert_path_missing "$PROJECT_DIR/_WIP_SPECS/SPEC-DRAFT-nested"
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: refuses to run outside a spec directory" {
    cd "$PROJECT_DIR"

    run -1 --separate-stderr "$SCRIPT_PATH" ready
    assert_stderr_contains "not inside a spec directory (cwd: $PROJECT_DIR)"
    assert_stderr_contains "Expected SPEC-DRAFT-<slug>/, SPEC-READY-<slug>/"
    assert_output_empty
}

@test "error: refuses when the spec directory holds no carrier file" {
    mkdir -p "$PROJECT_DIR/SPEC-DRAFT-sample"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" ready
    assert_stderr_contains "no SPEC.md or DISCOVERY.md in $PROJECT_DIR/SPEC-DRAFT-sample"
    assert_stderr_contains "nothing changed"
    assert_output_empty
    assert_path_missing "$PROJECT_DIR/SPEC-READY-sample"
}

@test "error: refuses a transition outside the table" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" discovery
    assert_stderr_contains "transition draft → discovery is not allowed"
    assert_stderr_contains "Allowed from draft: abandoned, explo, maybe-ready, ready"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "error: refuses a dir/tag mismatch" {
    setup_spec "SPEC-DRAFT-sample" "READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" ready
    assert_stderr_contains "directory name and H1 status tag disagree"
    assert_stderr_contains "Tag implies: $PROJECT_DIR/SPEC-READY-sample"
    assert_stderr_contains "The H1 tag wins"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "READY"
}

@test "error: refuses to overwrite an existing target directory" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    setup_spec "SPEC-READY-sample" "READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" ready
    assert_stderr_contains "target directory already exists: $PROJECT_DIR/SPEC-READY-sample"
    assert_stderr_contains "merging two specs is a manual decision"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
}

@test "error: refuses a foreign marker leftmost on SPEC.md" {
    setup_spec "SPEC-READY-sample" "READY"
    printf '# [CLAIMED] [READY] Sample Spec\n' > "$PROJECT_DIR/SPEC-READY-sample/SPEC.md"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" draft
    assert_stderr_contains "unknown status tag [CLAIMED]"
    assert_stderr_contains "another tool wrote it"
    assert_stderr_contains "ask the user to reset the tag"
    assert_output_empty
    assert_file_contains "$PROJECT_DIR/SPEC-READY-sample/SPEC.md" "# [CLAIMED] [READY] Sample Spec"
}

@test "error: refuses a stacked foreign marker on DISCOVERY.md" {
    setup_legacy_discovery_spec "SPEC-DRAFT-sample" "DISCOVERY"
    printf '# [DONE] [CLAIMED] [DISCOVERY] Sample Spec\n' > "$PROJECT_DIR/SPEC-DRAFT-sample/DISCOVERY.md"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" draft
    assert_stderr_contains "unknown status tag [DONE]"
    assert_stderr_contains "another tool wrote it"
    assert_output_empty
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/DISCOVERY.md" \
        "# [DONE] [CLAIMED] [DISCOVERY] Sample Spec"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
}

@test "transition: acts on a spec after the marker tag is reset" {
    setup_spec "SPEC-READY-sample" "READY"
    printf '# [CLAIMED] [READY] Sample Spec\n' > "$PROJECT_DIR/SPEC-READY-sample/SPEC.md"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" draft

    # The reset the refusal asks for: the heading keeps only the manage-spec tag.
    expected_spec_content "READY" > "$PROJECT_DIR/SPEC-READY-sample/SPEC.md"
    run -0 "$SCRIPT_PATH" draft
    assert_state "draft"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

# ------------------------------------------------------------------------------
# Tests: transition

@test "transition: --fix repairs the directory without changing the state" {
    setup_spec "SPEC-DRAFT-sample" "READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" ready --fix
    assert_output_contains "State: ready (already current)"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-READY-sample/" \
        "- \$specpath = SPEC-READY-sample/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
}

@test "transition: --fix moves a discovery tag back under the draft prefix" {
    setup_legacy_discovery_spec "SPEC-READY-sample" "DISCOVERY"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -0 "$SCRIPT_PATH" discovery --fix
    assert_output_contains "State: discovery (already current)"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-DRAFT-sample/" \
        "- \$specpath = SPEC-DRAFT-sample/DISCOVERY.md"
    assert_path_missing "$PROJECT_DIR/SPEC-READY-sample"
    # A same-state --fix only repairs the directory; the legacy carrier converges on a transition.
    assert_legacy_discovery_carrier "$PROJECT_DIR/SPEC-DRAFT-sample" "DISCOVERY"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
}

@test "transition: --fix repairs the directory and then transitions" {
    setup_spec "SPEC-READY-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -0 "$SCRIPT_PATH" ready --fix
    assert_state "ready"
    assert_output_contains "Session vars: unchanged"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
}

@test "transition: --fix repairs and then converges the legacy carrier" {
    setup_legacy_discovery_spec "SPEC-READY-sample" "DISCOVERY"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -0 "$SCRIPT_PATH" draft --fix
    assert_state "draft"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [DRAFT] Sample Spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$LOADER_ACTION_LINE"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/DISCOVERY.md" "Notes."
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-sample"
}

@test "transition: same state is a no-op" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" draft
    assert_output_contains "State: draft (already current)"
    assert_output_contains "Session vars: unchanged"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "transition: draft → maybe-ready keeps the directory" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" maybe-ready
    assert_state "maybe-ready"
    assert_output_contains "Session vars: unchanged"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "MAYBE-READY"
    assert_path_missing "$PROJECT_DIR/SPEC-READY-sample"
}

@test "transition: discovery → explo converges the legacy carrier onto SPEC.md" {
    setup_legacy_discovery_spec "SPEC-DRAFT-sample" "DISCOVERY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" explo
    assert_state "explo"
    assert_session_vars "Session vars: 1 changed" \
        "- \$specpath = SPEC-DRAFT-sample/SPEC.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [EXPLO] Sample Spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$EXPLO_POINTER_LINE"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/DISCOVERY.md" "Notes."
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-sample"
}

@test "transition: explo → draft converges a legacy EXPLO carrier onto SPEC.md" {
    setup_legacy_discovery_spec "SPEC-DRAFT-sample" "EXPLO"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" draft
    assert_state "draft"
    assert_session_vars "Session vars: 1 changed" \
        "- \$specpath = SPEC-DRAFT-sample/SPEC.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [DRAFT] Sample Spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$LOADER_ACTION_LINE"
    assert_file_lacks "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "## Introduction"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/DISCOVERY.md" "Notes."
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-sample"
}

@test "transition: discovery → draft skips explo" {
    setup_legacy_discovery_spec "SPEC-DRAFT-sample" "DISCOVERY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" draft
    assert_state "draft"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [DRAFT] Sample Spec"
    assert_file_lacks "$PROJECT_DIR/SPEC-DRAFT-sample/DISCOVERY.md" "[DISCOVERY]"
}

@test "transition: draft → explo retags SPEC.md and keeps its body" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" explo
    assert_state "explo"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "EXPLO"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "## Introduction"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$EXPLO_POINTER_LINE"
}

@test "error: refuses to return to discovery" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" discovery
    assert_stderr_contains "transition draft → discovery is not allowed"
    assert_output_empty
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "## Introduction"
}

@test "transition: keeps the frontmatter block above the H1" {
    cd "$PROJECT_DIR"

    run -0 "$SCRIPT_PATH" init demo-spec "Demo Title"
    cd "$PROJECT_DIR/SPEC-DRAFT-demo-spec"
    run -0 "$SCRIPT_PATH" draft

    assert_created_at_block "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md" "# [DRAFT] Demo Title"
    local stamp_before
    stamp_before="$(sed -n '2p' "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md")"
    run -0 "$SCRIPT_PATH" maybe-ready
    [[ "$(sed -n '2p' "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md")" == "$stamp_before" ]]
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-demo-spec/SPEC.md" "# [MAYBE-READY] Demo Title"
}

@test "edge: refuses an unclosed frontmatter block" {
    mkdir -p "$PROJECT_DIR/SPEC-DRAFT-sample"
    printf -- '---\ncreated-at: 20260101T0900\n\n# [DRAFT] Sample Spec\n' \
        > "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" maybe-ready
    assert_stderr_contains "no closing"
    assert_output_empty
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [DRAFT] Sample Spec"
    assert_path_missing "$PROJECT_DIR/SPEC-READY-sample"
}

@test "transition: normalises a legacy singular loader" {
    mkdir -p "$PROJECT_DIR/SPEC-DRAFT-sample"
    {
        printf '# [DRAFT] Sample Spec\n\n'
        printf '> agents MUST load one of the spec-writing skill first.\n\n'
        printf '## Introduction\n\nBody text.\n'
    } > "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" maybe-ready
    assert_state "maybe-ready"
    assert_file_lacks "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "spec-writing skill first"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$LOADER_ACTION_LINE"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "## Introduction"
    local specpath loader_count
    specpath="$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
    loader_count="$(grep -c 'IMPORTANT: Before any drafting' "$specpath")"
    [[ "$loader_count" == 1 ]]
}

@test "transition: maybe-ready → ready moves the directory and drops the loader" {
    setup_spec "SPEC-DRAFT-sample" "MAYBE-READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" ready
    assert_state "ready"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-READY-sample/" \
        "- \$specpath = SPEC-READY-sample/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
}

@test "transition: abandoned → draft moves back under the draft prefix" {
    setup_spec "SPEC-KO-sample" "ABANDONED"
    cd "$PROJECT_DIR/SPEC-KO-sample"

    run -0 "$SCRIPT_PATH" draft
    assert_state "draft"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-DRAFT-sample/" \
        "- \$specpath = SPEC-DRAFT-sample/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-KO-sample"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "transition: abandoned → explo moves back under the draft prefix" {
    setup_spec "SPEC-KO-sample" "ABANDONED"
    cd "$PROJECT_DIR/SPEC-KO-sample"

    run -0 "$SCRIPT_PATH" explo
    assert_state "explo"
    assert_path_missing "$PROJECT_DIR/SPEC-KO-sample"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [EXPLO] Sample Spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$EXPLO_POINTER_LINE"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "## Introduction"
}

@test "transition: draft → ready moves the directory and drops the loader" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" ready
    assert_state "ready"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
}

@test "transition: every state → abandoned moves under the KO prefix" {
    # One case per source state, each asserting the move lands under SPEC-KO-<slug>/.
    local -a cases=(
        "SPEC-DRAFT-sample|DISCOVERY|discovery"
        "SPEC-DRAFT-sample|EXPLO|explo"
        "SPEC-DRAFT-sample|DRAFT|draft"
        "SPEC-DRAFT-sample|MAYBE-READY|maybe-ready"
        "SPEC-READY-sample|READY|ready"
    )
    local entry dir_name tag state kodir index=0

    for entry in "${cases[@]}"; do
        IFS='|' read -r dir_name tag state <<< "$entry"
        index=$((index + 1))
        PROJECT_DIR="$BATS_TEST_TMPDIR/project-$index"
        mkdir -p "$PROJECT_DIR"
        case "$state" in
            discovery|explo) setup_legacy_discovery_spec "$dir_name" "$tag" ;;
            *) setup_spec "$dir_name" "$tag" ;;
        esac
        cd "$PROJECT_DIR/$dir_name"

        run -0 "$SCRIPT_PATH" abandoned

        kodir="$PROJECT_DIR/SPEC-KO-sample"
        assert_state "abandoned"
        assert_path_missing "$PROJECT_DIR/$dir_name"
        if [[ "$state" == "discovery" || "$state" == "explo" ]]; then
            # The legacy carrier converges: a fresh body-less SPEC.md, notes left untagged.
            assert_file_contains "$kodir/SPEC.md" "# [ABANDONED] Sample Spec"
            assert_file_lacks "$kodir/SPEC.md" "## Introduction"
            assert_discovery_notes "$kodir"
        else
            assert_spec_tree "$kodir" "ABANDONED"
        fi
    done
}

@test "transition: maybe-ready → draft keeps the directory" {
    setup_spec "SPEC-DRAFT-sample" "MAYBE-READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" draft
    assert_state "draft"
    assert_output_contains "Session vars: unchanged"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "transition: maybe-ready → explo keeps the directory and its body" {
    setup_spec "SPEC-DRAFT-sample" "MAYBE-READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" explo
    assert_state "explo"
    assert_output_contains "Session vars: unchanged"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [EXPLO] Sample Spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$EXPLO_POINTER_LINE"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "## Introduction"
}

@test "transition: ready → draft moves back under the draft prefix" {
    setup_spec "SPEC-READY-sample" "READY"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -0 "$SCRIPT_PATH" draft
    assert_state "draft"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-DRAFT-sample/" \
        "- \$specpath = SPEC-DRAFT-sample/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-READY-sample"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "transition: ready → explo demotes under the draft prefix and keeps its body" {
    setup_spec "SPEC-READY-sample" "READY"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -0 "$SCRIPT_PATH" explo
    assert_state "explo"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-DRAFT-sample/" \
        "- \$specpath = SPEC-DRAFT-sample/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-READY-sample"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [EXPLO] Sample Spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$EXPLO_POINTER_LINE"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "## Introduction"
}

@test "transition: ready → maybe-ready keeps the directory" {
    setup_spec "SPEC-READY-sample" "READY"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    run -0 "$SCRIPT_PATH" maybe-ready
    assert_state "maybe-ready"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "MAYBE-READY"
    assert_path_missing "$PROJECT_DIR/SPEC-READY-sample"
}

@test "error: refuses every transition outside the table" {
    # Every (dir, tag, target) triple the transition table forbids.
    local -a cases=(
        "SPEC-DRAFT-sample|DISCOVERY|maybe-ready"
        "SPEC-DRAFT-sample|DISCOVERY|ready"
        "SPEC-DRAFT-sample|EXPLO|discovery"
        "SPEC-DRAFT-sample|EXPLO|maybe-ready"
        "SPEC-DRAFT-sample|EXPLO|ready"
        "SPEC-DRAFT-sample|MAYBE-READY|discovery"
        "SPEC-READY-sample|READY|discovery"
        "SPEC-KO-sample|ABANDONED|discovery"
        "SPEC-KO-sample|ABANDONED|maybe-ready"
        "SPEC-KO-sample|ABANDONED|ready"
    )
    local entry dir_name tag target index=0

    for entry in "${cases[@]}"; do
        IFS='|' read -r dir_name tag target <<< "$entry"
        index=$((index + 1))
        PROJECT_DIR="$BATS_TEST_TMPDIR/project-$index"
        mkdir -p "$PROJECT_DIR"
        case "$tag" in
            DISCOVERY|EXPLO) setup_legacy_discovery_spec "$dir_name" "$tag" ;;
            *) setup_spec "$dir_name" "$tag" ;;
        esac
        cd "$PROJECT_DIR/$dir_name"

        run -1 --separate-stderr "$SCRIPT_PATH" "$target"
        [[ "$status" -eq 1 ]]
        assert_stderr_contains "is not allowed"
        assert_output_empty
    done
}

# ------------------------------------------------------------------------------
# Tests: rename

@test "rename: renames the slug and keeps the tag" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rename renamed
    assert_output_contains "Renamed: sample -> renamed"
    assert_session_vars "Session vars: 3 changed" \
        "- \$slug = renamed" \
        "- \$specdir = SPEC-DRAFT-renamed/" \
        "- \$specpath = SPEC-DRAFT-renamed/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-renamed" "DRAFT"
}

@test "rename: updates the H1 title when one is supplied" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rename renamed "Renamed Title"
    assert_output_contains "Renamed: sample -> renamed"
    assert_session_vars "Session vars: 3 changed" \
        "- \$slug = renamed" \
        "- \$specdir = SPEC-DRAFT-renamed/" \
        "- \$specpath = SPEC-DRAFT-renamed/SPEC.md"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-renamed" "DRAFT" "Renamed Title"
}

@test "rename: retitles without renaming the slug" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rename sample "New Title"
    assert_output_contains "Retitled: New Title"
    assert_output_contains "Session vars: unchanged"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT" "New Title"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-new-title"
}

@test "rename: refuses a slug taken in another state" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    setup_spec "SPEC-READY-other" "READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rename other
    assert_stderr_contains "spec 'other' already exists at $PROJECT_DIR/SPEC-READY-other"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-other" "READY"
}

@test "rename: treats a spaced argument as a title" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rename "New Title"
    assert_output_contains "Retitled: New Title"
    assert_output_contains "Session vars: unchanged"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT" "New Title"
}

@test "rename: refuses a slug with a path separator" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rename "bad/slug"
    assert_stderr_contains "invalid slug 'bad/slug'"
    assert_stderr_contains "no whitespace, path separator, or leading dash"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "error: refuses a one-word title" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rename sample "Word"
    assert_stderr_contains "invalid title 'Word'"
    assert_stderr_contains "a title needs more than one word"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "error: refuses two titles in one rename" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rename "New Title" "Other Title"
    assert_stderr_contains "two titles given"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "rename: converges a legacy DISCOVERY.md carrier onto SPEC.md" {
    setup_legacy_discovery_spec "SPEC-DRAFT-sample" "DISCOVERY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rename renamed
    assert_output_contains "Renamed: sample -> renamed"
    assert_session_vars "Session vars: 3 changed" \
        "- \$slug = renamed" \
        "- \$specdir = SPEC-DRAFT-renamed/" \
        "- \$specpath = SPEC-DRAFT-renamed/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-renamed/SPEC.md" "# [DISCOVERY] Sample Spec"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-renamed/DISCOVERY.md" "Notes."
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-renamed"
}

@test "rename: converges a legacy carrier on a retitle-only rename" {
    setup_legacy_discovery_spec "SPEC-DRAFT-sample" "EXPLO"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rename "New Title"
    assert_output_contains "Retitled: New Title"
    assert_session_vars "Session vars: 1 changed" \
        "- \$specpath = SPEC-DRAFT-sample/SPEC.md"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [EXPLO] New Title"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "$EXPLO_POINTER_LINE"
    assert_discovery_notes "$PROJECT_DIR/SPEC-DRAFT-sample"
}

@test "rename: moves an abandoned spec within the KO prefix" {
    setup_spec "SPEC-KO-sample" "ABANDONED"
    cd "$PROJECT_DIR/SPEC-KO-sample"

    run -0 "$SCRIPT_PATH" rename renamed
    assert_output_contains "Renamed: sample -> renamed"
    assert_spec_tree "$PROJECT_DIR/SPEC-KO-renamed" "ABANDONED"
    assert_path_missing "$PROJECT_DIR/SPEC-KO-sample"
}

@test "rename: --fix repairs a dir/tag mismatch" {
    setup_spec "SPEC-DRAFT-sample" "READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 --separate-stderr "$SCRIPT_PATH" rename sample-renamed --fix
    assert_output_contains "Renamed: sample -> sample-renamed"
    # The target directory follows the tag, so the mismatch is gone afterwards.
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample-renamed" "READY"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
}

@test "rename: refuses a dir/tag mismatch without --fix" {
    setup_spec "SPEC-DRAFT-sample" "READY"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rename sample-renamed
    assert_stderr_contains "directory name and H1 status tag disagree"
    assert_stderr_contains "rerun with --fix to repair the directory name"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "READY"
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: refuses a tagless H1 under the draft prefix" {
    mkdir -p "$PROJECT_DIR/SPEC-DRAFT-sample"
    printf '# Sample Spec\n\n## Introduction\n\nBody text.\n' \
        > "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    # Four states share the prefix, so a missing tag leaves the state undecidable.
    run -1 --separate-stderr "$SCRIPT_PATH" maybe-ready
    assert_stderr_contains "cannot derive the current state of $PROJECT_DIR/SPEC-DRAFT-sample"
    assert_stderr_contains "carries no status tag"
    assert_file_contains "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# Sample Spec"
}

@test "edge: --fix refuses a tagless H1" {
    mkdir -p "$PROJECT_DIR/SPEC-READY-sample"
    printf '# Sample Spec\n\n## Introduction\n\nBody text.\n' \
        > "$PROJECT_DIR/SPEC-READY-sample/SPEC.md"
    cd "$PROJECT_DIR/SPEC-READY-sample"

    # The directory names the state, so --fix has nothing to repair from.
    run -1 --separate-stderr "$SCRIPT_PATH" ready --fix
    assert_stderr_contains "carries no status tag"
    assert_stderr_contains "Give it a status tag"
    assert_output_empty
}

@test "edge: ignores a leading blank line before the H1" {
    mkdir -p "$PROJECT_DIR/SPEC-DRAFT-sample"
    printf '\n# [DRAFT] Sample Spec\n\n## Introduction\n\nBody text.\n' \
        > "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" maybe-ready
    assert_state "maybe-ready"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "MAYBE-READY"
    # The rewrite must not duplicate the H1 or keep the stale tag.
    assert_file_lacks "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md" "# [DRAFT] Sample Spec"
    [[ "$(grep -c '^# ' "$PROJECT_DIR/SPEC-DRAFT-sample/SPEC.md")" -eq 1 ]]
}

# ------------------------------------------------------------------------------
# Tests: rebase

@test "rebase: moves the spec under another base" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    mkdir -p "$PROJECT_DIR/specs"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rebase specs
    assert_output_contains "Rebased: SPEC-DRAFT-sample -> specs/SPEC-DRAFT-sample"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = specs/SPEC-DRAFT-sample/" \
        "- \$specpath = specs/SPEC-DRAFT-sample/SPEC.md"
    assert_spec_tree "$PROJECT_DIR/specs/SPEC-DRAFT-sample" "DRAFT"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
}

@test "rebase: accepts an absolute base" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    mkdir -p "$PROJECT_DIR/specs"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rebase "$PROJECT_DIR/specs"
    assert_spec_tree "$PROJECT_DIR/specs/SPEC-DRAFT-sample" "DRAFT"
}

@test "rebase: refuses a missing base directory" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rebase specs
    assert_stderr_contains "base directory does not exist: $PROJECT_DIR/specs"
    assert_stderr_contains "never creates directories"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "rebase: refuses a base outside the project" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rebase ..
    assert_stderr_contains "base directory is outside the project"
    assert_output_empty
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "rebase: refuses the spec's current base" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rebase .
    assert_stderr_contains "spec is already under"
    assert_output_empty
}

@test "rebase: refuses a base that already holds the slug" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    setup_spec "specs/SPEC-DRAFT-sample" "DRAFT"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -1 --separate-stderr "$SCRIPT_PATH" rebase specs
    assert_stderr_contains "target directory already exists"
    assert_spec_tree "$PROJECT_DIR/SPEC-DRAFT-sample" "DRAFT"
}

@test "rebase: uses git mv for a tracked spec" {
    setup_spec "SPEC-DRAFT-sample" "DRAFT"
    setup_git_repo
    mkdir -p "$PROJECT_DIR/specs"
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" rebase specs
    assert_spec_tree "$PROJECT_DIR/specs/SPEC-DRAFT-sample" "DRAFT"
    assert_git_status_contains "R  SPEC-DRAFT-sample/SPEC.md -> specs/SPEC-DRAFT-sample/SPEC.md"
}

# ------------------------------------------------------------------------------
# Tests: integration

@test "integration: uses git mv for a tracked spec" {
    setup_spec "SPEC-DRAFT-sample" "MAYBE-READY"
    setup_git_repo
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" ready
    assert_state "ready"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-READY-sample/" \
        "- \$specpath = SPEC-READY-sample/SPEC.md"
    assert_git_status_contains "RM SPEC-DRAFT-sample/SPEC.md -> SPEC-READY-sample/SPEC.md"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
}

@test "integration: moves a spec while unrelated changes are staged" {
    setup_spec "SPEC-DRAFT-sample" "MAYBE-READY"
    setup_git_repo
    touch "$PROJECT_DIR/unrelated.txt"
    git -C "$PROJECT_DIR" add unrelated.txt
    cd "$PROJECT_DIR/SPEC-DRAFT-sample"

    run -0 "$SCRIPT_PATH" ready
    assert_state "ready"
    assert_session_vars "Session vars: 2 changed" \
        "- \$specdir = SPEC-READY-sample/" \
        "- \$specpath = SPEC-READY-sample/SPEC.md"
    assert_path_missing "$PROJECT_DIR/SPEC-DRAFT-sample"
    assert_spec_tree "$PROJECT_DIR/SPEC-READY-sample" "READY"
    assert_git_status_contains "A  unrelated.txt"
}
