"""Tests for command-line parsing and dispatch, driven through an injected argument list."""

from pathlib import Path

import pytest

from lib.cli import main, parse_args


@pytest.mark.unit
def test_parse_args_reads_a_state_command() -> None:
    """A state command parses from the given arguments, with its repair flag."""
    args = parse_args(["ready", "--fix"])

    assert (args.command, args.fix) == ("ready", True)


@pytest.mark.unit
def test_parse_args_reads_migrate_ahead_of_argparse() -> None:
    """The undocumented command parses from the given arguments, not from the process ones."""
    args = parse_args(["migrate", "_WIP_SPECS/alpha"])

    assert (args.command, args.path) == ("migrate", "_WIP_SPECS/alpha")


@pytest.mark.unit
def test_parse_args_refuses_an_unknown_command() -> None:
    """An unknown command ends in argparse's invalid choice."""
    with pytest.raises(SystemExit) as exit_info:
        parse_args(["nope"])

    assert exit_info.value.code == 2


@pytest.mark.integration
def test_main_dispatches_on_the_given_arguments(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    """`main` runs the command its arguments name, instead of the process ones."""
    monkeypatch.chdir(tmp_path)

    main(["init", "alpha", "Alpha Spec"])

    assert capsys.readouterr().out.startswith("Session vars: 3 new")

