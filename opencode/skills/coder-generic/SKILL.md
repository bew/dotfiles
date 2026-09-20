---
name: coder-generic
description: |
  General code writing guidelines: structure, naming, comments, error handling, and organization.
  Always load when the task drafts/writes/edits/refactors/reviews ANY code file — regardless of language, framework, or tool; module or script; including config-as-code.
  Applies to large files and small mechanical edits alike — do not skip based on perceived triviality.
  Load this before any coder-* skill.
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
- Top-level constants: SCREAMING_SNAKE_CASE, defined at top of file after header/imports.
- No trailing whitespace — no trailing spaces or tabs at the end of any line,
  and no lines that contain only whitespace.
- Never install or declare a package, or silently substitute a stdlib/hand-rolled alternative for a
  recommended package, without asking the user first.

## Types

**Naming**
- Name types for their role, not generically (e.g. `BackendRequest` rather than `Request`;
  `AstHeading` rather than `Heading`).
- Give values that share a primitive representation but differ in meaning distinct named types.

**Structured data**
- Represent structured data with a named type — never a loose map/dict/associative array.
- Model external/wire data with a dedicated named type (struct, record, class, or language
  equivalent).
  Keep wire types (matching the serialized schema) distinct from in-process domain types.
- When a function receives 4 or more related data inputs, group them into a named
  struct/record/object rather than passing them as individual parameters. (ask user if unsure)

**Other**
- Use type annotations for parameters and variables whenever the language supports it.
  Prefer explicit types over implicit ones — they serve as inline documentation.
- Prefer the most specific type that expresses what a value *is*.
  A loose primitive — string, number, boolean, map, or top/`any` type — hides meaning and lets
  invalid states pass.
- Encode absence in the type (optional/nullable) instead of a sentinel
  such as `""`, `-1`, or `null`.
- Represent a closed set of values with a dedicated type (enum or equivalent), not a bare primitive.

## Comments & docs rules

### Function documentation

- Every function has documentation (doc comment, docstring, or leading comment — in the
  form the language uses) stating:
  * its contract: goal, parameters, return
  * any non-obvious behavior, refusal condition, or idempotency guarantee a caller must know.
  One line is enough for simple helpers; a few lines for non-obvious ones.
- Document every parameter unless it is truly obvious from the name and signature.
  Document the return when it is not obvious.
- When the language has dedicated syntax for parameter/return docs, place their description
  after the type.
- Implementation details and their rationale never go in the function doc.
  Put them in an inline comment next to the relevant code.
- Never document widely-known language/tool/framework default/expected behavior.
  Only non-obvious quirks a caller needs belong in the doc.

### Inline comments

- Inline comments inside function bodies must explain *why*, not *what*.
  Skip comments that restate what the code already says (unless said code is non-trivial).
  Write them when the intent, constraint, or reason is not obvious from the code alone.
  Exception: structural signpost comments are allowed when a function body or file has multiple
  sections/phases/logical-blocks of code — they aid navigation without restating code.
- For non-trivial code blocks (loops with inner computation, iterator chains, match arms with
  branching logic), add an inline comment for each logical phase not just one for a whole block.
- Sentences in comments start on a new line (semantic line breaks! + Follow lang max line width).
  Do not chain multiple sentences on a single line unless they fit the remaining line width
  without wrapping.

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
