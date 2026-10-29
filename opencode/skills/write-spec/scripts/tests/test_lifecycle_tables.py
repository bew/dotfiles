"""Characterisation tests for the lifecycle state tables."""

from pathlib import Path

import pytest

from lib.lifecycle import (
    DIR_PREFIXES,
    DRAFT_PREFIX,
    KO_PREFIX,
    READY_PREFIX,
    STATE_LAYOUT,
    STATE_TAGS,
    TAG_STATES,
    TRANSITIONS,
    UNIVERSAL_TARGETS,
    Loader,
    State,
    get_target_dir,
)


def test_every_state_has_one_layout() -> None:
    """Each state maps to a layout, and the derived tables cover the same keys."""
    assert set(STATE_LAYOUT) == set(State)
    assert set(STATE_TAGS) == set(State)


def test_tags_are_unique_and_round_trip() -> None:
    """Tags identify one state each, so the reverse table loses nothing."""
    tags = list(STATE_TAGS.values())
    assert len(set(tags)) == len(tags)
    assert all(TAG_STATES[tag] is state for state, tag in STATE_TAGS.items())


def test_dir_prefixes_are_the_three_known_ones() -> None:
    """Only the draft, ready, and knockout prefixes reach the filesystem."""
    assert DIR_PREFIXES == (DRAFT_PREFIX, READY_PREFIX, KO_PREFIX)


def test_draft_family_shares_one_prefix() -> None:
    """The four draft-family states differ by tag alone, which is why the prefix pins no state."""
    draft_states = [state for state in State if STATE_LAYOUT[state].dir_prefix == DRAFT_PREFIX]
    assert draft_states == [State.DISCOVERY, State.EXPLO, State.DRAFT, State.MAYBE_READY]


@pytest.mark.unit
@pytest.mark.parametrize(
    ("state", "expected_dir_name"),
    [
        (State.DISCOVERY, "SPEC-DRAFT-alpha"),
        (State.EXPLO, "SPEC-DRAFT-alpha"),
        (State.DRAFT, "SPEC-DRAFT-alpha"),
        (State.MAYBE_READY, "SPEC-DRAFT-alpha"),
        (State.READY, "SPEC-READY-alpha"),
        (State.ABANDONED, "SPEC-KO-alpha"),
    ],
)
def test_get_target_dir(state: State, expected_dir_name: str) -> None:
    """A state's directory is its prefix joined with the slug, under the project root."""
    target = get_target_dir(state, slug="alpha", project_root=Path("/project"))
    assert target == Path("/project") / expected_dir_name


@pytest.mark.unit
@pytest.mark.parametrize(
    ("state", "expected_loader"),
    [
        (State.DISCOVERY, Loader.STANDARD),
        (State.EXPLO, Loader.EXPLO),
        (State.DRAFT, Loader.STANDARD),
        (State.MAYBE_READY, Loader.STANDARD),
        (State.READY, Loader.NONE),
        (State.ABANDONED, Loader.STANDARD),
    ],
)
def test_loader_kind_per_state(state: State, expected_loader: Loader) -> None:
    """Only a ready spec drops the loader, and only explo adds the exploration pointer."""
    assert STATE_LAYOUT[state].loader is expected_loader


def test_no_state_transitions_to_itself() -> None:
    """A transition always names a different state."""
    assert all(state not in targets for state, targets in TRANSITIONS.items())


def test_discovery_is_never_a_target() -> None:
    """Discovery exists only at init, so no command can return to it."""
    assert all(State.DISCOVERY not in targets for targets in TRANSITIONS.values())
    assert State.DISCOVERY not in UNIVERSAL_TARGETS


def test_universal_targets_are_not_repeated_per_state() -> None:
    """Abandoning is open from everywhere, so it is not listed in the per-state rows."""
    assert UNIVERSAL_TARGETS == {State.ABANDONED}
    assert all(State.ABANDONED not in targets for targets in TRANSITIONS.values())


def test_ready_can_return_to_either_draft_state() -> None:
    """Leaving ready keeps the spec revisable without leaving the lifecycle."""
    assert TRANSITIONS[State.READY] == {State.DRAFT, State.MAYBE_READY, State.EXPLO}
