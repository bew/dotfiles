# Phase:Draft

Write the spec to `$specpath`, filling sections iteratively.
Read <../spec-structure.md> for section order, prose rules, API conventions, and Open Questions format.

## Initial Skeleton

Before writing anything: list the sections that will be created
(based on <../spec-structure.md> section order, adapted to what's known about the spec so far).

Ask: *Sections look right? Say 'next' to start writing.*
Adjust section list if user requests changes.

Once confirmed, write the file: H1 with status tag + all confirmed section headings, empty bodies.
Each main section (`##`) that may surface open questions gets an empty `### Open Questions` subsection.
Use `write` tool for this initial creation only.
All subsequent changes use `edit` only — never overwrite the file again.

H1 format:
```md
# [DRAFT] <Name>
```

Skeleton example (sections with OQ subsections):
```md
## Introduction

## Terminology

## <Domain Section>

### Open Questions

## <Another Decision Section>

### Open Questions
```

Omit `### Open Questions` from Introduction and Terminology — they are definitional/contextual sections, not decision surfaces.
Omit from sections unlikely to surface design decisions (e.g. Component Inventory, Related Files).

## Structure

**Heading hierarchy**: use `##` for top-level spec sections, `###` for sub-topics within a section.
Do not flatten everything to the same level.

**File splitting**: default to a single `SPEC.md`.
Only extract a companion file when a section is large enough that keeping it inline
makes the main spec hard to read.
Companion files supplement — they do not replace readable content in `SPEC.md`.

**Section placement**: before extracting a section into a companion file,
verify the content type matches the file name.
Different concerns belong in separate files
(e.g. CLI behavior and file format are distinct — do not conflate them).

## Filling

Fill one section at a time, then pause.
After filling a section, note what was written and any open questions surfaced.
Wait for user feedback before moving to the next section.
If user says "continue" or similar without feedback, proceed to next section.

Add open questions to the section's own `### Open Questions` subsection immediately — do not defer.

On edit failure (placeholder mismatch): re-read `$specpath`, locate current state, resume.

After all sections are filled:

1. Prune empty `### Open Questions` subsections — remove any that have no entries.
2. Tell user:
   > Draft written to `$specpath` — open to inspect and share review feedback.

## Refinement

When refining an existing spec (not a new draft):

1. Read full `$specpath` first.
2. Apply only requested changes — do not restructure unrelated sections.
3. When a rule change affects multiple sections, update all affected sections for consistency.
4. After edits, verify prose still follows sentence-per-line format in touched sections.
   If any violation found, flag to user: fix silently / fix with confirmation / leave as-is.

## New scope detection

During iteration, if user introduces a new idea, constraint, or design angle not covered in `Phase:Discover`
(signals: "what if…", "could we…", "idea:", "🤔", or a concept absent from prior discovery):
- Pause drafting.
- Ask: *"This looks like new scope — do a quick discover loop before writing it in?"*
- Do not silently absorb new inputs into spec content.
- If user confirms: return to `Phase:Discover` for the new scope, then resume `Phase:Draft`.

## Rules

- Never write full rewrite when targeted edit is requested. Surgical edits only.
- Never paper over unresolved decisions. Surface them in Open Questions.
- Never mix terminology once terms are defined in Terminology.
  Use exact names from Terminology everywhere.
- Always define all terms in Terminology before using them elsewhere in spec.
- Always include `### Open Questions` subsections in main sections that may surface design decisions.
  Never add OQ subsections to Introduction or Terminology — they are not decision surfaces.
  Empty OQ subsections serve as drafting placeholders — prune them before leaving `Phase:Draft` (see *Filling* above).
- Always include Alternatives & Tradeoffs section comparing proposed design
  against simpler alternative.
- When omitting a section, flag it explicitly: name section and state reason it was skipped.
- When a config field's value may depend on runtime state, ask user whether it should be a
  plain value or a function called lazily at first use.
  If a function: note in spec when it is called and whether result is cached.

Ready to move to `Phase:Review`? (say 'next' or similar to proceed)
