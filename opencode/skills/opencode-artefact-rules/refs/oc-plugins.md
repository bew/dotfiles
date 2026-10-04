# Quality Criteria — oc-tools & oc-plugins

Both artefacts are plugin directories under `plugins/`, so the criteria are shared.

1. **Entry** — Is the entrypoint named `index.ts`?
2. **README** — Does the plugin directory ship a `README.md` explaining what it does and why?
3. **Dependencies** — Does it prefer `node:` builtins and avoid npm dependencies / Bun-only `$`?
4. **Discovery** — Is it loadable by auto-discovery?
5. **Scope** — Single responsibility?
   An `oc-tool` registers one tool and no hooks; an `oc-plugin` may register tools, hooks, or both.
