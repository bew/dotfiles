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

## Testing

The standard Python testing system is **pytest**.
When writing tests, load the `write-code-pytest` skill for full conventions.
