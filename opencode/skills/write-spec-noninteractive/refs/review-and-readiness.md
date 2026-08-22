# Review pass and readiness

## Review pass

After all sections are filled, check:

- All Open Questions (per-section and Global) are marked **Blocking** or **Non-blocking**
- Introduction is complete prose (no skeleton placeholders)
- Terminology section (if present) is complete prose (no skeleton placeholders)
- If Terminology section exists: all terms used in spec are defined there before first use
- No terminology drift — single canonical name used everywhere for each concept
- `## Global Open Questions` section is present at end of spec
- No empty `### Open Questions` subsections remain (Global section is exempt — it is always present)
- `FIXME:` callouts are allowed as design signals — they do not block readiness.
  If a callout is not specific to its surrounding text, move it to Open Questions instead.
- Prose in touched sections follows sentence-per-line format
- Status tag in H1 reflects current state (set to `[DRAFT]` on creation; preserved on updates)

Flag any issues found; note them in the deferred questions block if they require user input.

## Readiness criteria

Assess readiness after the review pass.
State which criteria pass and which fail — do not update the H1 tag.

1. Introduction is complete prose — no placeholders.
   Terminology section (if present) is also complete prose.
2. Any unfocused `FIXME:` callouts moved to Open Questions (focused ones may remain).
3. All Open Questions (per-section and Global) marked **Blocking** or **Non-blocking**.
4. No **Blocking** Open Questions remain unresolved.
   Global entries default to **Non-blocking**; they must be escalated to Blocking explicitly during review to block readiness.
5. Alternatives & Tradeoffs section present and honest.
6. No synonym drift.
   If Terminology section exists, all terms defined there before use.
7. Spec reflects current design intent — surface as a deferred question: *"Does this spec reflect your current design intent?"*

If all criteria 1–6 pass and the only deferred question is criterion 7:
note that the spec may be ready to mark `[READY]` manually once the author confirms design intent.
Then output the deferred questions block (see `## Deferred questions` below).

## Deferred questions

After the full draft is written and readiness assessed,
output a single batched list of all questions that require user input.
Do not ask questions mid-pass.

Format:

```md
## Questions for you

1. <question about unresolved design decision>
2. <question about missing input>
3. …
```

Include only genuinely open questions.
Omit if no questions remain.
