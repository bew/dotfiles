# Helpers shared by the `git/bin/*` scripts.
#
# A script pulls these in with `source ./_common_helpers.nu`; nushell resolves
# that relative path against the script's own directory, so the scripts work
# from any cwd.

# Abort with an actionable message on stderr.
# Each extra line is printed on its own line, indented to align under the message.
def fail [message: string, ...detail_lines: string] {
    print --stderr $"!! ERROR: ($message)"
    for line in $detail_lines { print --stderr $"   ($line)" }
    exit 1
}

# Return the work-tree root, so index mutations work when invoked from a subdirectory.
def get_work_root []: nothing -> string {
    let probe = (^git rev-parse --show-toplevel | complete)
    if $probe.exit_code != 0 {
        fail "not inside a git work tree"
    }
    $probe.stdout | str trim
}

# Reset the given index entries to their HEAD state.
# Falls back to dropping them from the index on an unborn branch, where
# `git restore --staged` cannot resolve HEAD.
def reset_index_entries [work_root: string, paths: list<string>] {
    if ($paths | is-empty) { return }

    let head_exists = ((^git -C $work_root rev-parse --verify --quiet HEAD | complete).exit_code == 0)
    let undone = if $head_exists {
        ^git -C $work_root restore --staged -- ...$paths | complete
    } else {
        ^git -C $work_root rm --cached --quiet -- ...$paths | complete
    }
    if $undone.exit_code != 0 {
        fail $"could not unstage paths: ($undone.stderr | str trim)"
    }
}

# Record the given paths as intent-to-add, keeping them tracked but unstaged.
def mark_intent_to_add [work_root: string, paths: list<string>] {
    if ($paths | is-empty) { return }

    let added = (^git -C $work_root add --intent-to-add -- ...$paths | complete)
    if $added.exit_code != 0 {
        fail $"could not keep new files tracked: ($added.stderr | str trim)"
    }
}

# Make a repo-root-relative path relative to the current directory.
# Paths outside the cwd gain leading `..` segments.
def to_cwd_relative [path: string, prefix: string]: nothing -> string {
    let depth = ($prefix | split row "/" | where {|part| $part != "" } | length)
    if $depth == 0 {
        $path
    } else if ($path | str starts-with $prefix) {
        $path | split row "/" | skip $depth | str join "/"
    } else {
        let up = (0..<$depth | each { '..' } | str join '/')
        $"($up)/($path)"
    }
}

# Print each path on its own line, cwd-relative when `relative` is set.
def print_paths [paths: list<string>, relative: bool] {
    if $relative {
        let prefix = (^git rev-parse --show-prefix | str trim)
        for path in $paths { print (to_cwd_relative $path $prefix) }
    } else {
        for path in $paths { print $path }
    }
}
