# Quality Criteria — Skills

1. **Goal clarity** — Is Goal one sentence and unambiguous?
2. **Step structure** — Are all Steps ordered and each starting with verb? Are there decision points without branch?
   Named steps/phases required when: 3+ top-level phases or steps, 3+ steps within any phase, or any step references another (even if fewer than 3 items).
   Named steps: definition `1. **Name**` (bold), reference `*Name*` (italic).
   Named phases: definition ``## N. `Phase:Name` — description`` header, reference `` `Phase:Name` ``.
3. **Rule strength** — Are Rules using "must"/"never"? Guidelines using "prefer"/"avoid"?
4. **Output specification** — Is expected output concrete? Is there fenced example if applicable?
5. **Resources** — Are needed resource directories (`refs/`, `scripts/`, etc.) identified?
   List all files under `$skilldir` except `SKILL.md` (use `glob`); verify each has a conditional load trigger in `SKILL.md` or another ref file.
   Flag any file with no corresponding trigger — it is unreachable dead weight.
6. **Scope** — Does skill do more than one job? If so, flag it.
7. **Progressive disclosure** — Is context loaded at right tier?
   - Is anything in `SKILL.md` only needed in specific sub-scenario? If so, flag as candidate for extraction.
   - Is anything in reference file needed on every invocation? If so, flag as candidate to inline.
   - Every reference file must have conditional trigger in `SKILL.md` — is each trigger specific and unambiguous?
     Trigger like "read X if you need more detail" is too vague; must name concrete scenario.
8. **Trigger style** — Does `description` clearly encode when/how the skill loads?
   Is the trigger style consistent with the taxonomy in `trigger-styles.md` (crafter skill)?
   If skill has a companion command: is the command a thin launcher (no extraction logic)?
9. **Structured inputs** — If skill extracts structured inputs from free-form context:
   - Is there a `## Setup` section as the first section of the skill body?
   - Does `## Setup` extract every input from context with no assumption about the caller?
   - Does every input have either a default or a "required" declaration?
   - If a required input is absent: does skill stop and tell the user what is missing?
   - Are resolved values stated in a fenced `text` block for later phases to reference?
10. **Computed vars** — If skill computes values used across multiple steps/phases:
   - Is there a declaration block before the first step that uses each var?
   - Does each var's defining step include derivation logic?
   - Do later steps reference vars by name rather than re-deriving from raw context?
11. **Flow correctness** — If skill has multiple flows (e.g. create vs. update, or sub-scenarios):
   - Does each flow disclose only what it needs?
   - Is there content loaded unconditionally that only applies to one flow?
   - Are skip/fast-exit guards present and inline (not buried in reference file)?
