# Test suite for `nvimq` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/nvimq"

# Hermetic fixtures: the Lua backend reads these doc dirs and, because
# NVIMQ_DOC_ROOT is set, the Python CLI adds --clean to the nvim invocation.
function setup() {
    local fixtures="$SCRIPT_DIR/test-fixtures"
    local doc_root="$fixtures/runtime/doc"
    doc_root+=":$fixtures/plugins/sample/doc"
    doc_root+=":$fixtures/plugins/other/doc"
    export NVIMQ_DOC_ROOT="$doc_root"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: tag prints the rendered block around the anchor" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" tag core-alpha
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
    [[ "${lines[0]}" == *"*core-alpha*" ]]
    [[ "$output" == *"*alpha-inline*"* ]]
}

@test "defaults: section without names renders the whole file" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core
    [[ "${#lines[@]}" -eq 61 ]]
    [[ "${lines[0]}" == "*core.txt*"* ]]
    [[ "${lines[2]}" == "## INTRO"* ]]
}

@test "defaults: toc lists sections with line counts and stem.txt header" {
    run -0 "$SCRIPT_PATH" toc core
    [[ "${#lines[@]}" -eq 9 ]]
    [[ "${lines[0]}" == "core.txt" ]]
    [[ "${lines[1]}" == "INTRO  (45 lines)" ]]
    [[ "${lines[2]}" == "  ALPHA SECTION  (30 lines)" ]]
    [[ "${lines[3]}" == "    VIM.LSP.EXAMPLE()  (23 lines)" ]]
    [[ "${lines[4]}" == "      Parameters:  (19 lines)" ]]
    [[ "${lines[5]}" == "  SUB ALPHA  (6 lines)" ]]
    [[ "${lines[6]}" == "BETA SECTION  (13 lines)" ]]
    [[ "${lines[7]}" == "  SUB BETA  (5 lines)" ]]
    [[ "${lines[8]}" == "GAMMA  (4 lines)" ]]
}

@test "defaults: find matches a tag and prints file, line, name" {
    run -0 "$SCRIPT_PATH" find core-gamma
    [[ "$output" == "core.txt:62: core-gamma" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: -L limits toc depth" {
    run -0 "$SCRIPT_PATH" toc core -L 1
    [[ "${#lines[@]}" -eq 4 ]]
    [[ "${lines[0]}" == "core.txt" ]]
    [[ "${lines[1]}" == "INTRO  (45 lines)" ]]
    [[ "${lines[2]}" == "BETA SECTION  (13 lines)" ]]
    [[ "${lines[3]}" == "GAMMA  (4 lines)" ]]
}

@test "cli: -L includes nested h2 sections" {
    run -0 "$SCRIPT_PATH" toc core -L 2
    [[ "${#lines[@]}" -eq 7 ]]
    [[ "${lines[2]}" == "  ALPHA SECTION  (30 lines)" ]]
    [[ "${lines[3]}" == "  SUB ALPHA  (6 lines)" ]]
}

@test "cli: section accepts FILE:NAME target" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core:core-alpha
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
    [[ "${lines[0]}" == *"*core-alpha*" ]]
}

@test "cli: section accepts multiple positional names" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core core-alpha core-beta
    [[ "${#lines[@]}" -eq 44 ]]
    [[ "${lines[32]}" == "" ]]
    [[ "${lines[33]}" == "## BETA SECTION"* ]]
    [[ "$output" == *"*core-beta*"* ]]
}

@test "cli: bare stem and .txt are equivalent" {
    run -0 "$SCRIPT_PATH" toc core.txt
    [[ "${lines[0]}" == "core.txt" ]]
    run -0 "$SCRIPT_PATH" toc core
    [[ "${lines[0]}" == "core.txt" ]]
}

@test "cli: -S filters toc to plugin scope" {
    run -0 "$SCRIPT_PATH" toc sample -S plugin
    [[ "${lines[0]}" == "sample.txt" ]]
    [[ "${lines[1]}" == "SAMPLE USAGE  (10 lines)" ]]
}

@test "cli: tag -S hits the matching scope" {
    run -0 "$SCRIPT_PATH" tag core-alpha -S core
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
}

@test "cli: --lines slices rendered section output" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core core-alpha --lines 1-3
    [[ "${#lines[@]}" -eq 3 ]]
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
    [[ "${lines[2]}" == "Alpha body line one." ]]
}

@test "cli: tag --lines slices the rendered window" {
    run -0 "$SCRIPT_PATH" tag core-alpha --lines 3-4
    [[ "${#lines[@]}" -eq 2 ]]
    [[ "${lines[0]}" == "Alpha body line one." ]]
    [[ "${lines[1]}" == "Alpha body line two with *alpha-inline* anchor." ]]
}

