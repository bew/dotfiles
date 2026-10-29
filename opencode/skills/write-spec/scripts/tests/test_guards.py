"""Characterisation tests for the guards and spec resolution."""

from pathlib import Path

import pytest

from lib.commands import check_outside_spec_dir
from lib.lifecycle import RefusalError, State
from lib.operations import SpecLifecycle
from lib.spec import (
    check_dir_matches_tag,
    check_slug,
    check_target_absent,
    check_title,
    check_transition_allowed,
    find_taken_specdirs,
)


def make_spec_dir(specdir: Path, heading: str, filename: str = "SPEC.md") -> Path:
    """Create a spec dir holding one file whose H1 is the given line."""
    specdir.mkdir(parents=True)
    (specdir / filename).write_text(f"{heading}\n")
    return specdir


@pytest.mark.unit
@pytest.mark.parametrize(
    ("from_state", "to_state"),
    [
        (State.DISCOVERY, State.DRAFT),
        (State.DISCOVERY, State.EXPLO),
        (State.DRAFT, State.MAYBE_READY),
        (State.MAYBE_READY, State.READY),
        (State.READY, State.DRAFT),
        (State.ABANDONED, State.EXPLO),
    ],
)
def test_check_transition_allowed_accepts_table_entries(
    from_state: State,
    to_state: State,
) -> None:
    """A listed transition passes silently."""
    assert check_transition_allowed(from_state, to_state) is None


@pytest.mark.unit
def test_check_transition_allowed_accepts_universal_target() -> None:
    """Abandoning a shipped-ready spec needs no per-state row."""
    assert check_transition_allowed(State.READY, State.ABANDONED) is None


@pytest.mark.unit
def test_check_transition_allowed_names_the_allowed_set() -> None:
    """A refusal lists the targets, so the caller knows the way out."""
    with pytest.raises(RefusalError, match=r"transition discovery → ready is not allowed"):
        check_transition_allowed(State.DISCOVERY, State.READY)


def test_check_transition_refusal_lists_sorted_targets() -> None:
    """The allowed set is spelled out in sorted order."""
    with pytest.raises(RefusalError, match=r"Allowed from abandoned: abandoned, draft, explo"):
        check_transition_allowed(State.ABANDONED, State.DISCOVERY)


@pytest.mark.integration
def test_check_target_absent_refuses_an_existing_dir(tmp_path: Path) -> None:
    """Colliding with an existing spec dir is refused, with no merge attempt."""
    target = tmp_path / "SPEC-READY-alpha"
    target.mkdir()
    with pytest.raises(RefusalError, match=r"target directory already exists"):
        check_target_absent(target)


@pytest.mark.integration
def test_check_target_absent_accepts_a_free_path(tmp_path: Path) -> None:
    """A free path passes."""
    assert check_target_absent(tmp_path / "SPEC-READY-alpha") is None


@pytest.mark.unit
@pytest.mark.parametrize("slug", ["alpha", "alpha_1", "alpha.v2", "ALPHA"])
def test_check_slug_accepts_a_bare_slug(slug: str) -> None:
    """A slug with no whitespace, separator, or leading dash passes."""
    assert check_slug(slug) is None


@pytest.mark.unit
@pytest.mark.parametrize("slug", ["", "two words", "a/b", "-alpha"])
def test_check_slug_refuses_a_derived_name(slug: str) -> None:
    """Names that would break the directory layout are refused."""
    with pytest.raises(RefusalError, match=r"invalid slug"):
        check_slug(slug)


@pytest.mark.unit
def test_check_title_accepts_more_than_one_word() -> None:
    """A multi-word title passes."""
    assert check_title("My spec") is None


@pytest.mark.unit
def test_check_title_refuses_a_single_word() -> None:
    """One word reads as a slug, so it is refused with that explanation."""
    with pytest.raises(RefusalError, match=r"a title needs more than one word"):
        check_title("slug")


@pytest.mark.integration
def test_find_taken_specdirs_dedupes_shared_prefixes(tmp_path: Path) -> None:
    """One existing dir is reported once, even though four states share its prefix."""
    draft = tmp_path / "SPEC-DRAFT-alpha"
    draft.mkdir()
    (tmp_path / "SPEC-KO-alpha").mkdir()
    assert find_taken_specdirs("alpha", tmp_path) == [draft, tmp_path / "SPEC-KO-alpha"]


@pytest.mark.integration
def test_find_taken_specdirs_ignores_other_slugs(tmp_path: Path) -> None:
    """Only the queried slug counts."""
    (tmp_path / "SPEC-DRAFT-beta").mkdir()
    assert find_taken_specdirs("alpha", tmp_path) == []


@pytest.mark.integration
def test_find_taken_specdirs_ignores_prefixless_dirs(tmp_path: Path) -> None:
    """A plain directory is not a spec dir."""
    (tmp_path / "alpha").mkdir()
    assert find_taken_specdirs("alpha", tmp_path) == []


@pytest.mark.integration
def test_observe_reads_the_tag_state(tmp_path: Path) -> None:
    """A known tag wins over the directory name."""
    specdir = make_spec_dir(tmp_path / "SPEC-DRAFT-alpha", "# [MAYBE-READY] My spec")
    spec = SpecLifecycle().observe(specdir)
    assert (spec.slug, spec.state) == ("alpha", State.MAYBE_READY)
    assert spec.carrier_path == specdir / "SPEC.md"


