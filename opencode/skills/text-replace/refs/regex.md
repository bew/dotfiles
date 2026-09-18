# Regex Replacement

Read before any replacement that is not a plain literal (`-F`) match.

## Default mode

Without `-F`, `FIND` is a regex (Rust `regex` crate syntax, Unicode-aware).
`REPLACE` supports capture expansion.

```sh
sd '[ \t]+$' '' FILE...                # strip trailing whitespace from every line
sd '\t' '    ' FILE...                 # tabs -> 4 spaces
sd '\d+' 'N' FILE...                   # digit runs -> N
sd '(\w+)\s*=\s*(\w+)' '$1=$2' FILE... # normalize `key = value` -> `key=value`
sd '(?P<y>\d{4})-(?P<m>\d{2})-(?P<d>\d{2})' '$d/$m/$y' FILE... # dates -> D/M/Y
```

## Capture groups

- Define with `(...)`; reference in `REPLACE` with `$1`, `$2`, … and `${10}` for two-digit indices.
- Named groups: `(?P<name>...)` or `(?<name>...)`; reference with `$name`.
- A literal `$` in `REPLACE` must be escaped as `$$` — otherwise it starts a group reference.

## Flags (`-f`, combinable)

| Flag | Effect |
|---|---|
| `i` | case-insensitive |
| `w` | whole words only |
| `m` | multi-line matching (default) |
| `e` | disable multi-line matching |
| `s` | make `.` match newlines |
| `c` | case-sensitive |

`m` is on by default, so `^` and `$` anchor per line; `-f e` disables multi-line matching.

```sh
sd -f i 'todo' 'DONE' FILE...    # case-insensitive
sd -f w 'cat' 'dog' FILE...      # whole words only
```

## Deletion

Empty `REPLACE` deletes matches. `sd 'DEBUG:\s*\w+' '' log.txt` strips debug tokens.

## Cross-line matching

Matching is line-by-line by default. To span lines:

- `-A` processes the whole input as one buffer (more memory; disables streaming).
- `-f s` additionally lets `.` match newlines.

```sh
sd -A 'start\n.*\nend' 'block' file.txt
```

## Limits

- `-n N` caps replacements per file (`0` = unlimited, the default).

## Unsupported regex features

- Look-around (`(?=...)`, `(?<=...)`) — errors out.
- Backreferences in the pattern (`(a)\1`) — errors out; groups expand only in `REPLACE`.
- For either, fall back to a different tool; `sd` will not do it.
