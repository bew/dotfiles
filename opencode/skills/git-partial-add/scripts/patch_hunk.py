#!/usr/bin/env python3
"""
patch_hunk.py - selective git hunk staging tool

Usage:
    patch_hunk.py <diff-file> < instructions.txt | git apply --cached

Instruction format (tab-separated fields):
    <file>\t<hunk-index>\t<action>[\t<modifier>]
    [override block lines]
    [---]

Actions:
    stage           stage the hunk as-is
    skip            do not stage the hunk
    partial         stage hunk excluding listed hunk-line numbers (1-based, comma-separated in 4th field)
    override        replace specific +/- lines in the hunk (see modifier)

Modifiers (for override):
    staging         modify what gets staged (the + side): replace/add lines in the staged patch
    staged          modify what the index looks like after: affect - side handling

Override block syntax (after the instruction line, until ---):
    +<content>      the line to stage instead of the original + line (staging)
    -<content>      the line to remove from the - side (staged)

Example instructions:
    foo.py\t1\tstage
    foo.py\t2\tskip
    foo.py\t3\tpartial\t2,4
    foo.py\t4\toverride\tstaging
    +foo(x, verbose=True)
    ---
    bar.py\t1\tstage
"""

import sys
import re
from dataclasses import dataclass, field
from typing import Optional


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class Hunk:
    file_path: str
    old_start: int
    old_count: int
    new_start: int
    new_count: int
    lines: list[str]          # raw lines including @@ header
    header_suffix: str = ""   # function name hint after @@

    @property
    def header(self) -> str:
        return self.lines[0]

    @property
    def body(self) -> list[str]:
        return self.lines[1:]


@dataclass
class FileDiff:
    path: str
    header_lines: list[str]   # diff --git ... index ... --- +++ lines
    hunks: list[Hunk]
    file_type: str = "modified"  # modified | new | deleted | binary


@dataclass
class Instruction:
    file: str
    hunk_index: int           # 1-based
    action: str               # stage | skip | partial | override
    modifier: Optional[str] = None   # staging | staged | comma-list for partial
    override_lines: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Diff parser
# ---------------------------------------------------------------------------

def parse_diff(text: str) -> dict[str, FileDiff]:
    """Parse a unified diff into FileDiff objects keyed by file path."""
    files: dict[str, FileDiff] = {}
    current_file: Optional[FileDiff] = None
    current_hunk: Optional[Hunk] = None
    lines = text.splitlines(keepends=True)
    i = 0

    while i < len(lines):
        line = lines[i]

        if line.startswith("diff --git "):
            # Save previous hunk
            if current_hunk and current_file:
                current_file.hunks.append(current_hunk)
                current_hunk = None

            # Collect file header lines
            header = [line]
            i += 1
            while i < len(lines) and not lines[i].startswith("diff --git ") and not lines[i].startswith("@@"):
                header.append(lines[i])
                i += 1

            # Determine path and type
            path = _extract_path(header)
            ftype = "modified"
            for h in header:
                if h.startswith("--- /dev/null"):
                    ftype = "new"
                elif h.startswith("+++ /dev/null"):
                    ftype = "deleted"
                elif "Binary files" in h:
                    ftype = "binary"

            current_file = FileDiff(path=path, header_lines=header, hunks=[], file_type=ftype)
            files[path] = current_file
            continue

        if line.startswith("@@"):
            if current_hunk and current_file:
                current_file.hunks.append(current_hunk)

            m = re.match(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)", line)
            if not m:
                i += 1
                continue
            old_start = int(m.group(1))
            old_count = int(m.group(2)) if m.group(2) is not None else 1
            new_start = int(m.group(3))
            new_count = int(m.group(4)) if m.group(4) is not None else 1
            suffix = m.group(5)
            current_hunk = Hunk(
                file_path=current_file.path if current_file else "",
                old_start=old_start,
                old_count=old_count,
                new_start=new_start,
                new_count=new_count,
                lines=[line],
                header_suffix=suffix,
            )
            i += 1
            continue

        if current_hunk is not None and line and line[0] in (' ', '+', '-', '\\'):
            current_hunk.lines.append(line)
            i += 1
            continue

        i += 1

    if current_hunk and current_file:
        current_file.hunks.append(current_hunk)

    return files


