This is the config dir for [opencode][opencode] ✨

[opencode]: https://opencode.ai/


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
