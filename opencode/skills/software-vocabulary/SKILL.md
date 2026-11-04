---
name: software-vocabulary
description: |
  The term set for software structure — module, contract, seam, adapter, owner, logic, orchestrator,
  side-effect — each with the words not to use for it; the term set the design skill uses.
  Load when arguing about what to call something, naming a structural concept, or describing how
  parts of a program relate.
  Load when "component", "API", "service", "boundary", or "layer" would stand in for a precise
  noun.
  Not for naming style, code comments, or error mechanics — those belong to `coder-*`.
metadata:
  maintainers: [bew]
---

## Goal

Give every structural idea in a design discussion one word, so two people discussing code mean the
same thing by it.

Terms are grouped into questions.
Each italic line is one question; the terms under it answer that question.
Use the term, use its plural, do not reach for a synonym — each entry names the synonyms that
cost precision.

## Vocabulary

Rejected framings — the ones most often borrowed back in:
- depth is not a lines ratio (implementation lines over contract lines); depth is how much behaviour
  sits behind a small contract.
- `contract` is not the language keyword `interface`, and it is not the `API` of a service.
- `seam` is not `boundary` — that word covers both a module's edge and the edge of the program.

*What code is this* — the physical building blocks, at any scale.

- `module` — a structural building block: function, class, directory, or a slice of the program.
  `_Avoid_: unit, component, service`
- `fragment` — a `module` too small to own a concept: one class or two functions that a reader must
  jump to for nothing.
  `_Avoid_: helper, util, common`
- `deep module` — a `module` whose `contract` is small next to what it does: a caller learns
  little and gets much. Depth is the property; the module is what has it.
  `_Avoid_: layer, abstraction, wrapper`
- `package` — a physical group of related modules.
  `_Avoid_: component, bundle, library`
- `data module` — a `module` of fields and derived values; it orders nothing and touches nothing
  outside the process.
  `_Avoid_: model, DTO, entity`
- `implementation` — the code behind a `contract`, whether or not it occupies a `seam`.
  `_Avoid_: backend, guts, internals`

*What role does it play*

- `logic` — the code that makes decisions.
  Carries no purity claim; pairs by subtraction with the orchestrator, which owns order.
  `_Avoid_: core, pure core, business rules`
- `orchestrator` — the module implementing one operation: calls `logic` and `adapter`s in order,
  and owns retry, compensation, transaction boundaries, and mapping failures into what the caller
  sees. It owns the workflow rules — order, retry, compensation — and no domain `logic`: it
  decides what happens next, never whether the state is valid.
  It touches the world only through adapters.
  Orchestrators nest — a plan entry may itself be an operation with its own orchestrator — so
  decide which level owns retry instead of letting every level retry.
  Name it for the change it owns (`TagRewriter`, `LegacyMigration`), never for a role.
  `_Avoid_: sequencer, coordinator, executor, service, manager, editor, processor, handler`

Roles mix inside a behaviour module; they are not layers.
A `data module` carries none of them.

*Where can it be swapped*

- `contract` — everything a caller must know: signature, ordering, error modes, invariants,
  required configuration.
  `_Avoid_: interface, API`
- `signature` — the mechanical part of a contract: name, parameters, return type.
  `_Avoid_: interface, API`
- `seam` — a place where a behaviour can be replaced without editing the code there: both sides
  depend on a contract, and the choice of implementation is made somewhere else.
  Test: the behaviour runs once with the real clock and once with a fixed one, without editing the
  module.
  `_Avoid_: boundary, hook, extension point`
- `adapter` — the implementation occupying a seam.
  `_Avoid_: driver, backend, service`

*Who decides each value*

- `owner` — the one place a value lives; a shared owner is allowed only when made explicit.
  `_Avoid_: holder, container, source`
- `local state` — state kept by one module and not observable outside it.
  `_Avoid_: private field, cache (unless derived and droppable)`
- `shared state` — state read or written by more than one module, so `owner` applies to it.
  `_Avoid_: global, singleton`

*What work runs*

- `operation` — one piece of work in code, including each entry of a plan.
  `_Avoid_: action, task, job`
- `command` — the CLI verb that triggers one operation.
  `_Avoid_: action, task`
- `lifecycle` — the states one thing passes through, with allowed transitions and terminal states.
  `_Avoid_: status, stage, workflow`
- `workflow` — the sequence of work steps, and which actor acts next.
  `_Avoid_: pipeline, process, lifecycle`

*What touches the outside world*

- `side-effect` — interaction with anything outside the process: clock, filesystem, network,
  environment, subprocess, randomness.
  `_Avoid_: I/O, effect`