def _extract_path(header_lines: list[str]) -> str:
    """Extract the b/ path from diff header lines."""
    for line in header_lines:
        if line.startswith("+++ b/"):
            return line[6:].rstrip()
        if line.startswith("+++ /dev/null"):
            # deleted file: get path from --- a/
            pass
        if line.startswith("--- a/") and "+++ /dev/null" in "".join(header_lines):
            return line[6:].rstrip()
    # fallback: parse diff --git a/x b/x
    for line in header_lines:
        if line.startswith("diff --git "):
            m = re.match(r"diff --git a/(.*) b/\1", line)
            if m:
                return m.group(1).rstrip()
    return ""


# ---------------------------------------------------------------------------
# Instruction parser
# ---------------------------------------------------------------------------

def parse_instructions(text: str) -> list[Instruction]:
    instructions = []
    lines = iter(text.splitlines())
    for line in lines:
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        file_path = parts[0]
        hunk_index = int(parts[1])
        action = parts[2]
        modifier = parts[3] if len(parts) > 3 else None

        override_lines = []
        if action == "override":
            for ol in lines:
                ol = ol.rstrip("\n")
                if ol == "---":
                    break
                override_lines.append(ol)

        instructions.append(Instruction(
            file=file_path,
            hunk_index=hunk_index,
            action=action,
            modifier=modifier,
            override_lines=override_lines,
        ))
    return instructions


# ---------------------------------------------------------------------------
# Hunk rewriters
# ---------------------------------------------------------------------------

def rewrite_partial(hunk: Hunk, exclude_lines: set[int]) -> Optional[Hunk]:
    """
    Exclude specific 1-based body line numbers from staging.
    Demotes -/+ pairs to context; drops lone + lines; keeps lone - lines as context.
    Returns None if rewriting is unsafe.
    """
    body = hunk.body
    new_body = []
    old_count = 0
    new_count = 0

    i = 0
    while i < len(body):
        line = body[i]
        lineno = i + 1  # 1-based within body

        if line.startswith("\\"):
            new_body.append(line)
            i += 1
            continue

        if lineno in exclude_lines:
            if line.startswith("-"):
                # Demote removal to context (keep old line)
                new_body.append(" " + line[1:])
                old_count += 1
                new_count += 1
            elif line.startswith("+"):
                # Drop the addition entirely
                pass
            else:
                # Context line excluded? Treat as context anyway
                new_body.append(line)
                old_count += 1
                new_count += 1
        else:
            if line.startswith("-"):
                old_count += 1
            elif line.startswith("+"):
                new_count += 1
            else:
                old_count += 1
                new_count += 1
            new_body.append(line)
        i += 1

    new_header = f"@@ -{hunk.old_start},{old_count} +{hunk.new_start},{new_count} @@{hunk.header_suffix}\n"
    return Hunk(
        file_path=hunk.file_path,
        old_start=hunk.old_start,
        old_count=old_count,
        new_start=hunk.new_start,
        new_count=new_count,
        lines=[new_header] + new_body,
        header_suffix=hunk.header_suffix,
    )


