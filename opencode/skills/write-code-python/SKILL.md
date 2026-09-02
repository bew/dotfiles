---
name: write-code-python
description: |
  Python code writing guidelines: docstrings, file headers, main() conventions,
  type annotations, and error handling.
  Always load when asked to draft/write/edit/refactor/review Python code —
  including .py files, extensionless scripts with a Python shebang, and rewrites
  of another language's script into Python.
metadata:
  maintainers: [bew]
---

## Goal

Produce idiomatic, well-typed Python code, building on generic conventions.

REQUIRES: load `write-code-generic` skill first.

In Python, **module code** is any `.py` file imported by other modules — no shebang.
**Script code** is a file run directly: has a shebang (`#!/usr/bin/env python3`).

NOTE: `if __name__ == "__main__":` alone does not mean the file is script code — it is also
used for ad-hoc interactive tests in module files.
Do not add it automatically; do not flag its presence as an issue.

If working on **module code**: read <./module-rules.md>.
If working on **script code**: read <./script-rules.md>.

## Rules

### Docstrings

- Use `"""…"""` docstrings **inside** the function body — never `#` comments above the `def`.
- Do **not** document `main()`.
- **Single-line**: summary on the same line as the opening `"""`, closing `"""` on the same line.
- **Multi-line**: summary on the same line as the opening `"""`, then a blank line, then additional
  detail paragraphs, then closing `"""` on its own line.

```python
# Good — single-line
def split_lines(text: str) -> list[str]:
    """Split text into non-empty lines, ……"""
    return [line.rstrip() for line in text.splitlines() if line.strip()]

# Good — multi-line
def load_config(path: str) -> dict:
    """
    Load and return config from the given JSON file.

    Has special case for ……
    """
    ...

# Accepted — multi-line but first line on same line as """.
def load_config(path: str) -> dict:
    """Load and return config from the given JSON file.

    Raises FileNotFoundError if path does not exist.
    Raises json.JSONDecodeError if file content is not valid JSON.
    """
    with open(path) as f:
        return json.load(f)

# Bad — comment above instead of docstring inside
# Split text into non-empty lines
def split_lines(text: str) -> list[str]:
    ...
```

### Type annotations

- Always annotate parameters and return types.
- Use built-in generics (`list[str]`, `dict[str, int]`, `tuple[str, ...]`) —
  no `from typing import List`.
- Use `X | None` instead of `Optional[X]`.
- Use `X | Y` instead of `Union[X, Y]`.

```python
# Good
def get_type_info(schema: dict) -> tuple[str, str | None]:
    ...

# Bad
from typing import Optional, Tuple, Dict
def get_type_info(schema: Dict) -> Tuple[str, Optional[str]]:
    ...
```

### Proper typing over loose values

Always prefer proper typing instead of loose strings or defaults.
When a value may legitimately be absent, encode it in the type — do not paper over it.

```python
# Good — absence is visible to the type checker and callers must handle None
def find_rev(url: str) -> str | None:
    ...

# Bad — "" is invisible for the type checker and callers must know to check for ""
def find_rev(url: str) -> str:
    ...
```

Let the empty / not-found case surface through a `X | None` return type that the type
checker can verify. The type checker is always available — use it.

### Exceptions

- Never `except Exception`. Always except specific exception types.
- Narrow to the concrete exceptions the guarded region can raise:
  `OSError`/`subprocess.SubprocessError` for subprocess, `json.JSONDecodeError` for json,
  `FileNotFoundError` for file access, `ScriptError` or another project exception, etc.

```python
# Good — concrete types, chained with `from exc`
try:
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=CMD_TIMEOUT_S)
except (OSError, subprocess.SubprocessError) as exc:
    raise ScriptError(f"Could not run `{cmd}`: {exc}") from exc

# Bad — swallows everything, hides the real failure
try:
    ...
except Exception as exc:
    ...
```

### Text templates

- Use f-strings as the default for runtime substitution, **iff** the literal contains no `{`/`}`.
- `@@sentinel@@` + `str.replace` is acceptable for simple replacements, e.g. embedding a
  path into a shell-hook template that itself contains braces (`${...}`, `%{...}`), where
  an f-string would be mutilated by the braces.
- Interpolation targets must be `str` — wrap non-str values explicitly with `str(...)`.

## Testing

The standard Python testing system is **pytest**.
When writing tests, load the `write-code-pytest` skill for full conventions.
