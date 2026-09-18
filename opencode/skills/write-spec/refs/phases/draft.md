# Phase:Draft

Write the spec to `$specpath`, filling sections iteratively.
Read <../spec-structure.md> for section order and Open Questions format.
Read <../writing-guidelines.md> for prose style, Interface / How to use conventions, and naming discipline.

## Initial Skeleton

Before writing anything: list the sections that will be created
(based on <../spec-structure.md> section order, adapted to what's known about the spec so far).
If the chosen design has meaningful sub-variants, include the optional design-options section in the list.

Ask: *Sections look right? Say 'next' to start writing.*
Print the `<mode banner>`: `Mode: incremental (one section per turn)`.
The `incremental` mode is the default — one section per turn, pausing after each.
Say 'step by step' to assert it.
Say 'fill the rest'/'write all' to batch the rest.
Adjust section list if user requests changes.

Once confirmed, write the file: H1 with status tag + skill loader meta-paragraph
(for any non-READY status) + all confirmed section headings, empty bodies.
Each main section (`##`) that may surface open questions gets an empty `### Open Questions` subsection.
Use `write` tool for this initial creation only.
All subsequent changes use `edit` only — never overwrite the file again.

H1 format:
```md
# [DRAFT] <Name>
```
Immediately followed by the skill loader meta-paragraph for any non-READY status — see skeleton example below.

Skeleton example (sections with OQ subsections):
```md
# [DRAFT] <Name>

> IMPORTANT: Before any drafting/planning/editing of this spec,
> agents MUST load one of the spec-writing skill first.

## Introduction

## <Domain Section>

### Open Questions

## <Another Decision Section>

### Open Questions

## Global Open Questions

**Terminology & Key Concepts** (TKC) — Whether this section is needed for this spec.
Non-blocking. Refer to spec-writing skill for guidance.
```

Omit `### Open Questions` from Introduction — it is a definitional/contextual section, not a decision surface.
Omit from Terminology section (if present) for the same reason.
Omit from sections unlikely to surface design decisions (e.g. Component Inventory, Related Artifacts).

## Global Open Questions

`## Global Open Questions` is always appended at end of spec.
It is not a decision surface — it holds deferred questions that span the whole spec.
Do not add a `### Open Questions` subsection inside it.

### Default entries

Include these entries verbatim in the skeleton:

```
**Terminology & Key Concepts** (TKC) — Whether this section is needed for this spec.
Non-blocking. Refer to spec-writing skill for guidance.
```

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

### Modes

Two fill modes exist.

**incremental** (default) — fill exactly one section per turn, then STOP and wait for user input.
A plain 'next' confirm enters it.
Never fill a second section in the same turn, even if it is small or the design feels settled.
The pause is mandatory; never skip or batch it.
If the user names or selects several sections at once (e.g. answers a multi-select question with several),
treat it as an ordered queue, not a batch: still fill exactly one section per turn and pause between each.

**batch** — fill all remaining sections in one pass, with no per-section pause.
Reached only via the exit aliases below; sticky until a trigger alias re-enables incremental.
The initial skeleton write is its own step and is not affected by the mode.

Trigger aliases (each means *confirm + enter/assert incremental mode*):
'step by step', 'go incrementally', 'step-by-step', 'section by section', 'incr', 'incr mode'.

Exit aliases (each switches from incremental to batch, sticky):
'fill the rest', 'write all'.
In batch mode the user may say a trigger alias (e.g. 'step by step') to re-enable incremental.

### Fill loop

Every prompt starts with the active `<mode banner>`.
In incremental mode, print `Mode: incremental (one section per turn)`.
In batch mode, print `Mode: batch`.

NOTE: Earlier sections may be edited freely at any point, if needed.

Add open questions to the section's own `### Open Questions` subsection immediately — do not defer.

On edit failure: re-read `$specpath`, locate current state, resume.

After filling a section (incremental mode only):
- Note what was written and any open questions surfaced.
- Tell user:
  > <mode banner>
  >
  > Feedback on this section?
- List the remaining sections still to fill.
- Print:
  > Say 'next' or similar to continue with the next section.
  > Say 'fill the rest'/'write all' to switch to batch mode.

In batch mode, skip the per-section prompt above — fill all remaining sections,
then run the *After all sections are filled* steps.

The user's response should be handled as feedback by default.
Only 'next' or a trigger alias can be interpreted as signal to move on.
'fill the rest'/'write all' switches to batch mode (sticky) for the remaining sections.

If the user says 'tell me more' (or a listed alias): answer in output only.
Do not edit `$specpath`, do not treat it as section feedback, do not advance,
and do not switch to a different mode.
Then re-issue the prompt and wait.

After all sections are filled:
1. Prune empty `### Open Questions` subsections — remove any that have no entries.
2. Tell user:
   > <mode banner>
   >
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

- In `incremental` mode, never fill more than one section per turn.
  The pause after each section is mandatory — do not skip it nor batch it.
  A user answer that names or selects several sections is a queue, not a batch authorization.
- `incremental` is the default/canonical mode.
- Never write full rewrite when targeted edit is requested. Surgical edits only.
- Never paper over unresolved decisions. Surface them in Open Questions.
- Never mix terminology once terms are defined.
  If Terminology section exists, use exact names from there everywhere.
- Terminology section (if present): define all terms there before using them elsewhere in spec.
- `## Global Open Questions` is always included. Default entries included verbatim in skeleton (see Default entries above).
  Do not prune it even if empty (unless spec is marked as READY) — it is a structural fixture.
- The skill loader meta-paragraph (between H1 and first section) is required
  for all non-READY statuses.
  It is removed only on promotion to READY.
  If refining a spec with a non-READY status, ensure the meta-paragraph is
  present (add it if missing).
- Always include `### Open Questions` subsections in main sections that may surface design decisions.
  Never add OQ subsections to Introduction or Terminology (if present) — they are not decision surfaces.
  Empty OQ subsections serve as drafting placeholders — prune them before leaving `Phase:Draft` (see *Filling* above).
- Always include Alternatives & Tradeoffs section comparing proposed design
  against simpler alternative.
- When omitting a section, flag it explicitly: name section and state reason it was skipped.
- When a config field's value may depend on runtime state, ask user whether it should be a
  plain value or a function called lazily at first use.
  If a function: note in spec when it is called and whether result is cached.

Ready to move to `Phase:Review`? (say 'next' or similar to proceed)
