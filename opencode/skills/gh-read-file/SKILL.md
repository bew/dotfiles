---
name: gh-read-file
description: |
  Read one explicitly referenced file from a GitHub repository via the locally authenticated `gh` CLI.
  Use when the task contains a `GH:owner/repo:path`, `GH:owner/repo@rev:path`, or a
  `github.com/.../blob/.../path` URL and needs the file's actual content.
  Do not use to browse repositories, discover files, clone, or make write operations.
metadata:
  maintainers: [bew]
---

# Read a GitHub File with `gh`

Read a single concrete file reference supplied by the user or already in the task context.
Do not search for additional paths or inspect neighboring files unless explicitly asked.

## Parse the reference

Three accepted forms (fields needed: `owner`, `repo`, `path`; `rev` is absent for the default-branch form):

- **Default branch**: `GH:owner/repo:path/to/file.md`
- **Explicit revision**: `GH:owner/repo@myrev:path/to/file.md`
- **GitHub blob URL**: `https://github.com/owner/repo/blob/myrev/path/to/file.md`

Ignore URL query strings and fragments (e.g. `?plain=1`, `#L10-L20`).

## Read the file

For a default-branch reference:
`gh repo read-file "path/to/file.md" --repo "owner/repo"`

For an explicit revision:
`gh repo read-file "path/to/file.md" --repo "owner/repo" --ref "myrev"`

Use output as-is on success.

## Failures

If exit code is non-zero:

- Report stderr verbatim and state the exact reference attempted.
- If not found or `404`: stop; say the repository, revision, or path may be incorrect.
- If `401`, `403`, forbidden, or access denied: stop; tell the user to check
  `gh auth status` and repository access.
- If reports `gh repo read-file` is unknown command:
  stop; and tell the user that `gh repo read-file` requires `>= 2.95.0`.

Do not fall back to another GitHub mechanism.
Do not attempt alternate refs or paths unless the user explicitly supplies a correction.

## Rules

- Use `gh` CLI only. Never use `curl`, `wget`, `gh api`, raw GitHub URLs, or any HTTP client.
- Call `gh repo read-file` exactly once per explicitly requested file.
