# Quality Criteria — Skill-Standalone

Apply the universal criteria first. Then check the following.

1. **Single-file layout** — `SKILL.md` + `README.md` + `VARIANT` only.
   Flag any `refs/`, `scripts/`, `assets/`, or `templates/`.
2. **No OC mechanics** — body must not invoke OC tool names (`write`, `edit`, `read`, `bash`), git,
   filesystem paths/folders, subagents, `skill` tool, `question` tool.
3. **No interactive loop** — no phase gates, no mid-pass checkpoints.
4. **Inline output** — output instructions say "output inline in a fenced block";
   no "write to `<path>`".
5. **No dangling references** — no `./refs/` links; no `§slug` refs left un-inlined.
6. **Provenance** — `README.md` present with a source pointer to the base skill.
7. **Minimal description** — `description` states it is the self-contained export;
   no elaborate trigger encoding.
8. **Naming** — frontmatter `name` matches the directory name and equals `<base>-standalone`.
9. **Phase names preserved** — phases kept as conceptual stages; not flattened away.
10. **No scripts** — base skill had no `scripts/`; standalone references none.
11. **VARIANT marker** — `VARIANT` file present, containing `standalone`.
