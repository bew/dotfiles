## 3. `Phase:Discuss` — iterate, surface tradeoffs, identify parallel tracks

The file already exists — created at the end of `Phase:Draft` — and is the source of truth.
Iterate on the plan with the user.
For each open question or tradeoff: surface the pros/cons explicitly before proposing a resolution.
Do not silently absorb decisions — record the reasoning.

Every confirmed decision is written through to `$milestonesfile` immediately:
grouping, merges, bundling edges, parallel edges, and ordering.

Before each question round, show the focused view (see <../discussion-views.md>).

Focus areas:
- **Grouping decisions**: is bundling two concerns justified? (see *Grouping heuristics*)
- **Shared component scope**: is this component large or multi-faceted enough to be its own
  deliverable, or can it start implicit and be extracted later?
- **Ordering**: does the sequence follow make-it-work → make-it-right → make-it-fast?
  Are there hidden dependencies that force a different order?
- **Persistence**: is there a design gap that needs a milestone before implementation?
- **Descoping**: does a decision explicitly drop something from scope? Record it in the
  file's **Out of Scope** section (see <../file-format.md>) rather than leaving it implicit.

**Parallel tracks**: derive parallel candidates from the dependency graph — any two topics with
no edge between them and a common ancestor are potentially parallel.
Present the candidates to the user and ask for confirmation before labeling them.
Confirmed parallel pairs are written into the file's dependency graph as they are confirmed.

Each ordering decision updates that milestone's **Ordering reason** in the file as it is made.
The field is freely reworkable like any other: start it at `(pending ordering)` and refine it
throughout discussion, or revise an existing value when a decision shifts the order.

Ordering and bundling decisions follow `Milestone ordering rules` and `Grouping heuristics`.

Iterate until the user explicitly confirms the plan is stable.

Before assigning numbers, open the dependency graph in the file — it has been kept current —
and review it as a final whole-graph check.
No chat re-print of the graph is needed.

Then assign numbers to the milestone names, in agreed order.
The numbering must be consistent with the dependency graph — parallel topics get consecutive numbers
by convention, but either order is valid.
Update the file: graph bullets get `(M<N>)` after their `{topic}`, and each section header becomes
`## M<N> — <topic> (draft)`.