def rewrite_override_staging(hunk: Hunk, override_lines: list[str]) -> Optional[Hunk]:
    """
    modifier=staging: replace the + lines in the hunk with the provided + lines.
    The provided lines must start with + or -.
    + lines replace existing + lines in order.
    - lines cause the corresponding - line to be treated as context (not removed).
    """
    # Collect the intended staged lines from the override block
    additions = [l[1:] for l in override_lines if l.startswith("+")]
    removals_to_keep = [l[1:] for l in override_lines if l.startswith("-")]

    body = hunk.body
    new_body = []
    old_count = 0
    new_count = 0
    add_iter = iter(additions)

    for line in body:
        if line.startswith("\\"):
            new_body.append(line)
            continue

        if line.startswith("+"):
            # Replace with next override addition, or drop if no more
            try:
                replacement = next(add_iter)
                if not replacement.endswith("\n"):
                    replacement += "\n"
                new_body.append("+" + replacement)
                new_count += 1
            except StopIteration:
                # No more replacements — drop this + line
                pass
        elif line.startswith("-"):
            content = line[1:]
            if content in removals_to_keep:
                # Keep as context
                new_body.append(" " + content)
                old_count += 1
                new_count += 1
            else:
                new_body.append(line)
                old_count += 1
        else:
            new_body.append(line)
            old_count += 1
            new_count += 1

    new_header = f"@@ -{hunk.old_start},{old_count} +{hunk.new_start},{new_count} @@{hunk.header_suffix}\n"
    return Hunk(
        file_path=hunk.file_path,
        old_start=hunk.old_start,
        old_count=old_count,
        new_start=hunk.new_start,
        new_count=new_count,
        lines=[new_header] + new_body,
        header_suffix=hunk.header_suffix,
    )


def rewrite_override_staged(hunk: Hunk, override_lines: list[str]) -> Optional[Hunk]:
    """
    modifier=staged: modify what the index looks like after staging.
    + lines: add these lines to the staged result (append as additions).
    - lines: remove these lines from the staged result (add as removals).
    This is essentially editing the hunk body directly.
    """
    # For now: treat override_lines as direct replacements for the hunk body's +/- lines
    # - lines in override = lines to remove from index (add as - in patch)
    # + lines in override = lines to add to index (add as + in patch)
    body = hunk.body
    new_body = []
    old_count = 0
    new_count = 0

    # Keep context lines, replace change lines with override
    context_lines = [l for l in body if l.startswith(" ") or l.startswith("\\")]
    for l in context_lines:
        new_body.append(l)
        old_count += 1
        new_count += 1

    for ol in override_lines:
        if ol.startswith("+"):
            new_body.append(ol + "\n" if not ol.endswith("\n") else ol)
            new_count += 1
        elif ol.startswith("-"):
            new_body.append(ol + "\n" if not ol.endswith("\n") else ol)
            old_count += 1

    new_header = f"@@ -{hunk.old_start},{old_count} +{hunk.new_start},{new_count} @@{hunk.header_suffix}\n"
    return Hunk(
        file_path=hunk.file_path,
        old_start=hunk.old_start,
        old_count=old_count,
        new_start=hunk.new_start,
        new_count=new_count,
        lines=[new_header] + new_body,
        header_suffix=hunk.header_suffix,
    )


# ---------------------------------------------------------------------------
# Patch assembler
# ---------------------------------------------------------------------------

