---
name: coder-generic
description: |
  General code writing guidelines: structure, naming, comments, error handling, and organization.
  Always load when the task drafts/writes/edits/refactors/reviews ANY code file —
  regardless of language, framework, or tool; module or script; including config-as-code.
  Applies to large files and small mechanical edits alike —
  do not skip based on perceived triviality.
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
- Name a value for what it represents, not for its storage.
  When two values share a representation but differ in meaning, give each its own unambiguous
  name (e.g. a window handle vs its index, a buffer number vs its name).
  Never use a bare ambiguous noun (`win`, `buf`, `tab`) where a qualified name exists.
- Top-level constants: SCREAMING_SNAKE_CASE, defined at top of file after header/imports.
- Document each top-level constant: its purpose, and its unit when it carries one
  (e.g. "milliseconds", "bytes").
- No trailing whitespace — no trailing spaces or tabs at the end of any line,
  and no lines that contain only whitespace.
- Never install or declare a package, or silently substitute a stdlib/hand-rolled alternative for a
  recommended package, without asking the user first.
- Validate unknown input once, at the boundary that owns it.
  Pass typed values inward instead of re-checking what a schema, constructor, or internal type
  already guarantees.
- Do not extract a single-use helper preemptively.
  Inline it at the call site unless it is reused, hides a genuinely complex boundary, or names a
  concept that improves the caller.
- Prefer early returns.
  Avoid `else`: handle the guard or exceptional case first and let the main path read straight
  through.
- Prefer immutable bindings.
  Avoid reassignment; derive a result rather than mutating a variable.

## Code layout

- When a function signature does not fit the line width, put each parameter on its own line,
  with a trailing comma after the last one.
  Never pack multiple parameters onto a wrapped line.
- In brace-delimited languages, always use block braces for control-flow bodies, even when the
  body is a single statement or `return` — braces leave room for a comment above the line to
  document its behavior.

## Types

**Naming**
- Name types for their role, not generically (e.g. `BackendRequest` rather than `Request`;
  `AstHeading` rather than `Heading`).
- Give values that share a primitive representation but differ in meaning distinct named types.

**Structured data**
- Represent structured data with a named type — never a loose map/dict/associative array.
- Use a library's own named type when it exists and semantically matches the value;
  otherwise declare a custom boundary type for the fields you actually consume.
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
- Never write a bare map/dict, `any`, or top type where a named type can be written.
  Reuse a standard/builtin named type from the language or an imported library when one fits.
- Encode absence in the type (optional/nullable) instead of a sentinel
  such as `""`, `-1`, or `null`.
- Represent a closed set of values with a dedicated type (enum or equivalent), not a bare primitive.

## Comments & docs rules

### Semantic line breaks

- Every comment — file header, function documentation, and inline — uses semantic line breaks:
  each sentence starts on its own line.
- Keep comment lines within about 100 columns.
  When a language skill states its own max width, that one wins.

### Function documentation

- Every function has documentation (doc comment, docstring, or leading comment — in the
  form the language uses) stating:
  * its contract: goal, parameters, return
  * any non-obvious behavior, refusal condition, or idempotency guarantee a caller must know.
  One line is enough for simple helpers; a few lines for non-obvious ones.
- Document every parameter unless it is truly obvious from the name and signature.
  Document the return when it is not obvious.
- Document obscure positional parameters at their use sites, but remember that named arguments
  are self-documenting: prefer APIs that take named/structured arguments over long positional
  lists (see Guidelines).
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
- For an assignment that changes state (module, object, or global), write WHY the mutation
  happens when it is not obvious from the guarding condition.

### Dated notes

- Mark missing, incorrect, or surprising behaviour in a dependency with a dated note:
  `@YYYY-MM <note>` (month precision), e.g. `@2026-09 missing type annotation`.
  Use it where the behaviour may change later and the note should be re-checked.
- Do not proactively re-check or update the date/note unless asked.

## Guidelines

- Prefer `get_*` for functions that compute/return a value.
- Prefer `check_*` for validation functions.
- Prefer `parse_*` for argument/input parsing.
- When designing an API, prefer named/structured arguments over a long positional list —
  named args are self-documenting and remove call-site ambiguity.
- When writing or extracting a helper function, design it for reuse by default.
  Make its boundary general rather than shaped to the current call site.
  If a reusable shape is too complex or the boundary is unclear, ask the user before guessing.
- Make the main function read as the happy path.
  Move validation and supporting detail into small named helpers when that clarifies the main path.
- Avoid unnecessary destructuring.
  Access fields with dot notation when it preserves the qualifying name and context.
- Do not use exceptions for expected outcomes; return a value instead.
  Reserve exceptions for truly exceptional failures.
- Before adding complexity for a speculative or vanishingly unlikely race, security, or edge case,
  surface the concrete failure mode, its likelihood, and the complexity cost, and get buy-in first.
- In tests, prefer exercising the real implementation.
  Avoid mocks unless there is no alternative.
- Prefer functional collection transforms over manual index loops where the language supports them.
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
