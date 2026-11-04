## 3. `Phase:Discuss` — iterate, surface tradeoffs; settle window and boundary

The file already exists — created at the end of `Phase:Draft` — and is the source of truth.
Iterate on the plan with the user.
For each open question or tradeoff: surface the pros/cons explicitly before proposing a resolution.
Do not silently absorb decisions — record the reasoning.

Every confirmed decision is written through to `$milestonesfile` immediately:
grouping, merges, bundling edges, parallel edges, and ordering.

Before each question round, show the focused view (see <../discussion-views.md>).

Focus areas:
- **Grouping decisions**: is bundling two concerns justified? (see `Grouping heuristics`).
- **Shared component scope**: is this component large or multi-faceted enough to be its own
  deliverable, or can it start implicit and be extracted later?
- **Persistence**: is there a design gap that needs a milestone before implementation?
- **Descoping**: does a decision explicitly drop something from scope? Record it in the
  file's **Out of Scope** section (see <../file-format.md>) rather than leaving it implicit.

### Ordering

Ordering is settled only inside the **ordering window** — `$orderwindow` milestones past the
delivery edge, default `5`.
Ask whether the sequence follows make-it-work → make-it-right → make-it-fast, and whether hidden
dependencies force a different order.

- Confirm the resolved `$orderwindow` with the user in the first round.
  They may widen it, shrink it, or ask for the whole plan to be ordered.
- Topics past the window stay in the **Backlog**; see <../file-format.md>.
- A constraint the user already knows for a far topic becomes a `Pinned:` line on its backlog
  entry.
- An in-window milestone depending on a backlog topic promotes that topic into the window.

**Parallel tracks**: derive parallel candidates from the dependency graph — any two topics with
no edge between them and a common ancestor are potentially parallel.
Present the candidates to the user and ask for confirmation before labeling them.
Confirmed parallel pairs are written into the file's dependency graph as they are confirmed.

Each ordering decision updates that milestone's **Ordering reason** in the file as it is made.
The field is freely reworkable like any other: start it at `(pending ordering)` and refine it
throughout discussion, or revise an existing value when a decision shifts the order.

Ordering and bundling decisions follow `Milestone ordering rules` and `Grouping heuristics`.

Iterate until the user explicitly confirms the plan is stable.

### Numbering and backlog placement

Before assigning numbers, open the dependency graph in the file — it has been kept current —
and review it as a final whole-graph check.
No chat re-print of the graph is needed.

Then assign numbers to the in-window topic names, in agreed order.
The numbering must be consistent with the dependency graph — parallel topics get consecutive
numbers by convention, but either order is valid.
Update the file: graph bullets get `(M<N>)` after their `{topic}`, and each section header becomes
`## M<N> — <topic> (draft)`.

Move every topic that fell outside the window to the **Backlog** section at the end of the file:
topic name plus its Goal, and a free-form `Pinned:` line under any topic whose ordering the user
already constrained.
Backlog entries carry no numbers and no edges.
Promote a topic that moved into the window the same way, and fold its `Pinned:` line into the new
Ordering reason.

### Task scoping boundary

Confirm which milestones get scoped task files now.
A milestone is scoped only when every milestone it depends on is already delivered.
On a fresh plan nothing is delivered yet — the boundary is the startable in-window milestones,
those with no undelivered dependency.
A startable topic still in the backlog stays unordered until a window slot frees.
When the user asks to scope a milestone early, follow that request.
Milestones past the boundary keep rough task ideas until their turn comes.

The boundary carries into `Phase:Finalize`; it is not asked again.
