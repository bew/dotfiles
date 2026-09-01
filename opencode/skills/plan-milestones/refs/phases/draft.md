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

After grouping is tentatively settled, show the whole-plan view (see <../discussion-views.md>)
for confirmation — create-from-scratch flow only; in update mode the existing
`$milestonesfile` graph is reviewed from the file instead.
The user confirms this shape before `Phase:Discuss` begins.

----

Once the user explicitly confirmed, write `$milestonesfile` in draft state,
following the format in <../file-format.md> and <../file-draft-form.md>.
For updates: only new or changed milestones are written as `(draft)`;
existing entries are left untouched.

**The file is now the source of truth for the plan.**
