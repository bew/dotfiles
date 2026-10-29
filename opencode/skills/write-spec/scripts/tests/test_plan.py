"""Tests for the plan/apply seam: what an operation intends before anything lands."""

from pathlib import Path

import pytest

from lib.lifecycle import PartialChangeError, State
from lib.operations import (
    LegacyMigration,
    MakeDir,
    MoveDir,
    RemoveDir,
    SpecLifecycle,
    WriteFile,
    apply,
    plan_new_spec,
)

FRONTMATTER = ["---", "created-at: 20261028T1946", "---"]


@pytest.fixture
def sample_spec(tmp_path: Path) -> Path:
    """Write a draft spec dir holding a frontmatter block, a tag, a loader, and one body line."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "SPEC.md").write_text(
        "\n".join([*FRONTMATTER, "", "# [DRAFT] My spec", "", "", "Body line."]) + "\n"
    )
    return specdir


@pytest.mark.integration
def test_plan_retag_keeps_block_title_and_body(sample_spec: Path) -> None:
    """Retagging plans one SPEC.md write and leaves the disk alone until applied."""
    spec = SpecLifecycle().observe(sample_spec)
    before = (sample_spec / "SPEC.md").read_text()

    plan = SpecLifecycle().plan_retag(spec, State.READY)

    assert plan.actions == [
        WriteFile(
            sample_spec / "SPEC.md",
            "\n".join([*FRONTMATTER, "", "# [READY] My spec", "", "Body line."]) + "\n",
        ),
    ]
    assert (sample_spec / "SPEC.md").read_text() == before


@pytest.mark.integration
def test_apply_writes_the_planned_text(sample_spec: Path) -> None:
    """Applying a retag plan writes exactly what the plan announced."""
    plan = SpecLifecycle().plan_retag(SpecLifecycle().observe(sample_spec), State.READY)

    apply(plan)

    assert (sample_spec / "SPEC.md").read_text() == plan.actions[0].text


@pytest.mark.integration
def test_plan_retag_overrides_the_title(sample_spec: Path) -> None:
    """A new title replaces the one the heading carried."""
    plan = SpecLifecycle().plan_retag(
        SpecLifecycle().observe(sample_spec), State.DRAFT, "Renamed spec"
    )

    assert plan.spec.document.heading == "# [DRAFT] Renamed spec"
    assert "# [DRAFT] Renamed spec" in plan.actions[0].text


@pytest.mark.integration
def test_plan_retag_normalises_the_legacy_loader(tmp_path: Path) -> None:
    """The singular loader line is replaced, not stacked under a second blockquote."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "SPEC.md").write_text(
        "\n".join(
            [
                "# [DRAFT] My spec",
                "",
                "> IMPORTANT: Before any drafting/planning/editing of this spec,",
                "> agents MUST load one of the spec-writing skill first.",
                "",
                "Body.",
            ]
        )
        + "\n"
    )

    plan = SpecLifecycle().plan_retag(SpecLifecycle().observe(specdir), State.DRAFT)

    assert plan.actions[0].text.count("> IMPORTANT:") == 1
    assert "Body.\n" in plan.actions[0].text


