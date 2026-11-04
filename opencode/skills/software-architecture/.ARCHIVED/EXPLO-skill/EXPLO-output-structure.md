# output-structure — exploration

What the frames end with: the shape of that output, and what it is called.

## Findings

- The frames intro says they end with `a statement of five to ten lines — the modules and their roles,
  the contracts, the seams, the failure behaviour`. Nothing else defines it.
- `statement` is overloaded: in a programming context it reads as a language statement, and in prose as
  one sentence. The user's verdict: "not clear at all".
- The `pseudocode` sample of that output was dropped, so nothing now shows the output's form. Only the
  five names above describe it, and four of them are vocabulary terms, not sections.
- `statement` appears in the frames intro and in `## Which case`. `software-vocabulary` does not define it;
  the design skill owns it, which is why the head pointer says "structural terms" rather than "every term".
- The output stays in conversation and goes to a file only when the user agrees and names the location.
- `write-spec` owns durable design documents, so anything here has to stay lighter than a spec.

## Design crux

What is the output actually made of, and what name tells an agent both what to produce and when it is
finished?

## Decisions

### (settled) `architecture-report-shape` — the frames end with a `<thing> Architecture Report`

related-to: `topic:output-structure`

The report is titled `<thing> Architecture Report`, where `<thing>` is the project, repo, or script.
It describes the code, not the frames: modules and contracts stay in it although no frame names them,
because the frames describe the work and the report describes the result.

Sections, in reader order, each paragraph opening with `**Term**: ` (colon outside the bold) and one
sentence per line, never restating its own lead-in:
- `Concepts` — what each load-bearing thing means, what it becomes in code, what it is not.
- `Data` — what makes each thing valid, what identifies it, what is derived rather than held.
- `Modules` — each module's role, what callers may rely on, and whether it is a seam.
- `Failure` — per step, expected or exceptional, and what survives.

`Contracts` and `Seams` do not get sections of their own: a seam is a property of a contract and a
contract is a property of a module, so giving either its own section describes the module twice.
`Data` exists separately from `Concepts` because the two answer different questions — meaning versus
how the thing is held — and a concept that is also a value gets a paragraph in each.

An empty section is a decision nobody made.

No frame decides what makes a thing valid, what identifies it, or what is derived rather than held, so
the `Data` bullet closes with `state the choice behind it`, and the data frame names the same three.

A review reports the code as it is, and closes each paragraph that has a flaw with one sentence
naming what is not good there.
That sentence carries the flaw only, never the fix, so no suggestion is written twice.

A refinement is a review scoped to what the change touches, so it produces the same shape; there is
no separate change-summary artefact.

The report stays in conversation; write it to a file only when the user agrees and names the location.

#### Example

```md
# importer Architecture Report

## Concepts

**Order**: the thing the business accepts.
Becomes `Order`, the type the rest of the system handles.
It is not a row: rows can be malformed, orders cannot.

## Modules

**writer**: applies an accepted set.
Its contract is all or nothing: every order applied, or a failure returned with nothing applied.
The code commits per row, so a mid-import failure leaves half the orders written.
```

### (settled) `changes-index-and-cta` — changes stay an index, expanded on request

related-to: `architecture-report-shape`

`Suggested changes` follows a review report: one line per main change, numbered `C1`, `C2` …, and the
line reads as the heading the change would expand into.
A closing paragraph carries the minors, opening with `**Minors**: ` so it stays apart from the
indexed lines without needing a term of its own.
A new design has no changes section, and `No changes suggested.` is the line when a review finds
nothing worth changing.

A change expands only when asked, into what moves, what it replaces, what forces it, and what it
costs, with no code beyond what the entry is unreadable without.
Main changes are taken up one at a time, by asking.

The report closes with one line per next move, each formatted `Say '<cta>' to <short description>`,
drawn from:

- `discuss changes` — expand the index in full, one short subsection per main change and the minors at
  the end, then walk the changes one by one with a question per change; a review holding only minors
  walks the minors paragraph instead.
- `rework <part>` — redo one part of the report.
- `apply all` — implement every change in code.
- `to file` — save the report where the user says.

A review with changes offers all of them; a review without changes offers `rework <part>` and
`to file`, as does a new design.
The form is fixed, the set is not: a case may add a move.

#### Example

```md
## Suggested changes

- C1 — commit the import as one unit
- C2 — split validation out of the parser

Minor: fold `InvoiceData` into `Invoice`; rename `Row` to `Raw row`.

Say 'discuss changes' to expand each change in full.
Say 'rework writer' to redo one part of the report.
Say 'apply all' to make every change.
Say 'to file' to save the report.
```

## Rejected directions

- **prose parts, renamed `design summary`** — the parts copied the frames, so the list moved whenever
  the frames moved, and one frame was already under revision.
- **named slots, one line each** — five fixed slots hardened into a form to fill, and a line per slot
  invited one thin line per decision instead of a thought.
- **rename only** — left the output uncheckable; the noun was not the whole defect.
- **bare labelled skeleton** — read as a template to fill, the same objection that killed the dropped
  pseudocode sample.
- **fold into an existing artefact** — the skill then produces nothing itself, which weakens the
  frames' completion test.

## Open threads

- none
