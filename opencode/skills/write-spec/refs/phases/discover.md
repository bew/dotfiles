# Phase:Discover

Gather all inputs needed to write the spec.
Do not begin drafting until all required inputs are answered or explicitly waived.

## Required inputs

1. **Name** — what is this spec about? (may be a system, concept, protocol, format, etc.)
   The name might be temporary or not yet settled — that's fine;
   it can be renamed later (see Renaming below).
2. **Slug** — short kebab-case identifier derived from the name; used as `$slug` and directory name.
   Suggest a slug from the name; let user confirm or override.
3. **Problem** — what does it solve, and for whom?
4. **Inspirations** — any prior art, external systems, or prior sessions that shaped the design?

If user has supplied most context inline, confirm/waive inputs quickly
rather than asking each one explicitly.

Once all required inputs are answered or waived, proactively move to path derivation
and signal readiness to draft — do not keep asking follow-up questions.

## Path derivation

Once inputs are confirmed:

```
$basedir  = _WIP_SPECS/             (default; relative to project root or cwd)
$slug     = <confirmed-slug>
$specdir  = $basedir/<slug>/
$specpath = $specdir/SPEC.md
```

Tell user the resolved `$specpath` before proceeding.
Create `$specdir` if it does not exist.

NOTE: `$basedir` is `_WIP_SPECS/` unless user explicitly requests `_SPECS/` at this stage.
Promotion to `_SPECS/` happens later, at the end of `Phase:Review`.

## Renaming

If the spec's name or slug needs to change later (name was temporary, concept was renamed, etc.):
Read <../rename.md> for steps — it handles git-tracked and plain directories via a script.

Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)
