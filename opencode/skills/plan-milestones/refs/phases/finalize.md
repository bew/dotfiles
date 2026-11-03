## 4. `Phase:Finalize` — readiness check, fill in the blanks, and emit task files when chosen

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
- Complete **Finished** and **Proof** per milestone.
- Complete **Tasks** only when the destination chosen in `Phase:Discuss` is inline.
  In task-file mode, skip it here — the task-file step below writes the link.
- Backfill any still-pending **Ordering reason** from the ordering decisions already
  confirmed in `Phase:Discuss`.
- Strip `(draft)` from each section header and from the dependency graph header,
  turning `## M<N> — <topic> (draft)` into `## M<N> — <topic>`.

The ordering and grouping rules are applied throughout `Phase:Draft` and `Phase:Discuss`;
nothing is applied here — the checklist above is the final consistency gate.

**Task files** _(only when chosen in `Phase:Discuss`)_:

Skip this step in inline mode.

Resolve:
- **$taskdir** — where the task files go.
  Default: the plan's directory (`dirname $milestonesfile`).
  Ask the user when the plan spans several directories.
- **$namespace** — the namespace that groups these tasks.
  Derive from the plan source: the spec or plan directory name, with a leading `SPEC-<STATUS>-`
  segment stripped.
  e.g. `SPEC-DRAFT-wrapkit-system` → `wrapkit-system`.
  When the plan is not spec-driven, use the plan directory name.
  Confirm the value with the user before writing.

For each new or changed milestone:
- Write `$taskdir/$taskfilename` per <../file-task-form.md> — `$taskfilename` is defined there.
  When the milestone already links a task file, update that file.
- Add or update the link in the milestone's **Tasks** field.
- Track each new file with the environment's track-new-file tool (e.g. `git_track_new_file`).
  Never run `git add` by hand.

If a file must be created at a path that already exists: stop and ask the user for a new namespace;
never overwrite.

Report each created or updated file by path — one line per file.
Never output file content inline.

For updates: edit only the affected milestones; leave the rest untouched.
