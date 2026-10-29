"""Characterisation tests for the session variables a command reports."""

from pathlib import Path

import pytest

from lib.cli import get_var_items, report_vars
from lib.lifecycle import State
from lib.operations import SpecLifecycle
from lib.spec import SessionVars, Spec


@pytest.fixture
def sample_spec_dir(tmp_path: Path) -> Path:
    """Create a draft spec dir tagged on SPEC.md with a separate notes file."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "SPEC.md").write_text("# [DRAFT] My spec\n")
    (specdir / "DISCOVERY.md").write_text("# Discovery notes\n")
    return specdir


@pytest.mark.integration
def test_session_vars_point_at_spec_md(sample_spec_dir: Path) -> None:
    """The reported paths are relative to the root, and the dir keeps its trailing slash."""
    assert SpecLifecycle().observe(sample_spec_dir).session_vars() == SessionVars(
        slug="alpha",
        specdir="SPEC-DRAFT-alpha/",
        specpath="SPEC-DRAFT-alpha/SPEC.md",
    )


@pytest.mark.integration
def test_session_vars_follow_the_legacy_carrier(tmp_path: Path) -> None:
    """A dir with no SPEC.md reports the file that actually carries the tag."""
    specdir = tmp_path / "SPEC-DRAFT-alpha"
    specdir.mkdir()
    (specdir / "DISCOVERY.md").write_text("# [DRAFT] My spec\n")
    assert SpecLifecycle().observe(specdir).session_vars().specpath == (
        "SPEC-DRAFT-alpha/DISCOVERY.md"
    )


@pytest.mark.unit
def test_session_vars_fall_back_to_spec_md(tmp_path: Path) -> None:
    """With neither carrier on disk, the path still names the file a rewrite would create."""
    spec = Spec(
        slug="alpha",
        root=tmp_path,
        dir=tmp_path / "SPEC-DRAFT-alpha",
        state=State.DISCOVERY,
        document=None,
        carrier_path=None,
    )
    assert spec.session_vars().specpath == "SPEC-DRAFT-alpha/SPEC.md"


@pytest.mark.unit
def test_get_var_items_keeps_a_stable_order() -> None:
    """The three variables are always reported in the same order."""
    session_vars = SessionVars(slug="alpha", specdir="SPEC-DRAFT-alpha/", specpath="x/SPEC.md")
    assert get_var_items(session_vars) == [
        ("slug", "alpha"),
        ("specdir", "SPEC-DRAFT-alpha/"),
        ("specpath", "x/SPEC.md"),
    ]


@pytest.mark.unit
def test_report_vars_counts_every_variable_as_new(
    capsys: pytest.CaptureFixture[str],
) -> None:
    """A fresh spec reports all three as new."""
    report_vars(None, SessionVars(slug="alpha", specdir="d/", specpath="d/SPEC.md"))
    assert capsys.readouterr().out == (
        "Session vars: 3 new\n"
        "- $slug = alpha\n"
        "- $specdir = d/\n"
        "- $specpath = d/SPEC.md\n"
    )


@pytest.mark.unit
def test_report_vars_lists_only_changes(capsys: pytest.CaptureFixture[str]) -> None:
    """A transition that moves the dir reports the dir and path, not the slug."""
    previous = SessionVars(slug="alpha", specdir="SPEC-DRAFT-alpha/", specpath="a/SPEC.md")
    current = SessionVars(slug="alpha", specdir="SPEC-READY-alpha/", specpath="b/SPEC.md")
    report_vars(previous, current)
    assert capsys.readouterr().out == (
        "Session vars: 2 changed\n"
        "- $specdir = SPEC-READY-alpha/\n"
        "- $specpath = b/SPEC.md\n"
    )


@pytest.mark.unit
def test_report_vars_says_unchanged(capsys: pytest.CaptureFixture[str]) -> None:
    """A repair that moves nothing reports the variables as unchanged."""
    previous = SessionVars(slug="alpha", specdir="d/", specpath="d/SPEC.md")
    report_vars(previous, previous)
    assert capsys.readouterr().out == "Session vars: unchanged\n"
