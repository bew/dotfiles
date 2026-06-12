# Classify — New Artefact

Read when creating a new artefact (not an update to an existing one).

## Right artefact type

Ask user what they want to create if not already clear.
Use decision table below to confirm right artefact type.

**A skill is appropriate when…**:
- Task requires judgment, branching, or dynamically composing tools
- Task should be automatically done based on needs of agent
- Agent needs to use skill-associated files/scripts/references
- Task is reusable across many sessions

**A command is appropriate when…**:
- Task is a fixed prompt template run on demand
- You want a `/shortcut` that injects context (args, shell output, files)
- Output format is always the same

**An agent is appropriate when…**:
- You need a persistent specialised assistant workflow
- You want a different model, temperature, or tool set
- You want to restrict or expand permissions (tool access, mcp, ..) beyond defaults

NOTE: Only **skills** support companion files (`references/`, `scripts/`, `assets/`, `templates/`).
Agents and commands use single `.md` file — all content must be self-contained.

**A snippet is appropriate when…**:
- You want reusable static text injected anywhere in a message (not just first position)
- Content is small, self-contained, and has a single responsibility
- You want to DRY up recurring prompt patterns or instructions

## Should this even be an OpenCode config artefact?

Before proceeding, determine whether an OpenCode artefact is the right 'tool' for the job.

An OpenCode artefact is NOT appropriate for tasks that are:
- Fully deterministic → suggest to write a script (`scripts/`, `Makefile`, CI workflow)
- Always identical → suggest to use a template or code generator
- Run unattended in CI/CD → suggest to use a pipeline action, not an agent
- Simple enough to be a one-liner → suggest to write command in `AGENTS.md`

If requested need appears to 'violate' these rules, suggest user toward alternative solution.
