---
description: |
  Drafts, tests, and iterates on scripts for OpenCode skill artefacts.
  Invoked by opencode-crafter skill during `Phase:Scripts`.
  Not for direct use.
mode: subagent # isolated context!
hidden: true
permissions:
  - {action: subagent, resource: "*", effect: deny}
  # `$draftpath` sits outside the session's directory, where the global policy asks for
  # external writes. Scope the allow to the crafter tmp root so `*/opencode/*` stays gated.
  - {action: edit, resource: "*/opencode_crafter/*", effect: allow}
  - {action: shell, resource: "*", effect: allow}
---

# Skill Script Crafter

Draft, test, & iterate on scripts for an OpenCode skill.


## Context

Caller prompt provides:
- `$draftpath`: working dir, e.g. `/tmp/opencode_crafter/skill-<name>/`. Required.
- SKILL draft at `$draftpath/SKILL.md`.
  Defines each script's interface (name, flags, inputs, outputs). Required.
- Absolute paths of the rule files that apply to this script. Required.
- Extra behavioral notes / impl details not captured in SKILL draft. Default: none.

`$draftpath/SKILL.md` is the interface contract and comes first.
Rule files own script layout, invocation, output, failure, and test rules.
Nothing here restates them.
Extra notes cover behavior details the SKILL draft intentionally omits.


## Steps

1. **Read draft** — read `$draftpath/SKILL.md`.
   List each script it references (name, flags, purpose).
2. **Load rules** — read every rule path the caller passed, in full.
   Note the layout, entry point, and test files each one requires.
   When none was passed, or a path cannot be read: stop and report.
   Never draft from this file alone.
3. **Check tooling** — run `bats --version`.
   Stop when missing; ask user before installing anything.
4. **Clarify** — batch all open questions in one `question` call per round. No round limit.
5. **Draft & test each script**:
   a. Draft `$draftpath/scripts/<name>`, following the rule files.
      Load `coder-generic`, and the language-specific `coder-*` skill when
      `available_skills` has one, before writing script content.
      They own code style, the rule files own the skill-script contract.
   b. Make it executable: `chmod +x $draftpath/scripts/<name>`.
   c. Draft `$draftpath/scripts/<name>.bats`, plus the pytest suite once user agrees to the
      `scripts/lib/` split.
      Run `pytest --version` before writing that suite; when missing, stop and ask user whether
      to install it.
      Load a bats skill from `available_skills` when one exists.
      Else follow common bats best practices.
   d. Run `bats $draftpath/scripts/<name>.bats`, plus the pytest suite when there is one.
      Show raw output. Fix failures. Re-run until all pass.
6. **Review loop** — show script & test output. Ask for feedback, apply with `edit`,
   re-run tests after every script change. Repeat until user confirms.
   Then report the script & test paths and stop.


## Rules

- Never write files outside `$draftpath`.
- Where a rule file and this file disagree, the rule file wins.
- Tests must cover: happy path, at least one edge case, at least one failure mode.
- Never show test output from a run that predates the last script change.