@pytest.mark.integration
def test_observe_falls_back_to_a_single_state_prefix(tmp_path: Path) -> None:
    """With no tag, a prefix owned by one state names the state."""
    specdir = make_spec_dir(tmp_path / "SPEC-READY-alpha", "# My spec")
    assert SpecLifecycle().observe(specdir).state is State.READY


@pytest.mark.integration
def test_observe_refuses_an_ambiguous_fallback(tmp_path: Path) -> None:
    """A shared prefix with no tag leaves nothing to derive the state from."""
    specdir = make_spec_dir(tmp_path / "SPEC-DRAFT-alpha", "# My spec")
    with pytest.raises(RefusalError, match=r"cannot derive the current state"):
        SpecLifecycle().observe(specdir)


@pytest.mark.integration
def test_observe_refuses_a_dir_with_no_carrier(tmp_path: Path) -> None:
    """A prefixed dir holding neither carrier file names both expected files."""
    specdir = tmp_path / "SPEC-READY-alpha"
    specdir.mkdir()
    with pytest.raises(RefusalError, match=r"no SPEC.md or DISCOVERY.md"):
        SpecLifecycle().observe(specdir)


@pytest.mark.integration
def test_observe_refuses_an_unknown_tag(tmp_path: Path) -> None:
    """A tag outside the vocabulary lists the expected ones."""
    specdir = make_spec_dir(tmp_path / "SPEC-READY-alpha", "# [SHIPPED] My spec")
    with pytest.raises(RefusalError, match=r"unknown status tag \[SHIPPED\]"):
        SpecLifecycle().observe(specdir)


@pytest.mark.integration
def test_observe_calls_out_a_foreign_marker(tmp_path: Path) -> None:
    """A marker written by another tool is reported as a second owner, not as a typo."""
    specdir = make_spec_dir(tmp_path / "SPEC-READY-alpha", "# [CLAIMED] My spec")
    with pytest.raises(RefusalError, match=r"\[CLAIMED\] sits ahead of the spec tag"):
        SpecLifecycle().observe(specdir)


@pytest.mark.integration
def test_observe_keeps_a_legacy_carrier(tmp_path: Path) -> None:
    """A tag on DISCOVERY.md is read there, and the spec file is still the target."""
    specdir = make_spec_dir(
        tmp_path / "SPEC-DRAFT-alpha",
        "# [DRAFT] My spec",
        filename="DISCOVERY.md",
    )
    spec = SpecLifecycle().observe(specdir)
    assert (spec.state, spec.carrier_path) == (State.DRAFT, specdir / "DISCOVERY.md")
    assert spec.is_legacy_carrier is True
    assert spec.spec_path == specdir / "SPEC.md"


@pytest.mark.integration
def test_find_returns_none_outside_a_spec(tmp_path: Path) -> None:
    """An ordinary directory belongs to no spec."""
    assert SpecLifecycle().find(tmp_path) is None


@pytest.mark.integration
def test_observe_refuses_outside_a_spec(tmp_path: Path) -> None:
    """The refusal names the three accepted prefixes."""
    with pytest.raises(RefusalError, match=r"not inside a spec directory"):
        SpecLifecycle().observe(tmp_path)


@pytest.mark.integration
def test_check_dir_matches_tag_accepts_the_matching_dir(tmp_path: Path) -> None:
    """A dir named for the tag state passes."""
    specdir = make_spec_dir(tmp_path / "SPEC-READY-alpha", "# [READY] My spec")
    spec = SpecLifecycle().observe(specdir)
    assert check_dir_matches_tag(spec, override=False, repair_hint="hint") is None


@pytest.mark.integration
def test_check_dir_matches_tag_refuses_a_disagreement(tmp_path: Path) -> None:
    """The tag wins, and the refusal names the directory it implies."""
    specdir = make_spec_dir(tmp_path / "SPEC-DRAFT-alpha", "# [READY] My spec")
    spec = SpecLifecycle().observe(specdir)
    with pytest.raises(RefusalError, match=r"Tag implies: .*SPEC-READY-alpha"):
        check_dir_matches_tag(spec, override=False, repair_hint="Run rename --fix.")


@pytest.mark.integration
def test_check_dir_matches_tag_honours_the_override(tmp_path: Path) -> None:
    """An override lets the caller work from the tag state without moving the dir."""
    specdir = make_spec_dir(tmp_path / "SPEC-DRAFT-alpha", "# [READY] My spec")
    spec = SpecLifecycle().observe(specdir)
    assert check_dir_matches_tag(spec, override=True, repair_hint="hint") is None


@pytest.mark.integration
def test_check_outside_spec_dir_refuses_a_nested_spec(tmp_path: Path) -> None:
    """A spec cannot be created inside another spec dir."""
    specdir = make_spec_dir(tmp_path / "SPEC-DRAFT-alpha", "# [DRAFT] My spec")
    with pytest.raises(RefusalError, match=r"sits inside a spec tree"):
        check_outside_spec_dir(specdir)


@pytest.mark.integration
def test_check_outside_spec_dir_refuses_a_legacy_container(tmp_path: Path) -> None:
    """A legacy container is a spec tree even though it is not a spec dir."""
    container = tmp_path / "_WIP_SPECS"
    container.mkdir()
    with pytest.raises(RefusalError, match=r"sits inside a spec tree"):
        check_outside_spec_dir(container)


@pytest.mark.integration
def test_check_outside_spec_dir_accepts_a_project_root(tmp_path: Path) -> None:
    """An ordinary project directory accepts a new spec."""
    assert check_outside_spec_dir(tmp_path) is None
