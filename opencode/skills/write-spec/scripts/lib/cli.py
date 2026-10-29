import argparse
import sys

from lib.commands import (
    CommandResult,
    cmd_init,
    cmd_migrate,
    cmd_rebase,
    cmd_rename,
    cmd_transition,
)
from lib.lifecycle import ManageSpecError, State
from lib.spec import SessionVars


def print_err(message: str) -> None:
    """Print message to stderr."""
    print(message, file=sys.stderr)


def render(result: CommandResult) -> None:
    """Print one command's warnings, lines, session variables, and trailing lines."""
    for warning in result.warnings:
        print_err(warning)
    for line in result.lines:
        print(line)
    if result.current is not None:
        report_vars(result.previous, result.current)
    for line in result.trailing:
        print(line)


def report_vars(previous: SessionVars | None, current: SessionVars) -> None:
    """Report every session variable, as new or changed against the previous ones."""
    items = get_var_items(current)
    if previous is None:
        print_var_block(f"Session vars: {len(items)} new", items)
        return

    pairs = zip(items, get_var_items(previous), strict=True)
    changed = [
        (name, value) for (name, value), (_, previous_value) in pairs if value != previous_value
    ]
    if not changed:
        print("Session vars: unchanged")
        return

    print_var_block(f"Session vars: {len(changed)} changed", changed)


def get_var_items(session_vars: SessionVars) -> list[tuple[str, str]]:
    """Return the session variables as ordered `(name, value)` pairs."""
    return [
        ("slug", session_vars.slug),
        ("specdir", session_vars.specdir),
        ("specpath", session_vars.specpath),
    ]


def print_var_block(header: str, items: list[tuple[str, str]]) -> None:
    """Print the vars header followed by one bullet per variable."""
    print(header)
    for name, value in items:
        print(f"- ${name} = {value}")


def parse_migrate_args(argv: list[str]) -> argparse.Namespace:
    """Parse the undocumented `migrate` command, kept out of the advertised command list."""
    parser = argparse.ArgumentParser(
        prog="manage-spec migrate",
        description="Move a spec out of a legacy _WIP_SPECS/ or _SPECS/ directory.",
    )
    parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help="legacy spec directory (default: the current directory)",
    )
    args = parser.parse_args(argv)
    args.command = "migrate"
    return args


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse the given arguments, defaulting to the ones the process was called with."""
    args = sys.argv[1:] if argv is None else argv
    if args and args[0] == "migrate":
        return parse_migrate_args(args[1:])

    parser = argparse.ArgumentParser(
        description="Create a spec directory and move a spec between lifecycle states.",
    )
    subcommands = parser.add_subparsers(
        dest="command",
        required=True,
        title="commands",
        metavar="<command>",
    )

    init = subcommands.add_parser(
        "init",
        help="create a spec directory in the discovery state",
        description="Create a spec directory in the discovery state, under the current directory.",
    )
    init.add_argument("slug", help="kebab-case slug, without any SPEC- prefix")
    init.add_argument(
        "title",
        nargs="?",
        default=None,
        help="H1 title; defaults to the slug",
    )

    rename = subcommands.add_parser(
        "rename",
        help="rename the spec slug, or retitle it",
        description=(
            "Rename the spec slug or replace its H1 title. "
            "A single word is read as a slug; a spaced argument is read as a title."
        ),
    )
    rename.add_argument(
        "target",
        help="new slug (one word), or new title (two or more words)",
    )
    rename.add_argument(
        "new_title",
        nargs="?",
        default=None,
        help="replacement H1 title, when the first argument is a slug",
    )
    rename.add_argument(
        "--fix",
        dest="fix",
        action="store_true",
        help="repair a directory name that disagrees with the H1 tag",
    )

    rebase = subcommands.add_parser(
        "rebase",
        help="move the spec under another base directory",
        description=(
            "Move the spec directory under another base directory inside the project, "
            "keeping its state and files."
        ),
    )
    rebase.add_argument(
        "new_base",
        help="destination base directory, relative to the project root; it must exist",
    )

    # Each lifecycle state is its own command, so state and directory share one vocabulary.
    for state in State:
        state_parser = subcommands.add_parser(
            state.value,
            help=f"move the spec to the {state.value} state",
            description=f"Move the spec to the {state.value} state.",
        )
        state_parser.add_argument(
            "--fix",
            dest="fix",
            action="store_true",
            help="repair a directory name that disagrees with the H1 tag",
        )

    # Undocumented on purpose: it exists to drain the pre-rename layout, not for daily use.
    # Registering it as a subparser would advertise it in the command list, so it is parsed
    # ahead of argparse instead.
    return parser.parse_args(args)


def main(argv: list[str] | None = None) -> None:
    """Run the command the caller asked for."""
    args = parse_args(argv)

    if args.command == "init":
        result = cmd_init(args.slug, args.title)
    elif args.command == "rename":
        result = cmd_rename(args.target, new_title=args.new_title, fix=args.fix)
    elif args.command == "rebase":
        result = cmd_rebase(args.new_base)
    elif args.command == "migrate":
        result = cmd_migrate(args.path)
    else:
        result = cmd_transition(args.command, args.fix)

    render(result)


def cli_main() -> int:
    """Console-script entry point; return the process exit status."""
    try:
        main()
    except ManageSpecError as exc:
        print_err(f"!! ERROR: {exc}")
        return 1
    return 0
