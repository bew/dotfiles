"""Smoke tests: the script body is importable as a module."""

from lib.cli import cli_main
from lib.lifecycle import State


def test_module_exposes_entry_point() -> None:
    """The importable module still offers the console entry point."""
    assert callable(cli_main)


def test_states_are_complete() -> None:
    """Every lifecycle state survives the move into a module."""
    assert [state.name for state in State] == [
        "DISCOVERY",
        "EXPLO",
        "DRAFT",
        "MAYBE_READY",
        "READY",
        "ABANDONED",
    ]
