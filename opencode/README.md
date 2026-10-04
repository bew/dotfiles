This is the config dir for [opencode][opencode] ✨

[opencode]: https://opencode.ai/


## Docs

- [`MY_AI_STUFF.md`](./MY_AI_STUFF.md) — catalogue of every skill, agent, command,
  and plugin, with a dependency graph for the complex ones.
- [`DIR_AGENTS.md`](./DIR_AGENTS.md) — directory layout and maintenance rules for
  agents.
- [`NOTES-opencode2.md`](./NOTES-opencode2.md) — running notes on OpenCode V2
  behaviour.


## Local plugin dependencies

Local plugins under `plugins/` import packages such as `@opencode/plugin`.
OpenCode does not install their dependencies, so they live in this config dir's
shared `package.json` + `bun.lock`, installed into `node_modules/` (gitignored).

Relock/upgrade them within their declared ranges:
```sh
./update-local-plugins-deps
```

The script runs `bun update` (via a transient `nix run pkgs#bun`), then `bun outdated`
to report newer versions available outside the constraints.
Bump the range in `package.json` manually to adopt a newer line.

`@opencode/plugin` is pinned to `~2.0.x` (its minor tracks the OpenCode minor).
Note that `bun update` rewrites `package.json` and strips comments,
so keep the manifest comment-free and document changes here instead.
