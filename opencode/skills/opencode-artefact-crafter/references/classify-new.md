# Classify — New Artefact

## Choose/Confirm artefact type

Ask user what they want to create if unclear.
Use decision table below to confirm right artefact type.

**A skill is appropriate when…**:
- Task requires judgment, branching, or dynamically composing tools
- Task should be auto-done based on needs of agent
- Agent needs to use skill-associated files/scripts/references
- Task is reusable across sessions

**A command is appropriate when…**:
- Task is a fixed prompt template run on demand
- Want a `/shortcut` that injects context (args, shell output, files)
- Output format is always the same

**An agent is appropriate when…**:
- Need persistent specialised assistant workflow
- Want different model, temperature, or tool set
- Want to restrict or expand permissions (tool access, mcp, ..) beyond defaults

NOTE: Only **skills** support companion files (`references/`, `scripts/`, `assets/`, `templates/`).
Agents & commands use single `.md` file — all content must be self-contained.

**A snippet is appropriate when…**:
- Want reusable static text injected anywhere in a message (not just first position)
- Content is small, self-contained, single responsibility
- Want to DRY up recurring prompt patterns or instructions

## Should this even be an OpenCode config artefact?

Determine whether an OpenCode artefact is right for the job.

An OpenCode artefact is NOT appropriate for tasks that are:
- Fully deterministic → suggest to write a script (`scripts/`, `Makefile`, CI workflow)
- Always identical → suggest to use a template or code generator
- Run unattended in CI/CD → suggest to use a pipeline action, not an agent
- Simple enough to be a one-liner → suggest to write command in `AGENTS.md`

If request appears to 'violate' these rules, suggest user toward alternative solution.
