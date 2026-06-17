---
description: |
  Quality criteria and review checklist for OpenCode artefacts (skills, agents, commands).
  Invoked by opencode-reviewer agent.
  Not for direct use.
metadata:
  maintainers: [bew]
---

# Quality Criteria for OpenCode Artefacts

## Goal

Provide quality criteria for reviewing OpenCode artefacts.
Type-specific criteria loaded on demand.

## Universal criteria (all artefact types)

Check these first, regardless of artefact type.

1. **Description trigger** — Is `description` specific enough to trigger correctly — not too broad, not too narrow?
2. **Frontmatter completeness** — Is every relevant frontmatter field present and valid?
3. **Writing & structural rules** — Does body conform to the writing-rules and steps/phases/headers rules files already loaded in context?
   Check: tone, sentence-per-line, example format, formatting rules, named steps/phases syntax, header anchors.
4. **Missing rules** — Is there anything artefact should always/never do? Any precondition it should verify before acting?
5. **Edge cases** — What happens when required file is missing? When tool returns an error?
6. **Re-locatability** — Check that no paths point outside of `$draftpath` (like: /foo or ~/foo or ../foo).
   Referencing other artefacts by name is fine.
7. **Reference integrity** — For every `§slug` reference in any file under `$draftpath`:
   - Same-file ref (`§slug`): a matching `<!-- §slug -->` anchor must exist in that file.
   - Cross-file ref (<./path/to/file.md§slug>): target file must exist and contain `<!-- §slug -->`.
   Flag dangling references (no anchor) and dead anchors with no reference.

## Type-specific criteria

Based on artefact type, read the appropriate file for additional criteria:

- skill: read <./refs/skills.md>
- agent: read <./refs/agents.md>
- command: read <./refs/commands.md>
