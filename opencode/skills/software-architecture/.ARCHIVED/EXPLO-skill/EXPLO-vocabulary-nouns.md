# vocabulary-nouns — exploration

The noun set the skill talks in: which words are kept, renamed, or dropped, and what each one is
defined to mean.

## Findings

- Their glossary defines module, interface, implementation, seam, adapter, depth, leverage, locality,
  each with an explicit `_Avoid_:` list of forbidden synonyms.
- Our draft uses `seam`, `boundary`, `effect`, `holder` with no definitions and no consistent choice.
- In the user's own projects `core_lib` means all non-presentation code — business logic, services,
  adapters, domain models — so `core` cannot be borrowed for "the pure part".
- `action` and `operation` are near-synonyms in English, so any pair of them has to be separated by
  level rather than by gloss.
- `signature` is narrower than `interface` in PL use: name plus parameter and return types, with
  nothing about ordering, error modes, or invariants.

## Design crux

Can a small noun set stay unambiguous when the skill also borrows words from ports-and-adapters,
dependency injection, and state-machine talk, where several of these words already have local
meanings?

## Decisions

### (settled) `contract-over-interface` — "everything a caller must know" is the contract

`signature` covers only name, parameters, and return type, so it cannot carry ordering, error modes,
invariants, or required config.
`contract` does, and it reads correctly in the skill's existing line: the contract is the test surface.

`signature` stays available as the narrow, precise word for the mechanical part: the signature is part
of the contract.

### (settled) `module-structural-noun` — module stays the structural noun

`module` names the structural unit across scales: function, class, package, directory, slice.
It carries the bulk of the pattern refs and needs no second structural noun beside it.

### (settled) `owner-noun` — owner names the single authority for a value

`owner` names the one place a value lives: the clock port owns the current time.
It is the plain-English form, and the Rust analogy — one owner, or a shared one made explicit — is
the intent.

`holder` loses for being a container noun rather than a responsibility.

### (settled) `lifecycle-workflow-pair` — both nouns, contrasted

A `lifecycle` is the states one thing passes through, with allowed transitions and terminal states.
A `workflow` is the sequence of work steps and which actor acts next.
A spec moving draft → active → archived is a lifecycle; drafting → review → merge is a workflow.

The pair is a stopgap and is scheduled for rework: `TASK-20261024T0343-rework-lifecycle-workflow-vocabulary.md`.

### (settled) `operation-single-work-noun` — operation is the unit of work, action is dropped

`operation` names the work a user asks for, whether a subcommand-sized intent or a single mutation
inside a plan.
`action` is dropped, so the vocabulary carries one work noun instead of two near-synonyms.

Consequence: the detect-plan-apply refs must stop calling their plan records actions.

### (settled) `operation-in-code-command-in-cli` — operation in code, command in CLI

`operation` is the work unit in code, including each entry of a plan.
`command` is the CLI verb that triggers one, so a subcommand keeps a name of its own without
competing with `operation`.

### (settled) `logic-noun` — logic decides, and the edge rule stays separate

`logic` names the code that makes decisions.
It carries no purity claim, which fits code that is mostly not pure, and it pairs by subtraction with
the sequencing role: logic owns decisions, the sequencing role owns order.

A module can hold both roles, so roles are not layers.
The pattern keeps the name `effects-at-the-edge`: the actionable rule is where I/O sits, not whether a
pure core exists.

### (settled) `no-layer-noun` — layers stay out of the vocabulary

`layer` is a whole-codebase claim, so a small program has none, and it says nothing about where seams
go, which is this skill's subject.
Roles answer the same question per module, and roles can mix where layers cannot.

### (settled) `package-grouping-noun` — a group of related modules is a package

`package` names a physical group of modules, and every language can check whether a module is in one.
`component` is rejected: it also means a UI part and a deployable unit, and it means structure, contract,
and role at once.

### (settled) `state-local-shared` — local versus shared state, glossary line plus a section

`local state` is kept by one module and not observable outside it.
`shared state` is read or written by more than one module, so `owner` applies to it.

Both get one line in `## Vocabulary`, and the skill carries a short section on state ownership that
uses the pair.

### (settled) `orchestrator-noun` — orchestrator owns order and failure handling

The orchestrator implements one operation: it calls `logic` and `adapter`s in order, and owns retry,
compensation, transaction boundaries, and mapping failures into what the caller sees.
It holds no business rules and touches the world only through adapters.

`sequencer` was rejected for claiming order alone, leaving failure handling without a home.

### (settled) `no-cross-cutting-noun` — constraints live as rules, not as a noun

`seam` is the only location word: a place where behaviour can be replaced without editing the code
there.
A constraint such as "every value has one owner" is not a location and often needs no seam at all — it
is checked by reading the code — so it belongs in `## Rules`, not in the vocabulary.

`boundary` stays out for the same reason it lost to `seam`: it names both a module's edge and the edge
of the program, blurring the distinction seams exist to keep.

### (settled) `seam-definition` — a seam is a replaceable behaviour, decided elsewhere

A seam is a place where a behaviour can be replaced without editing the code there: both sides depend on
a contract, and the choice of implementation is made somewhere else.

Test: can this run once with the real clock and once with a fixed one, without touching the module under
test?

### (settled) `adapter-noun` — adapter is the seam occupant

`adapter` names the implementation that sits at a seam.
`driver` covers only the outward direction, `backend` implies interchangeable targets, and
`implementation` is role-blind.

### (settled) `effect-noun` — effect is outside-world interaction

`effect` covers clock, filesystem, network, environment, subprocess, and randomness.
`I/O` is narrower and usually excludes the clock and randomness; `side effect` reads as "unwanted
consequence".

### (settled) `avoid-lines-full` — every term carries `_Avoid_:`

Each glossary term lists the synonyms not to use, mirroring the reference skill's full gloss.

Accepted cost: `API`, `component`, and `service` are banned too, although they have real referents in
OpenCode and MCP work; prose needing them has to reach for a longer phrase.

### (settled) `implementation-glossary` — implementation keeps a glossary entry

`implementation` is defined as the code behind a contract, whether or not it occupies a seam.
It is the neutral word for code whose role is not being classified, and the counterpart that makes
`adapter` readable.

## Open threads

- Does `implementation` stay a prose word, or do the three role nouns make it unnecessary?
- `explicit-state-machine.md` now inherits `local state` and `shared state`; does it still need its own
  `state` definition, or does the glossary pair cover it?
- Does `owner` survive contact with the code-owner and Rust-ownership senses well enough to use
  without a gloss?
