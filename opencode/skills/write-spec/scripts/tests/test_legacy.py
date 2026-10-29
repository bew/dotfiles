"""Characterisation tests for the legacy-layout migration."""

import os
from datetime import datetime
from pathlib import Path

import pytest

from lib.lifecycle import RefusalError, State
from lib.operations import LegacyMigration, apply
from lib.spec import Spec


def migrate(source_dir: Path) -> tuple[Spec, list[str]]:
    """Plan one migration, apply it, and return the moved spec with its notes."""
    plan = LegacyMigration().plan(source_dir)
    apply(plan)
    return plan.spec, plan.notes


def make_legacy_spec(tmp_path: Path, heading: str | None) -> Path:
    """Create a legacy spec dir, optionally tagged on DISCOVERY.md."""
    source_dir = tmp_path / "_WIP_SPECS" / "alpha"
    source_dir.mkdir(parents=True)
    if heading is not None:
        (source_dir / "DISCOVERY.md").write_text(f"{heading}\n")
    return source_dir


@pytest.mark.integration
def test_migrate_migrates_an_untagged_legacy_spec(tmp_path: Path) -> None:
    """An untagged legacy spec migrates as draft, says so, and keeps its carrier."""
    source_dir = make_legacy_spec(tmp_path, "# My spec")

    spec, notes = migrate(source_dir)

    assert notes[0] == "NOTE: H1 has no status tag; migrating as draft."
    assert spec.state is State.DRAFT
    assert spec.dir == tmp_path / "SPEC-DRAFT-alpha"
    assert spec.carrier_path == spec.dir / "DISCOVERY.md"
    assert (spec.dir / "DISCOVERY.md").read_text().startswith("# [DRAFT] My spec\n")


@pytest.mark.integration
def test_migrate_stamps_the_creation_time_its_files_remember(tmp_path: Path) -> None:
    """A legacy dir with no carrier is stamped from its oldest file, not from the clock."""
    source_dir = make_legacy_spec(tmp_path, None)
    brief = source_dir / "EXPLORATION-topic.md"
    brief.write_text("Notes.\n")
    written = datetime(2026, 3, 4, 5, 6).timestamp()
    os.utime(brief, (written, written))

    spec, _ = migrate(source_dir)

    seeded = (spec.dir / "SPEC.md").read_text()
    assert seeded.startswith("---\ncreated-at: 20260304T0506\n---\n\n# [EXPLO] alpha\n")


@pytest.mark.integration
def test_migrate_keeps_the_tagged_state(tmp_path: Path) -> None:
    """A tagged legacy spec keeps the state its tag names."""
    source_dir = make_legacy_spec(tmp_path, "# [READY] My spec")

    spec, _ = migrate(source_dir)

    assert spec.state is State.READY
    assert spec.dir == tmp_path / "SPEC-READY-alpha"


@pytest.mark.integration
def test_migrate_refuses_an_unknown_tag(tmp_path: Path) -> None:
    """A tag outside the vocabulary aborts the migration."""
    source_dir = make_legacy_spec(tmp_path, "# [SHIPPED] My spec")

    with pytest.raises(RefusalError, match=r"unknown status tag \[SHIPPED\]"):
        migrate(source_dir)


@pytest.mark.integration
def test_migrate_refuses_a_plain_directory(tmp_path: Path) -> None:
    """Only the two known containers count as a legacy layout."""
    plain = tmp_path / "alpha"
    plain.mkdir()

    with pytest.raises(RefusalError, match=r"not a legacy spec directory"):
        migrate(plain)


@pytest.mark.integration
def test_migrate_seeds_a_carrier_for_an_exploration_only_dir(tmp_path: Path) -> None:
    """A dir with neither carrier enters the explo state with both files seeded."""
    source_dir = make_legacy_spec(tmp_path, None)

    spec, notes = migrate(source_dir)

    assert spec.state is State.EXPLO
    assert any(note.startswith("NOTE: no SPEC.md") for note in notes)
    assert (spec.dir / "DISCOVERY.md").exists()


@pytest.mark.integration
def test_migrate_renames_explo_files_and_rewrites_references(tmp_path: Path) -> None:
    """`EXPLORATION-*` files are renamed, and references ending in `.md` follow them."""
    source_dir = make_legacy_spec(tmp_path, "# [DRAFT] My spec")
    (source_dir / "EXPLORATION-BRIEF.md").write_text("brief\n")
    (source_dir / "NOTES.md").write_text("See EXPLORATION-BRIEF.md and EXPLORATION-BRIEF.\n")

    spec, notes = migrate(source_dir)

    assert "Renamed: EXPLORATION-BRIEF.md -> EXPLO-BRIEF.md" in notes
    assert "Updated exploration references in 1 file(s)." in notes
    assert (spec.dir / "EXPLO-BRIEF.md").exists()
    assert (spec.dir / "NOTES.md").read_text() == "See EXPLO-BRIEF.md and EXPLORATION-BRIEF.\n"


@pytest.mark.integration
def test_migrate_refuses_a_collision(tmp_path: Path) -> None:
    """An existing `EXPLO-*` file stops the migration instead of being overwritten."""
    source_dir = make_legacy_spec(tmp_path, "# [DRAFT] My spec")
    (source_dir / "EXPLORATION-BRIEF.md").write_text("old\n")
    (source_dir / "EXPLO-BRIEF.md").write_text("new\n")

    with pytest.raises(RefusalError, match=r"never overwrites"):
        migrate(source_dir)


@pytest.mark.integration
def test_migrate_reports_the_drained_container(tmp_path: Path) -> None:
    """The container a move empties is removed, and the removal is reported."""
    source_dir = make_legacy_spec(tmp_path, "# [DRAFT] My spec")

    _, notes = migrate(source_dir)

    assert "Removed empty _WIP_SPECS/" in notes
    assert not (tmp_path / "_WIP_SPECS").exists()
