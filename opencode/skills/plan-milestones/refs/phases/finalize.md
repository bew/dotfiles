## 4. `Phase:Finalize` — readiness check, fill blanks, scope boundary tasks into files

The file already exists in draft state; `Phase:Finalize` completes it.

**Readiness checklist**:
- Every milestone has a single, named concern (no fat milestones).
- No milestone mixes make-it-work and make-it-safe/right concerns.
- Every in-window milestone has an **Ordering reason** field that explains its placement.
  - Milestones that bundle multiple concerns include explicit justification for the bundling.
- Every backlog entry is a lone topic bullet — no numbers, no edges, no milestone fields.
- Every shared component that is large or multi-faceted is an explicit deliverable with
  its own verification criteria.
- Every configuration or naming scheme that others depend on is an explicit deliverable.
- CI setup is not deferred past the first milestone that produces testable output.
- Make-it-work → make-it-right → make-it-fast order is respected.
- M1 is a research milestone if any spec assumptions are unconfirmed.
- Each milestone is independently verifiable without depending on a later milestone.

If any item fails: return to `Phase:Discuss` and resolve before continuing.

Then fill in the blanks:
- Complete **Goal**, **Finished**, and **Proof** per ordered milestone.
- Complete **Tasks** for every ordered milestone — scoped links or rough bullets, per the
  task-file step.
- Backfill any still-pending **Ordering reason** from the ordering decisions already
  confirmed in `Phase:Discuss`.
- Complete the Goal of each backlog entry; leave its `Pinned:` line as written if it has one.
- Strip `(draft)` from each section header and from the dependency graph header,
  turning `## M<N> — <topic> (draft)` into `## M<N> — <topic>`.
  Strip it from `## Backlog (draft)` and from each backlog topic name.

The ordering and grouping rules are applied throughout `Phase:Draft` and `Phase:Discuss`;
nothing is applied here — the checklist above is the final consistency gate.

**Task files**:

- **$taskdir** — `dirname $milestonesfile`. Resolved in `Setup`; next to the plan, no question.
- **$namespace** and `$taskfilename` — see <../file-task-form.md>; that file owns both rules.

Derive work units first: one unit per independently verifiable behavior change named by the
milestone's **Goal** and **Proof**.
Write no task file before the batch's units are listed.

For each milestone in the scoping boundary:
- Write one `$taskdir/$taskfilename` per work unit, per <../file-task-form.md>.
  `$taskfilename` is defined there.
  When the milestone already links a task file for that unit, update that file.
- Set the milestone's **Tasks** field to the ordered link bullets for its units.
- Track each new file with the environment's track-new-file tool (e.g. `git_track_new_file`).
  Never run `git add` by hand.

For each milestone past the boundary:
- Write rough tasks only: plain bullets of task ideas under the `**Tasks** (rough):` label.
  No files, no links.

If a task file path already exists and the milestone does not link it: stop and ask.
Resolve by adjusting the task title — and so its slug — or by confirming the existing file
covers the same unit.
Never overwrite.

Report each created or updated file by path — one line per file.
Never output file content inline.

For updates: edit only the affected milestones; leave the rest untouched.
