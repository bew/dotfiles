# wrapper-schema — exploration

## Findings

`makeWrapper` (nixpkgs `pkgs/build-support/setup-hooks/make-wrapper.sh`) accepts these argument families; wrapkit's schema should express all of them.

Environment variables, keyed by `VAR` under `env`:
- `sep = <str>` (default `":"`) — the shared separator reused by every prefix/suffix variant for this VAR.
- `set = <str>` — `--set VAR VAL`
- `set-default = <str>` — `--set-default VAR VAL`
- `unset = <bool>` — `--unset VAR`
- `prefix` / `suffix` = `<list of str>` — joined by `sep`, emitted as one `--prefix` / `--suffix VAR <sep> VAL`
- `prefix-each` / `suffix-each` = `<list of str>` — one `--prefix-each` / `--suffix-each VAR <sep> VALS` per element
- `prefix-contents` / `suffix-contents` = `<list of str>` (file paths) — the `-contents` variants

Flags for the wrapped invocation, under `flags`:
- `add-flags` / `append-flags` = `<list of str>` — verbatim, shell-interpreted (`--add-flags` / `--append-flags`)
- `add-flag` / `append-flag` = `<list of str>` — single arg, quoted (`--add-flag` / `--append-flag`)

Process control, top-level:
- `argv0` = `null | "inherit" | "resolve" | <str>` — `--argv0` / `--inherit-argv0` / `--resolve-argv0`
- `chdir` = `<nullOr str>` — `--chdir`
- `run` = `<list of str>` — `--run`

Schema notes:
- A per-VAR `sep` avoids repeating the separator across the prefix/suffix variants.
- With a shared `sep`, `prefix`/`suffix` become simple string lists joined by `sep`.
- `--prefix` treats its VAL as one de-duplicated, order-preserving unit, while `--prefix-each` emits one operation per element; the schema preserves that distinction.
- `--add-flag` and `--add-flags` differ only in shell quoting (single arg vs verbatim), so the schema keeps them distinct.
- The per-action model lets an override set `env.FOO.set` while inheriting a commons `env.FOO.prefix`.

## Design crux

The exact schema shape (per-VAR action submodule vs ordered action list) is still open.

## Candidate directions

- **Per-VAR action submodule with a shared `sep`** — each `env.<VAR>` is a submodule of typed actions; `prefix`/`suffix` and variants are simple string lists reusing the VAR's `sep`. _(active)_
- **Ordered action list** — `env.<VAR>` is a list of action entries applied in order. _(deferred)_

## Decisions

- **The wrapper schema covers the full makeWrapper surface.** _(settled)_
- **Each `env.<VAR>` carries a shared `sep` (default `":"`)** — `prefix`/`suffix` and their variants are simple string lists. _(settled)_

## Open threads

- Where process-control options live (`argv0`, `chdir`, `run`) — under `env`, under `flags`, or top-level.