@pytest.mark.integration
def test_plan_retag_does_not_add_a_missing_block(tmp_path: Path) -> None:
    """A spec created before frontmatter existed stays without one."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "SPEC.md").write_text("# [DRAFT] Legacy spec\n\nBody.\n")

    plan = SpecLifecycle().plan_retag(SpecLifecycle().observe(specdir), State.READY)

    assert plan.actions[0].text == "# [READY] Legacy spec\n\nBody.\n"


@pytest.mark.integration
def test_plan_new_spec_seeds_both_carriers(tmp_path: Path) -> None:
    """A fresh spec plans its directory, a tagged SPEC.md, and a bare discovery notes file."""
    specdir = tmp_path / "SPEC-DISCOVERY-alpha"

    plan = plan_new_spec(
        specdir, State.DISCOVERY, slug="alpha", title="My spec", frontmatter_lines=FRONTMATTER
    )

    assert isinstance(plan.actions[0], MakeDir)
    assert plan.actions[0].path == specdir
    assert [action.path.name for action in plan.actions[1:]] == ["SPEC.md", "DISCOVERY.md"]
    seed = "\n".join([*FRONTMATTER, "", "# [DISCOVERY] My spec", ""])
    assert plan.actions[1].text.startswith(seed)
    assert plan.actions[2].text.startswith("# Discovery notes\n")
    assert plan.actions[2].text.count("\n") == 1
    assert plan.spec.slug == "alpha"


@pytest.mark.integration
def test_plan_new_spec_lands_on_disk_when_applied(tmp_path: Path) -> None:
    """Applying the seed plan creates the directory and both files it promised."""
    specdir = tmp_path / "SPEC-DISCOVERY-alpha"

    plan = plan_new_spec(
        specdir, State.DISCOVERY, slug="alpha", title="My spec", frontmatter_lines=FRONTMATTER
    )
    apply(plan)

    assert sorted(path.name for path in specdir.iterdir()) == ["DISCOVERY.md", "SPEC.md"]


@pytest.mark.integration
def test_plan_relocate_notes_the_drained_container(tmp_path: Path) -> None:
    """Moving the last spec out of a legacy container plans the move and the removal."""
    specdir = tmp_path / "_WIP_SPECS" / "SPEC-DRAFT-alpha"
    specdir.mkdir(parents=True)
    (specdir / "SPEC.md").write_text("# [DRAFT] My spec\n")
    target_dir = tmp_path / "SPEC-DRAFT-alpha"

    plan = SpecLifecycle().plan_relocate(
        SpecLifecycle().observe(specdir),
        target_dir,
        repair_command="Fix it.",
    )

    assert plan.actions == [
        MoveDir(specdir, target=target_dir, project_root=specdir.parent, repair_command="Fix it."),
        RemoveDir(tmp_path / "_WIP_SPECS"),
    ]
    assert plan.notes == ["Removed empty _WIP_SPECS/"]
    assert specdir.is_dir()
    assert plan.spec.dir == target_dir


@pytest.mark.integration
def test_plan_then_chains_actions_and_carries_the_last_spec(tmp_path: Path) -> None:
    """Chaining retag and relocate plans puts both in order and reports the final spec."""
    specdir = tmp_path / "_WIP_SPECS" / "SPEC-DRAFT-alpha"
    specdir.mkdir(parents=True)
    (specdir / "SPEC.md").write_text("# [DRAFT] My spec\n")
    lifecycle = SpecLifecycle()
    spec = lifecycle.observe(specdir)
    target_dir = tmp_path / "SPEC-READY-alpha"

    plan = lifecycle.plan_retag(spec, State.READY).then(
        lifecycle.plan_relocate(spec, target_dir=target_dir, repair_command="Fix it.")
    )

    assert [type(action) for action in plan.actions] == [WriteFile, MoveDir, RemoveDir]
    assert plan.spec.dir == target_dir
    assert plan.notes == ["Removed empty _WIP_SPECS/"]


@pytest.mark.integration
def test_legacy_migration_plan_touches_nothing(tmp_path: Path) -> None:
    """A migration plan names every move and write before any of them happens."""
    source_dir = tmp_path / "_WIP_SPECS" / "alpha"
    source_dir.mkdir(parents=True)
    (source_dir / "DISCOVERY.md").write_text("# [DRAFT] My spec\n")
    (source_dir / "EXPLORATION-BRIEF.md").write_text("brief\n")
    (source_dir / "NOTES.md").write_text("See EXPLORATION-BRIEF.md.\n")

    plan = LegacyMigration().plan(source_dir)

    assert (source_dir / "EXPLORATION-BRIEF.md").exists()
    assert (source_dir / "NOTES.md").read_text() == "See EXPLORATION-BRIEF.md.\n"
    assert [
        action.target.name for action in plan.actions if isinstance(action, MoveDir)
    ] == ["SPEC-DRAFT-alpha"]
    rewritten = [action for action in plan.actions if isinstance(action, WriteFile)]
    assert any(action.text == "See EXPLO-BRIEF.md.\n" for action in rewritten)


@pytest.mark.integration
def test_legacy_migration_apply_renames_and_moves(tmp_path: Path) -> None:
    """Applying the migration plan produces the renamed file and the drained container."""
    source_dir = tmp_path / "_WIP_SPECS" / "alpha"
    source_dir.mkdir(parents=True)
    (source_dir / "DISCOVERY.md").write_text("# [DRAFT] My spec\n")
    (source_dir / "EXPLORATION-BRIEF.md").write_text("brief\n")

    plan = LegacyMigration().plan(source_dir)
    apply(plan)

    specdir = tmp_path / "SPEC-DRAFT-alpha"
    assert (specdir / "EXPLO-BRIEF.md").exists()
    assert not (specdir / "EXPLORATION-BRIEF.md").exists()
    assert not (tmp_path / "_WIP_SPECS").exists()


@pytest.mark.integration
def test_plan_retag_converges_a_legacy_carrier(tmp_path: Path) -> None:
    """A legacy DISCOVERY.md carrier plans a SPEC.md write and turns the old carrier into notes."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "DISCOVERY.md").write_text("# [DRAFT] My spec\n\nBody.\n")
    lifecycle = SpecLifecycle()

    plan = lifecycle.plan_retag(lifecycle.observe(specdir), State.READY)

    assert [action.path.name for action in plan.actions] == ["SPEC.md", "DISCOVERY.md"]
    assert plan.actions[0].text.startswith("# [READY] My spec\n")
    assert plan.actions[1].text.startswith("# Discovery notes\n")
    assert plan.spec.is_legacy_carrier is False


@pytest.mark.integration
def test_plan_retag_renders_the_loader_of_the_target_state(tmp_path: Path) -> None:
    """The loader block comes from the target state's layout, not the carrier's old one."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "SPEC.md").write_text("# [DRAFT] My spec\n\nBody.\n")
    lifecycle = SpecLifecycle()

    ready = lifecycle.plan_retag(lifecycle.observe(specdir), State.READY)
    explo = lifecycle.plan_retag(lifecycle.observe(specdir), State.EXPLO)

    assert "> IMPORTANT:" not in ready.actions[0].text
    assert "EXPLO-BRIEF.md" in explo.actions[0].text
    assert explo.actions[0].text != ready.actions[0].text


@pytest.mark.integration
def test_apply_stops_on_the_first_failing_action(tmp_path: Path) -> None:
    """A failing move leaves the earlier write in place, which is why it needs a repair hint."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "SPEC.md").write_text("# [DRAFT] My spec\n\nBody.\n")
    lifecycle = SpecLifecycle()
    spec = lifecycle.observe(specdir)
    blocked_target = tmp_path / "SPEC-READY-alpha"
    blocked_target.mkdir()
    (blocked_target / "SPEC.md").write_text("# [READY] Other\n")

    plan = lifecycle.plan_retag(spec, State.READY).then(
        lifecycle.plan_relocate(
            spec,
            blocked_target,
            repair_command="Fix the cause.",
        )
    )

    with pytest.raises(PartialChangeError, match=r"The directory did not move"):
        apply(plan)

    assert (specdir / "SPEC.md").read_text().startswith("# [READY] My spec")
    assert (blocked_target / "SPEC.md").read_text() == "# [READY] Other\n"
