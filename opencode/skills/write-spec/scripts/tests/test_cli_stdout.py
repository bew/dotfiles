"""Golden stdout tests: every command must print exactly what it printed before the split."""

import os
import subprocess
import sys
from pathlib import Path

import pytest

ENTRY_POINT = Path(__file__).parent.parent / "manage-spec"

HELP_OUTPUT = """\
usage: manage-spec [-h] <command> ...

Create a spec directory and move a spec between lifecycle states.

options:
  -h, --help     show this help message and exit

commands:
  <command>
    init         create a spec directory in the discovery state
    rename       rename the spec slug, or retitle it
    rebase       move the spec under another base directory
    discovery    move the spec to the discovery state
    explo        move the spec to the explo state
    draft        move the spec to the draft state
    maybe-ready  move the spec to the maybe-ready state
    ready        move the spec to the ready state
    abandoned    move the spec to the abandoned state
"""

INIT_OUTPUT = """\
Session vars: 3 new
- $slug = alpha
- $specdir = SPEC-DRAFT-alpha/
- $specpath = SPEC-DRAFT-alpha/SPEC.md

Next: record the discovery notes in SPEC-DRAFT-alpha/DISCOVERY.md
"""

DRAFT_OUTPUT = """\
State: draft
Session vars: unchanged
"""

READY_OUTPUT = """\
State: ready
Session vars: 2 changed
- $specdir = SPEC-READY-alpha/
- $specpath = SPEC-READY-alpha/SPEC.md
"""

RENAME_SLUG_OUTPUT = """\
Renamed: alpha -> beta
Session vars: 3 changed
- $slug = beta
- $specdir = SPEC-READY-beta/
- $specpath = SPEC-READY-beta/SPEC.md
"""

RENAME_TITLE_OUTPUT = """\
Retitled: Better Title
Session vars: unchanged
"""

REBASE_OUTPUT = """\
Rebased: SPEC-READY-beta -> base/SPEC-READY-beta
Session vars: 2 changed
- $specdir = base/SPEC-READY-beta/
- $specpath = base/SPEC-READY-beta/SPEC.md
"""

MIGRATE_OUTPUT = """\
Renamed: EXPLORATION-topic.md -> EXPLO-topic.md
Updated exploration references in 1 file(s).
Removed empty _WIP_SPECS/
Migrated: _WIP_SPECS/gamma -> SPEC-DRAFT-gamma
State: draft
"""


def run_spec(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    """Run the script in cwd with a fixed terminal width."""
    env = {**os.environ, "COLUMNS": "200"}
    return subprocess.run(
        [sys.executable, str(ENTRY_POINT), *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )


@pytest.fixture
def project_root(tmp_path: Path) -> Path:
    """Provide an empty project directory to create specs in."""
    return tmp_path


@pytest.fixture
def discovery_spec(project_root: Path) -> Path:
    """Provide a discovery spec created by `init`, with its directory."""
    run_spec(project_root, "init", "alpha", "Alpha Spec")
    return project_root / "SPEC-DRAFT-alpha"


@pytest.fixture
def ready_spec(discovery_spec: Path) -> Path:
    """Provide a spec moved to the ready state, with its directory."""
    run_spec(discovery_spec, "draft")
    run_spec(discovery_spec, "ready")
    return discovery_spec.parent / "SPEC-READY-alpha"


def test_help_lists_every_command_but_migrate(project_root: Path) -> None:
    """`--help` advertises the documented commands and hides `migrate`."""
    result = run_spec(project_root, "--help")
    assert result.returncode == 0
    assert result.stdout == HELP_OUTPUT


def test_init_reports_seeded_vars_and_the_notes_file(
    project_root: Path, discovery_spec: Path
) -> None:
    """`init` reports new session vars, then points at the discovery notes."""
    result = run_spec(project_root, "init", "beta", "Beta Spec")
    assert result.returncode == 0
    assert result.stdout == INIT_OUTPUT.replace("alpha", "beta")


def test_transitions_print_the_state_and_changed_vars(discovery_spec: Path) -> None:
    """`draft` leaves the vars alone; `ready` moves the dir and reports the two changed."""
    assert run_spec(discovery_spec, "draft").stdout == DRAFT_OUTPUT

    result = run_spec(discovery_spec, "ready")
    assert result.returncode == 0
    assert result.stdout == READY_OUTPUT


def test_rename_reports_slug_change_and_title_only_change(ready_spec: Path) -> None:
    """`rename` reports a renamed slug, and a retitle that leaves every var alone."""
    renamed = run_spec(ready_spec, "rename", "beta")
    assert renamed.stdout == RENAME_SLUG_OUTPUT

    retitled = run_spec(ready_spec.parent / "SPEC-READY-beta", "rename", "Better Title")
    assert retitled.stdout == RENAME_TITLE_OUTPUT


def test_rebase_reports_both_locations(ready_spec: Path) -> None:
    """`rebase` reports the move relative to the project root, then the changed vars."""
    run_spec(ready_spec, "rename", "beta")
    (ready_spec.parent / "base").mkdir()

    rebased = run_spec(ready_spec.parent / "SPEC-READY-beta", "rebase", "base")
    assert rebased.returncode == 0
    assert rebased.stdout == REBASE_OUTPUT


def test_migrate_reports_renames_removals_and_both_locations(project_root: Path) -> None:
    """`migrate` reports the exploration rename, the pruned container, and the move."""
    legacy_spec = project_root / "_WIP_SPECS" / "gamma"
    legacy_spec.mkdir(parents=True)
    (legacy_spec / "DISCOVERY.md").write_text(
        "---\ncreated-at: 20260101T0000\n---\n\n# [DRAFT] Gamma Spec\n\nbody here\n"
    )
    (legacy_spec / "EXPLORATION-topic.md").write_text("see EXPLORATION-topic.md for details\n")

    result = run_spec(project_root, "migrate", "_WIP_SPECS/gamma")
    assert result.returncode == 0
    assert result.stdout == MIGRATE_OUTPUT


def test_unknown_command_reports_the_choice_list(project_root: Path) -> None:
    """An unknown command is refused by argparse, which never offers `migrate`."""
    result = run_spec(project_root, "shipped")
    assert result.returncode == 2
    assert "invalid choice: 'shipped'" in result.stderr
    assert "migrate" not in result.stderr
