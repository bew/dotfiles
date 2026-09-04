---
name: write-code-generic
description: |
  General code writing guidelines: structure, naming, comments, error handling, and organization.
  Always load when the task drafts/writes/edits/refactors/reviews ANY code file — regardless of language, framework, or tool; module or script; including config-as-code.
  Applies to large files and small mechanical edits alike — do not skip based on perceived triviality.
  Load this before any write-code-* skill.
  Language-specific skills build on top of it.
metadata:
  maintainers: [bew]
---

NOTE: This skill is a reference rule-set, not a workflow — no Steps section.

## Goal

Apply consistent structure, naming, and error-handling conventions when writing code files.

## Module code vs Script code

Both are code — but they differ in how they're used:

**Module code** — files imported, required, or sourced by other code (libraries, modules,
helpers). Not run directly.
When working on **module code**, read <./module-rules.md> before writing.

**Script code** — standalone executable entrypoints, run directly (shebang, `main` called at
end of file, or language-level entrypoint guard).
When working on **script code**, read <./script-rules.md> before writing.

**No executable-script concept** — some languages and config formats (e.g. Nix, JSON/YAML
config-as-code) are purely declarative or expression-based: every file is module-like. For
these, the generic module rules apply to all files and the script rules are N/A.

All extend the rules below.

## Rules

- Use descriptive function names with a verb (e.g. `parse_args`, `check_format`).
- Add a short comment above every function explaining its purpose or why it exists.
  One line is enough for simple helpers.
  A few lines for non-obvious ones.
- Inline comments inside function bodies must explain *why*, not *what*.
  Skip comments that restate what the code already says (unless said code is non-trivial).
  Write them when the intent, constraint, or reason is not obvious from the code alone.
  Exception: structural signpost comments are allowed when a function body or file has multiple
  sections/phases/logical-blocks of code — they aid navigation without restating code.
  For non-trivial code blocks (loops with inner computation, iterator chains, match arms with
  branching logic), add a comment for each logical phase — not just one for the block as a whole.
- Top-level constants: SCREAMING_SNAKE_CASE, defined at top of file after header/imports.
- No trailing whitespace — no trailing spaces or tabs at the end of any line,
  and no lines that contain only whitespace.
- Use type annotations for parameters and variables whenever the language supports it.
  Prefer explicit types over implicit ones — they serve as inline documentation.
- Sentences in comments start on a new line.
  Do not chain multiple sentences on a single line unless they fit the remaining line width
  without wrapping.
- When a function receives 4 or more related data inputs, prefer to group them into a named
  struct/record/object rather than passing them as individual parameters. (ask user if unsure)

## Guidelines

- Prefer `get_*` for functions that compute/return a value.
- Prefer `check_*` for validation functions.
- Prefer `parse_*` for argument/input parsing.
- Section separators may be used when file has 5+ functions/structs/enums.
  Usually not needed for smaller files.
  Format: (example for language with '//' prefix for comments)
  ```
  // -------------------------------------------------------
  // Section title
  ```
  The dashes line goes above the title, never below it.
  A blank line is added both before & after the section comment.

### CLI naming

- CLI-exposed names (commands, flags, subcommands) must reflect user-facing concepts.
  Not internal implementation details: a user runs `refresh`, not `refresh-async`.
