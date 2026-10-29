# Python Skill Script Split

Read this only when a Python skill script outgrows one file and the user agrees to restructure it.

Default for every Python skill script: one executable file plus its `.bats` end-to-end suite.
The split is a structural change — propose it to the user, never apply it silently.

## Layout

```
scripts/
  <name>            # executable entry: shebang, no extension
  lib/__init__.py
  lib/cli.py        # argument parser, dispatch, and all printing
  lib/<concern>.py  # one concern per module
  tests/conftest.py
  tests/test_*.py
  pytest.ini
  <name>.bats       # end-to-end suite
```

## Entry stays a shim

`<name>` holds the shebang, `import sys`, `from lib.cli import cli_main`, and the `__main__` guard.
Nothing else:

```python
#!/usr/bin/env python3

import sys

from lib.cli import cli_main

if __name__ == "__main__":
    sys.exit(cli_main())
```

`sys.exit(cli_main())` carries the `0`/`1`/`2` status through the entry.

`lib/cli.py` owns the parser, the dispatch, and every `print`.
Sibling modules own one concern each and return values.
Nothing below the CLI writes to stdout.

## Imports need no packaging

Python puts the running script's own directory on `sys.path`.
So `from lib.cli import cli_main` resolves when `<name>` is executed directly.
No `sys.path` line in the entry, no `PYTHONPATH`, no editable install.

## pytest suite

The `.bats` suite stays the end-to-end run: it drives `<name>` and asserts stdout, exit status,
and the files left on disk.
Add a pytest suite under `scripts/tests/` for what an end-to-end assertion can only infer:
tables, parsers, guards, derived values.
Neither suite replaces the other.

Pytest does not inherit the script's import path, so `tests/conftest.py` restores it:

```python
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
```

`pytest.ini` (in `scripts/`) sets `testpaths` and registers the markers:

```ini
[pytest]
testpaths = tests
markers =
    unit: no filesystem, git, or subprocess access
    integration: touches the filesystem, git, or subprocess
```

An unregistered marker warns on every run.
Run `pytest` from `scripts/`, the directory holding `pytest.ini`, so it becomes the rootdir.
Run from the skill root, the ini is never found: nothing is collected and the markers
stay unregistered.
