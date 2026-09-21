# Incremental round

Stop-at-section round for `incremental` mode.

Runs after a section has been filled, before the user's confirmation to advance.
Does not apply to `batch` mode.

## Steps

1. **Finalize section** — replace the section's `SKELETON TODO` placeholder with its body;
   never leave the comment behind.
2. **Report** — note what was written and any Open Questions surfaced.
3. **OQ round** — ask about the OQs surfaced in this section (see *OQ round* below).
   Skip this step when the section surfaced no OQ, or when the `question` tool is unavailable.
   When unavailable, do not ask the OQs in chat instead — go straight to *Feedback prompt*.
4. **Feedback prompt** — print:
   > <mode banner>
   >
   > Feedback on this section?
5. **Remaining sections** — list them, headings only, no overview lines.
6. **Continue instructions** — print:
   > Say 'next' or similar to continue with the next section.
   > Say 'what's next' to list upcoming sections with their planned content.
   > Say 'fill the rest'/'write all' to switch to batch mode.

## OQ round

Emit one `question` tool call with one question per OQ entry surfaced in this section.
If the tool accepts only one question per call, issue them sequentially within the same OQ round.
Options per question:
- All relevant candidate resolutions inferable from the spec context — any number.
- The defer option: `Defer — keep OQ in spec for now`.
- For a **Blocking** OQ: a `Downgrade to Non-blocking` option, unless the OQ is genuinely blocking.

Do not add a freeform/custom answer option — the `question` tool provides one itself.
Do not add an "other"/catch-all option.

Apply each answer:
- Defer → leave the OQ entry unchanged in the spec.
  Deferral is deliberate and legitimately carried forward.
- Downgrade → change the entry from **Blocking** to **Non-blocking**; keep the entry.
- Answered → resolve it: apply the resolution wherever it affects content, which may span sections
  (update all filled affected sections for consistency); then remove the OQ entry if fully answered,
  or narrow it if partially answered.
  If an answer affects a not-yet-filled section, do not edit its `SKELETON TODO` placeholder —
  apply the resolution when that section is filled.

After the answers are processed, continue to *Feedback prompt*.

## What's next

A 'what's next' utterance is informational.
List remaining sections with each section's `SKELETON TODO` overview line, so the user sees planned
content, not just headings.
Do not treat it as section feedback, do not advance, do not switch mode.
After listing, re-issue the continue instructions and wait.

A question that merely contains the word 'next' is not the confirm token — answer it, then re-issue
the prompt and wait.
