# Skill with a Command Trigger

A command trigger is a thin command whose sole purpose is to invoke a skill.
See <../command-anatomy.md> for full command syntax and `$ARGUMENTS` forms.

## Ownership rule

The skill owns input extraction — not the command.

A skill may be loaded directly by the user or by another skill, with no command involved.
If extraction lives in the command, direct loads skip it and the skill doesn't know what to do.

EXCEPTION: a caller may extract values the skill does not know about and state them explicitly
alongside raw user context.
In that case, the skill reads both raw context and the caller-provided named values.
The skill still owns extraction of its own inputs.

## Command body shape

Thin launcher — no extraction, no interpretation of `$ARGUMENTS`.
The skill load instruction comes first, then the user context block at the end:

`````md
Load the `<skill-name>` skill and follow its instructions.

## User context

May be empty. If non-empty, <brief description of what context means for this skill>.

```
$ARGUMENTS
```
`````

NOTE: `$ARGUMENTS` must appear at most once in the command body.
The fenced-block form handles multiline and free-form input correctly.

NOTE: Do not inject working directory in the command body.
The skill infers it from the env block in the system prompt (e.g. `Working directory:` line).
If the skill needs to pass it to a subagent: it reads it from the env block itself.

If the skill takes no arguments at all, omit the "User context" section entirely:

`````md
Load the `<skill-name>` skill and follow its instructions.
`````

If the skill has structured inputs to extract: read <../with-precise-inputs.md> for the `## Setup` pattern.
