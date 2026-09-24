# naming — exploration

## Findings

- The tool holds explorations (raw), specs (settled), and handoffs (transfer).
- Candidates: `lab` (placeholder), `atelier`, `sketch` / `sketchbook`, `corpus`, `dossier`, `briefcase`, `marginalia`, `apocrypha`.

## Design crux

The name must fit a personal CLI, avoid collisions with git concepts, and ideally evoke the contents.

## Candidate directions

- **`lab`** — short, workshop metaphor. _(active)_
- **`atelier`** — a designer's workshop. _(active)_
- **`sketch` / `sketchbook`** — explorations are sketches. _(active)_

## Decisions

- **Use `lab` throughout the spec as a placeholder**; the exact name stays an open question. _(settled)_
- **Derived paths track the final name**: worktree dir (`.lab` placeholder) and manifest name. _(settled)_
- **Branch name fixed**: `specs-and-design`. _(settled)_

## Open threads

- Exact tool name: `lab` vs `atelier` vs `sketch`.