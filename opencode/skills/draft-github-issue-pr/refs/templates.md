# Repo Templates

Locate the target repo's template before drafting, and split it into required and advisory items.
Store the annotated result in `$repotemplate`.

## Locate

Check these paths in the local checkout, in order:
1. `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`,
   `PULL_REQUEST_TEMPLATE.md`, or `.github/PULL_REQUEST_TEMPLATE/`.
2. `.github/ISSUE_TEMPLATE/*.yml` (issue forms) and `*.md`.
3. `.github/ISSUE_TEMPLATE/config.yml`.

Read every match for the relevant artefact type.
Some repos have several issue templates; if more than one matches, ask the user to choose.
Do not pick one silently.

If the templates are not in the local checkout, fetch them from the remote:
```bash
gh api repos/<owner>/<repo>/contents/.github/pull_request_template.md --jq .content | base64 -d
```

Use the same pattern for issue-template paths.
Store the annotated template text in `$repotemplate`.
If nothing is found, set it to `(none)`.

## Required vs advisory

Mark each template item:
- Required — YAML fields with `required: true`, required sections, acknowledgement checkboxes,
  and rules the repo says it auto-rejects on.
  Always pinned into the draft.
- Advisory — optional prompts, suggested sections, and style hints.
  Applied only when they do not conflict with the personal guideline.

## Conform

- PR template: keep every required section in order and preserve exact headings.
  Preserve `- [ ]` checklist lines; mark a box only for something you actually did.
- GitHub issue form (`*.yml`): render one section per `body` field, in order, using each field's
  `label` as the heading.
  Preserve checkbox fields as `- [x]` lines.
- Markdown issue template: keep its headings and order.
- Never drop, rename, or reorder a required section.
  Advisory sections may be dropped.
- If `$repotemplate` is `(none)`: base the body on `<./for-<kind>.md>`.

NOTE: templates may forbid or penalise AI-generated filler.
Keep the body specific and first-person.
