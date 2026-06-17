# Quality Criteria — Skills

1. **Goal clarity** — Is Goal one sentence and unambiguous?
2. **Step structure** — Are all Steps ordered and each starting with verb? Are there decision points without branch?
   Named steps/phases required when: 3+ top-level phases or steps, 3+ steps within any phase, or any step references another (even if fewer than 3 items).
   Named steps: definition `1. **Name**` (bold), reference `*Name*` (italic).
   Named phases: definition ``## Phase N: `Phase:Name` — description` header``, reference `` `Phase:Name` ``.
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
8. **Flow correctness** — If skill has multiple flows (e.g. create vs. update, or sub-scenarios):
   - Does each flow disclose only what it needs?
   - Is there content loaded unconditionally that only applies to one flow?
   - Are skip/fast-exit guards present and inline (not buried in reference file)?
