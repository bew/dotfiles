## 2. `Phase:Draft` — sketch milestones by topic name

Sketch the milestones as a named list — topic names only, no numbers yet.
Numbers crystallize only after ordering is settled in `Phase:Discuss`.

IMPORTANT: During this phase, always refer to milestones by topic name.

The focused view (see <../discussion-views.md>) supplies each topic's goal so the reader always has
the meaning in front of them.
Example: "does {checkout-core} belong before {remote-registration}?" — the view shows both goals.

For each capability boundary found in `Phase:Discover`, ask targeted placement questions before
grouping.
Ask only what is genuinely ambiguous.

Before each question round, show the focused view (see <../discussion-views.md>) for the topics
the question touches.

Keep questions coarse-grained at this stage: focus on whether a topic is its own milestone and
what its hard blockers are.
Fine-grained ordering and tradeoffs are resolved in `Phase:Discuss`.
Placement questions are weighed against `Milestone ordering rules` and `Grouping heuristics`.

Typical questions:
- Does `{topic}` warrant its own milestone, or is it an extension of `{other-topic}`?
- Should the naive implementation land in `{topic}`, or is it already covered by `{other-topic}`?
- Is this shared component large enough to be a first-class deliverable, or is it implicit
  in the first component that uses it?
- Is this architectural refactor a blocker for the next feature, or can it be deferred?
- Does the persistence layer need a design step, or is the spec sufficient to implement directly?
- Does `{topic}` assume a delivery/output mechanism (send, publish, notify...) that hasn't
  actually been decided yet? Specs often leave the last-mile action (send vs. download vs.
  manual handoff) implicit — surface it explicitly rather than assuming the obvious one.

If the user's answer does not resolve the question as asked — e.g. it reframes the tradeoff,
answers a different question, or introduces a new split — do not silently fold it into the
plan. Restate the reframed structure back to the user in the same focused-view format and get
explicit confirmation before moving on.

Before showing the whole-plan view, do an explicit merge/split pass across the full topic list:
- For each topic, check `Grouping heuristics` — is bundling it with a neighboring topic
  justified? Don't leave 1-topic-per-milestone as a silent default.
- For each topic, check whether it should split across multiple milestones (e.g. a
  make-it-work slice now, a make-it-right/make-it-fast slice later; or part of it blocked on
  something landing after the rest) per `Milestone ordering rules`.
This pass is mandatory even when its conclusion is "no changes" — the point is that the shape
is an explicit decision, not an unexamined default.

After grouping is tentatively settled, show the whole-plan view (see <../discussion-views.md>)
for confirmation — create-from-scratch flow only; in update mode the existing
`$milestonesfile` graph is reviewed from the file instead.
The user confirms this shape before `Phase:Discuss` begins.

----

Once the user explicitly confirmed, write `$milestonesfile` in draft state,
following the format in <../file-format.md> and <../file-draft-form.md>.
For new files: write the **Sources** section first, using `$specpath` and anything tracked
during `Phase:Discover`; then the **Dependency Graph**; then **Out of Scope** if there is
anything to list; then a `----` line before the first milestone entry.
For updates: only new or changed milestones are written as `(draft)`;
existing entries are left untouched.

**The file is now the source of truth for the plan.**