@test "cli: find -S filters by scope" {
    run -0 "$SCRIPT_PATH" find '^sample-(usage|options)$' -S plugin
    [[ "${#lines[@]}" -eq 2 ]]
    [[ "${lines[0]}" == "sample.txt:4: sample-usage" ]]
    [[ "${lines[1]}" == "sample.txt:10: sample-options" ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: unknown tag fails" {
    run -1 --separate-stderr "$SCRIPT_PATH" tag no-such-tag
    [[ "$stderr" == *"unknown tag"* ]]
    [[ -z "$output" ]]
}

@test "error: unknown file fails" {
    run -1 --separate-stderr "$SCRIPT_PATH" toc no-such-file
    [[ "$stderr" == *"help file not found"* ]]
}

@test "error: unknown section fails" {
    run -1 --separate-stderr "$SCRIPT_PATH" section core no-such-section
    [[ "$stderr" == *"no section matching"* ]]
}

@test "error: toc scope mismatch fails" {
    run -1 --separate-stderr "$SCRIPT_PATH" toc core -S plugin
    [[ "$stderr" == *"scope 'plugin'"* ]]
}

@test "error: tag -S scope miss is reported" {
    run -1 --separate-stderr "$SCRIPT_PATH" tag core-alpha -S plugin
    [[ "$stderr" == *"outside scope 'plugin'"* ]]
}

@test "error: tag exists only outside requested scope" {
    run -1 --separate-stderr "$SCRIPT_PATH" tag dup-tag -S core
    [[ "$stderr" == *"outside scope 'core'"* ]]
}

@test "error: -L below 1 fails" {
    run -1 --separate-stderr "$SCRIPT_PATH" toc core -L 0
    [[ "$stderr" == *"-L must be a positive integer"* ]]
}

@test "error: reversed --lines fails" {
    run -1 --separate-stderr "$SCRIPT_PATH" section core core-alpha --lines 5-3
    [[ "$stderr" == *"invalid --lines"* ]]
}

@test "error: malformed --lines fails" {
    run -1 --separate-stderr "$SCRIPT_PATH" section core core-alpha --lines abc
    [[ "$stderr" == *"invalid --lines"* ]]
}

@test "error: missing tag argument is a usage error" {
    run -2 "$SCRIPT_PATH" tag
}

@test "error: missing nvim without a doc root is reported" {
    local bin="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$bin"
    ln -sf "$(command -v python3)" "$bin/python3"
    NVIMQ_DOC_ROOT= PATH="$bin" run -1 --separate-stderr "$SCRIPT_PATH" tag lsp
    [[ "$stderr" == *"nvim"* ]]
}

@test "error: missing doc root entry fails" {
    NVIMQ_DOC_ROOT="$BATS_TEST_TMPDIR/nope" \
        run -1 --separate-stderr "$SCRIPT_PATH" toc core
    [[ "$stderr" == *"not a directory"* ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: tag lookup is case-insensitive" {
    run -0 "$SCRIPT_PATH" tag CORE-ALPHA
    [[ "${lines[0]}" == *"*core-alpha*" ]]
}

@test "edge: tag tolerates a missing () suffix" {
    run -0 "$SCRIPT_PATH" tag core-paren
    [[ "${lines[0]}" == *"*core-paren()*"* ]]
}

@test "edge: tag tolerates a redundant () suffix" {
    run -0 "$SCRIPT_PATH" tag "core-paren()"
    [[ "${lines[0]}" == *"*core-paren()*"* ]]
}

@test "edge: tag strips a *anchor* marker" {
    run -0 "$SCRIPT_PATH" tag "*core-alpha*"
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
    [[ "${lines[0]}" == *"*core-alpha*" ]]
}

@test "edge: tag strips a |ref| marker" {
    run -0 "$SCRIPT_PATH" tag "|core-alpha|"
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
}

@test "edge: tag accepts a bare option name via quotes" {
    run -0 "$SCRIPT_PATH" tag opt
    [[ "${lines[0]}" == *"*'opt'*"* ]]
}

@test "edge: tag accepts an explicitly quoted option name" {
    run -0 "$SCRIPT_PATH" tag "'opt'"
    [[ "${lines[0]}" == *"*'opt'*"* ]]
}

@test "edge: section name strips markers" {
    run -0 "$SCRIPT_PATH" section core "|core-alpha|"
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
}

@test "edge: find strips a fully wrapped pattern" {
    run -0 "$SCRIPT_PATH" find "|core-gamma|"
    [[ "$output" == "core.txt:62: core-gamma" ]]
}

@test "edge: ambiguous tag warns on stderr and prints first match" {
    run -0 --separate-stderr "$SCRIPT_PATH" tag dup-tag
    [[ "$stderr" == *"ambiguous"* ]]
    [[ "$stderr" == *"sample.txt (plugin)"* ]]
    [[ "$stderr" == *"other.txt (plugin)"* ]]
    [[ "${lines[0]}" == "Sample plugin body line one. *dup-tag*" ]]
}

@test "edge: scoped ambiguity lists only in-scope matches" {
    run -0 --separate-stderr "$SCRIPT_PATH" tag dup-tag -S plugin
    [[ "$stderr" == *"sample.txt (plugin)"* ]]
    [[ "$stderr" == *"other.txt (plugin)"* ]]
}

@test "edge: section lookup by lowercased title" {
    run -0 "$SCRIPT_PATH" section core "alpha section"
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
}

@test "edge: section lookup by heading tag" {
    run -0 "$SCRIPT_PATH" section core core-h3
    [[ "${lines[0]}" == "#### VIM.LSP.EXAMPLE()"* ]]
}

@test "edge: section lookup by column heading title" {
    run -0 "$SCRIPT_PATH" section core "Parameters:"
    [[ "${lines[0]}" == "#### Parameters:" ]]
}

@test "edge: numeric section selects by document order" {
    run -0 "$SCRIPT_PATH" section core 2
    [[ "${lines[0]}" == "### ALPHA SECTION"* ]]
}

@test "edge: find matches regex anchors across files" {
    run -0 "$SCRIPT_PATH" find '^sample-(usage|options)$' -S plugin
    [[ "${#lines[@]}" -eq 2 ]]
    [[ "${lines[0]}" == "sample.txt:4: sample-usage" ]]
    [[ "${lines[1]}" == "sample.txt:10: sample-options" ]]
}

@test "edge: find without matches exits 0 with no output" {
    run -0 "$SCRIPT_PATH" find zzz-no-match
    [[ -z "$output" ]]
}

@test "edge: rendered section fences and de-indents lua code" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core core-alpha --lines 14-20
    [[ "${lines[0]}" == "Example:" ]]
    [[ "${lines[1]}" == '```lua' ]]
    [[ "${lines[2]}" == "local x = 1" ]]
    [[ "${lines[3]}" == "if x then" ]]
    [[ "${lines[4]}" == "  print(x)" ]]
    [[ "${lines[5]}" == "end" ]]
    [[ "${lines[6]}" == '```' ]]
}

@test "edge: bare code blocks get a plain fence" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core core-alpha --lines 22-26
    [[ "${lines[0]}" == "Bare sample:" ]]
    [[ "${lines[1]}" == '```' ]]
    [[ "${lines[2]}" == "echo hello" ]]
    [[ "${lines[3]}" == "echo world" ]]
    [[ "${lines[4]}" == '```' ]]
}

@test "edge: vim code blocks get a vim fence" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core core-alpha --lines 28-31
    [[ "${lines[0]}" == "Vim sample:" ]]
    [[ "${lines[1]}" == '```vim' ]]
    [[ "${lines[2]}" == ":set number" ]]
    [[ "${lines[3]}" == '```' ]]
}

@test "edge: implicitly closed code blocks still get a closing fence" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section other other-usage
    [[ "$output" == *"Implicit example:"* ]]
    [[ "$output" == *'```lua'* ]]
    [[ "$output" == *'local y = 2'* ]]
    [[ "$output" == *'print(y)'*'```'* ]]
}

@test "edge: inline tag and ref anchors are preserved" {
    run -0 "$SCRIPT_PATH" section core core-intro
    [[ "$output" == *"*core-inline*"* ]]
    [[ "$output" == *"|core-ref|"* ]]
}

@test "edge: column heading drops the ~ delimiter" {
    run -0 "$SCRIPT_PATH" section core core-h3 --lines 5
    [[ "${lines[0]}" == "#### Parameters:" ]]
}

# ------------------------------------------------------------------------------
# Tests: integration

@test "integration: multiple sections remain greppable" {
    run -0 --keep-empty-lines "$SCRIPT_PATH" section core core-alpha core-beta
    [[ "$output" == *"*core-beta*"* ]]
    [[ "$output" == *"Beta body line four."* ]]
}

@test "integration: find and section agree on a heading line" {
    run -0 "$SCRIPT_PATH" find core-beta -S core
    [[ "${lines[0]}" == "core.txt:49: core-beta" ]]
    run -0 "$SCRIPT_PATH" section core core-beta
    [[ "${lines[0]}" == "## BETA SECTION"* ]]
}
