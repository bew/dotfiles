## 4. `Phase:Finalize` — readiness check + fill in the blanks

The file already exists in draft state; `Phase:Finalize` completes it.

**Readiness checklist**:
- Every milestone has a single, named concern (no fat milestones).
- No milestone mixes make-it-work and make-it-safe/right concerns.
- Every milestone has an **Ordering reason** field that explains its placement.
  - Milestones that bundle multiple concerns include explicit justification for the bundling.
- Every shared component that is large or multi-faceted is an explicit deliverable with
  its own verification criteria.
- Every configuration or naming scheme that others depend on is an explicit deliverable.
- CI setup is not deferred past the first milestone that produces testable output.
- Make-it-work → make-it-right → make-it-fast order is respected.
- M1 is a research milestone if any spec assumptions are unconfirmed.
- Each milestone is independently verifiable without depending on a later milestone.

If any item fails: return to `Phase:Discuss` and resolve before continuing.

Then fill in the blanks:
- Complete the missing fields per milestone: **Finished**, **Proof**, **Tasks**.
- Backfill any still-pending **Ordering reason** from the ordering decisions already
  confirmed in `Phase:Discuss`.
- Strip `(draft)` from each section header and from the dependency graph header,
  turning `## M<N> — <topic> (draft)` into `## M<N> — <topic>`.

The ordering and grouping rules are applied throughout `Phase:Draft` and `Phase:Discuss`;
nothing is applied here — the checklist above is the final consistency gate.

For updates: edit only the affected milestones; leave the rest untouched.
