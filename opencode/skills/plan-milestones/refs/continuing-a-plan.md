## Continuing an existing plan — promote and scope the next batch

Entry: the user asks to continue an existing plan.
Examples: "order more milestones", "promote backlog items", "define tasks for M3",
"continue scoping tasks".

A milestone holding rough tasks is not executable.
Its bullets are idea notes — scope them into task files before starting the milestone.

### Step 1 — Read the plan

Read `$milestonesfile`.
Resolve `$specpath` from its **Sources** section, `$taskdir` from its location, and
`$orderwindow` from the skill default `5` — do not re-run `Setup`.
Greenfield is inferred from the plan, not re-detected: a first milestone that scaffolds the
project means greenfield — read <./greenfield-plans.md>.
Ask the user when that is ambiguous, or when the first milestone could scaffold a new subsystem
rather than a new project.

### Step 2 — Establish delivery state

The plan file records no delivery state, so ask the user which milestones are delivered.
That sets the delivery edge — the last delivered milestone.

### Step 3 — Promote backlog topics

Count the ordered milestones past the delivery edge, and promote enough backlog topics to bring
that count up to `$orderwindow`.
Present the promotion set and confirm it before numbering; the user may ask for another size.
A greenfield plan keeps its opening sizing until the two small milestones are past —
see <./greenfield-plans.md>.
Honour every `Pinned:` line when picking the set: a pin naming an ordered milestone forces its
topic's promotion, and a pin it contradicts is surfaced to the user.

A promoted topic becomes a full milestone entry per <./file-final-form.md>: next number, section
header, graph edges, Ordering reason, Finished, and Proof.
Its tasks stay rough unless it lands in the scoping batch.
Regroup it if its scope shifted since it was written; move its `Pinned:` line into the Ordering
reason and drop the line.
A topic that splits in two while regrouping occupies two window positions, so confirm the
overshoot with the user instead of silently exceeding `$orderwindow`.

When an ordered milestone depends on a backlog topic, that topic's promotion is forced and counts
in the presented set.
A forced prerequisite must be numbered below its dependent, which the no-renumber rule forbids.
Stop and ask: renumber the dependent and the milestones after it, or drop the dependency.

When the backlog runs dry, the window stays short; drop the **Backlog** section if nothing
remains.

### Step 4 — Pick the batch

The batch is the rough-task in-window milestones whose dependencies are all delivered.
Do not scope past an undelivered dependency on your own — its scope may shift once that
dependency lands.
When the user names milestones, use that list instead.
An explicit user request overrides the gate.

A startable backlog topic stays unordered until a slot frees; it cannot enter the batch
unscoped, since it has no Finished, Proof, or Tasks yet.

### Step 5 — Scope the batch into task files

Scope each work unit of the batch into <./file-task-form.md> files.
That file owns the filename, `$namespace`, and `depends-on` rules.
Refine the rough bullets into one unit per independently verifiable behavior change named by the
milestone's **Goal** and **Proof**.
Replace the `**Tasks** (rough):` block with the `**Tasks**:` ordered task-file links.
On a path collision: stop and ask — adjust the task title, or confirm the file covers the same
unit.
Never overwrite.
Track each new file with the environment's track-new-file tool (e.g. `git_track_new_file`).
Never run `git add` by hand.

### Step 6 — Leave the rest alone

Leave every other milestone untouched.
No `Phase:Discover`, no `Phase:Draft`, and no renumbering of existing milestones without the
user's approval — the plan already exists.
