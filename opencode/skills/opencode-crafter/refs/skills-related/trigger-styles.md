# Skill Trigger Styles

Catalogue of trigger styles for skills (and agents).
A skill may combine styles (e.g. auto-load on condition + explicit user phrase).

NOTE: The `description` field is the only thing the agent reads to decide whether to load a skill.
Include concrete examples in the description — the more cases listed, the more reliably the agent
recognises the trigger in real situations (new cases are discovered as the skill is used).

## Style catalogue

### Explicit user request

Loads when the user explicitly asks for the skill's task — by topic, not by phrase.

Description pattern: "Load when user asks to …", "Load when asked to …"

> "Load when asked to write, draft, or review an ADR (architecture decision record)."
> "Load when asked to produce, update, or critique a changelog entry."

### Explicit user phrase / keyword

Loads on a specific phrase or keyword in the user's message.

Description pattern: "Load when user says …", "Use when user says …"

> "Use when user says 'strict mode', 'be pedantic', or 'lint everything'."
> "Load when user says 'explain like I'm five' or 'simplify this'."

### Named command `/foo`

Loads when a companion command `/foo` is invoked.
Do NOT mention the command name in the skill description — the skill should not load on its own when
the user types the command name in a message; only the command triggers it.
Description should describe what the skill does, not how it is triggered.

Read <./with-command-trigger.md> for the command body pattern.

> "Analyses a test run output and produces a prioritised fix plan, one failure at a time."
> "Generates a release summary from the diff between two tags."

### Auto-load on detected condition

Loads automatically when a runtime condition is met — no user request needed.

Description pattern: "Load when … is detected", "Load when agent hits …"

> "Load when the agent hits a missing dependency or unresolvable import."
> "Load whenever the agent writes or moves a file in a monitored directory."

### Auto-load on consecutive failure

Loads after N consecutive identical failures.

Description pattern: "Load at the Nth consecutive …"

> "Load when the same test or build step fails three times in a row without progress."

### Invoked by another skill or agent

Loaded programmatically, not by user.
Description must include: "Not for direct use." or "Invoked by <artefact-name>."

> "Schema validation helper for the data-pipeline agent. Not for direct use."
> "Provides formatting rules for the report-writer skill. Invoked by report-writer. Not for direct use."

### Post-phase hook

Loads after a specific phase or task completes, when user signals done.

Description pattern: "Load after … and user signals …"

> "Load after a migration has been written and the user signals it is ready for review."

### Task-type match (always-load for a language/domain)

Loads whenever a specific file type or task domain is active.

Description pattern: "Always load when writing/reviewing …"

> "Always load when writing or reviewing SQL migration files."
> "Always load when writing or reviewing Dockerfile or docker-compose files."

### Reference-only (explicit load, no auto)

Never auto-loads. Must be explicitly requested or loaded by another artefact.

Description must include: "Do NOT auto-load" or "not auto-loaded".

> "Style guide for internal RFCs. Reference-only — not auto-loaded.
> Load explicitly when drafting or reviewing RFC documents."

### Meta / artefact-type match

Loads when the target of work is itself an artefact of a specific type.

Description pattern: "Load when … artefact is being created/modified"

> "Load when user asks to create or update any CI pipeline definition (GitHub Actions, GitLab CI, …).
> Also triggers when request is phrased as a direct edit to a workflow file."
> "Style rules for plugin manifests. Always load whenever a plugin manifest is being created or modified."

## Discovery questions

Ask during `Phase:Discover`:

- When should this skill load — what condition, phrase, or event triggers it?
- Should it auto-load, or only when explicitly requested?
- Is there a companion command that triggers it? (→ read <./with-command-trigger.md>)
- Can it be triggered by another skill or agent? Should it also be user-accessible?
- Should anything prevent it from loading (e.g. "not for direct use")?
