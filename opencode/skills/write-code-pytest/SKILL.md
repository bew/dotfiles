---
name: write-code-pytest
description: |
  pytest test writing guidelines: fixtures, naming, test structure, and assertions.
  Always load when asked to draft/write/edit/refactor/review pytest test files (test_*.py).
metadata:
  maintainers: [bew]
---

## Goal

Write pytest tests that are readable, type-annotated, and well-scoped,
building on generic & language conventions.

REQUIRES: load `write-code-generic` and `write-code-python` skills first.

## Running tests

```bash
pytest -k <filter>                     # run matching subset
pytest tests/path/to/test_file.py      # run one file
pytest                                 # full suite
```

Run tests actively during development — after each meaningful change, not as a post-step.

## Rules

### Test structure

- All tests are plain `def test_*` functions — never methods in a class unless the framework
  requires it.
- Mark tests `@pytest.mark.unit` (no I/O, no external calls) or `@pytest.mark.integration`.
- Every test must include at least one positive assertion that proves the expected behaviour —
  not just negative "was not called" checks.
- Merge related assertions about one object into a single test rather than splitting into
  many tiny tests.
- Prefer a single parametrized test covering all variants over separate `@pytest.mark.parametrize`
  blocks, unless the setup differs significantly between variants.
- Add an explicit test for behaviours that depend on operator overloading or special methods
  (e.g. `test_can_be_used_as_dict_key`).
- No section-comment dividers (`# ---`) inside test files.

### Fixtures

- Always annotate fixture return types.
- Never return a tuple from a fixture — use multiple separate fixtures instead.
- Keep fixtures generic; set mock return values and scenario-specific data inside each test
  body rather than hardcoding them in the fixture.
- When production-only paths must be exercised (e.g. setting env vars), add an explicit named
  fixture (e.g. `production_env`) with a comment explaining why.

### Naming

| Subject | Convention | Example |
|---|---|---|
| Example data fixture (shared across tests) | `sample_` prefix | `sample_field`, `sample_config` |
| Module-level example data constant | `SAMPLE_` prefix | `SAMPLE_PROJECT_CONFIG` |
| Test-only helper class | `Sample` prefix | `class SampleEnumColor(Enum)` |
| Autospecced dependency or mock fixture | `mock_` prefix | `mock_fenergo_adapter` |
| Sample ticket/ID keys | consistent prefix (e.g. `PROJ-`) | `PROJ-2`, `PROJ-123` |

### Test setup

- Prefer `create_autospec(SomeClass)` over plain `Mock()`.
- Avoid opaque sentinels like `object()` — prefer concrete literals or small helper dataclasses
  when a placeholder value is needed.
- Never monkeypatch attributes on the object under test; steer behaviour through mocks of
  dependencies or public APIs only.

### Assertions

- Use `pytest.raises` with the precise exception class and a `match=r"..."` pattern — never
  bare `Exception`.
- Use `assert x is True` / `assert x is False` for boolean checks — not `assert x` / `assert not x`.
- Never write a test that expects `UnboundLocalError` — it signals missing handling in source
  code; surface the issue and ask what to do instead.

### Type annotations

- Annotate all test function parameters (including fixtures) and return types.
- Never use `object` as a type hint — use `Any` from `typing` instead.

```python
# Good
@pytest.fixture
def sample_config() -> dict[str, str]:
    return {"env": "test"}

def test_loads_config(sample_config: dict[str, str]) -> None:
    result = load_config(sample_config)
    assert result["env"] == "test"

# Bad — missing annotations, bare Mock, tuple fixture
@pytest.fixture
def data():
    return ("value1", Mock())
```