def assemble_patch(file_diff: FileDiff, hunks: list[Hunk]) -> str:
    if not hunks:
        return ""
    # Drop no-op hunks (pure context — git apply rejects them)
    effective = [h for h in hunks if any(l[0] in ('+', '-') for l in h.body)]
    if not effective:
        return ""
    out = "".join(file_diff.header_lines)
    for hunk in effective:
        out += "".join(hunk.lines)
    return out


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print("Usage: patch_hunk.py <diff-file> < instructions.txt", file=sys.stderr)
        sys.exit(1)

    diff_path = sys.argv[1]
    with open(diff_path) as f:
        diff_text = f.read()

    instructions_text = sys.stdin.read()

    files = parse_diff(diff_text)
    instructions = parse_instructions(instructions_text)

    # Group instructions by file
    by_file: dict[str, list[Instruction]] = {}
    for inst in instructions:
        by_file.setdefault(inst.file, []).append(inst)

    result_patch = ""

    for file_path, file_diff in files.items():
        insts = by_file.get(file_path, [])
        # Default: stage all hunks not explicitly mentioned
        inst_map = {i.hunk_index: i for i in insts}

        staged_hunks = []
        skipped = []

        for idx, hunk in enumerate(file_diff.hunks, start=1):
            inst = inst_map.get(idx)

            if file_diff.file_type == "binary":
                skipped.append((idx, "binary file — stage manually"))
                continue

            if inst is None or inst.action == "stage":
                staged_hunks.append(hunk)

            elif inst.action == "skip":
                skipped.append((idx, "skipped per instruction"))

            elif inst.action == "partial":
                if not inst.modifier:
                    skipped.append((idx, "partial action missing exclude line numbers"))
                    continue
                exclude = set(int(x) for x in inst.modifier.split(","))
                rewritten = rewrite_partial(hunk, exclude)
                if rewritten:
                    staged_hunks.append(rewritten)
                else:
                    skipped.append((idx, "partial rewrite failed — stage manually"))

            elif inst.action == "override":
                modifier = inst.modifier or "staging"
                if modifier == "staging":
                    rewritten = rewrite_override_staging(hunk, inst.override_lines)
                elif modifier == "staged":
                    rewritten = rewrite_override_staged(hunk, inst.override_lines)
                else:
                    skipped.append((idx, f"unknown override modifier: {modifier}"))
                    continue
                if rewritten:
                    staged_hunks.append(rewritten)
                else:
                    skipped.append((idx, "override rewrite failed — stage manually"))

            else:
                skipped.append((idx, f"unknown action: {inst.action}"))

        if staged_hunks:
            result_patch += assemble_patch(file_diff, staged_hunks)

        for idx, reason in skipped:
            print(f"# skipped {file_path} hunk {idx}: {reason}", file=sys.stderr)

    sys.stdout.write(result_patch)


if __name__ == "__main__":
    main()


# ---------------------------------------------------------------------------
# Examples (basis for future unit tests)
# ---------------------------------------------------------------------------
#
# All examples use the fixture diff at /tmp/opencode/test.diff.
#
# Fixture: three-hunk diff of file.py
#   hunk 1 — adds `z = 3` to foo()      (body + line at index 3)
#   hunk 2 — adds `c = 30` to bar()     (body + line at index 11)
#   hunk 3 — adds `q = 200` to baz()    (body + line at index 11)
#
# --- Example 1: selective stage (stage 1+3, skip 2) ---
#
# instructions:
#   file.py\t1\tstage
#   file.py\t2\tskip
#   file.py\t3\tstage
#
# expected stdout: valid patch containing hunks 1 and 3 only
# expected stderr: "# skipped file.py hunk 2: skipped per instruction"
# after `git apply --cached`: git diff --cached shows +z=3 and +q=200, no c=30
#
# --- Example 2: override staging — replace added line content ---
#
# instructions:
#   file.py\t1\tskip
#   file.py\t2\toverride\tstaging
#   +    c = 99
#   ---
#   file.py\t3\tskip
#
# expected stdout: valid patch for hunk 2 with `+    c = 99` instead of `+    c = 30`
# expected stderr: skipped 1 and 3
# after `git apply --cached`: git diff --cached shows +c=99 only
#
# --- Example 3: no instructions — default stage all ---
#
# instructions: (empty stdin)
#
# expected stdout: full patch with all three hunks verbatim
# expected stderr: (empty)
# after `git apply --cached`: git diff --cached shows +z=3, +c=30, +q=200
#
# --- Example 4: partial hunk — exclude the only + line (produces no-op) ---
#
# instructions:
#   file.py\t1\tskip
#   file.py\t2\tpartial\t11
#   file.py\t3\tskip
#
# expected stdout: empty  (no-op hunk dropped; git apply would reject pure-context patch)
# expected stderr: skipped 1 and 3; hunk 2 emits no output (silent drop)
# after pipe to git apply: "No valid patches in input" error from git — expected, nothing staged
# caller guard: check stdout is non-empty before piping, or use `git apply --allow-empty`
