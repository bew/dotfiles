from dataclasses import dataclass
from enum import Enum
from pathlib import Path

SPEC_FILENAME = "SPEC.md"
DISCOVERY_FILENAME = "DISCOVERY.md"
# Files that may carry the H1 status tag, in authority order.
# `SPEC.md` carries it for every spec `init` creates; `DISCOVERY.md` only on a legacy spec,
# until the first command that rewrites the file converges it onto `SPEC.md`.
TAG_FILENAMES = (SPEC_FILENAME, DISCOVERY_FILENAME)

DRAFT_PREFIX = "SPEC-DRAFT-"
READY_PREFIX = "SPEC-READY-"
KO_PREFIX = "SPEC-KO-"
LEGACY_CONTAINERS = ("_WIP_SPECS", "_SPECS")

# H1 tags another tool may prepend to a spec heading, above the tag `manage-spec` wrote.
# Seeing one leftmost means the heading has a second owner, so `manage-spec` must not rewrite it.
FOREIGN_MARKERS = frozenset({"CLAIMED", "DONE"})

EXPLO_PREFIX = "EXPLO-"
EXPLO_BRIEF_FILENAME = f"{EXPLO_PREFIX}BRIEF.md"


class State(str, Enum):
    """Closed set of spec lifecycle states."""

    DISCOVERY = "discovery"
    EXPLO = "explo"
    DRAFT = "draft"
    MAYBE_READY = "maybe-ready"
    READY = "ready"
    ABANDONED = "abandoned"


class Loader(Enum):
    """The skill-loader blockquote a state's spec file carries above its body."""

    NONE = "none"
    STANDARD = "standard"
    EXPLO = "explo"


@dataclass(frozen=True)
class StateLayout:
    """How one lifecycle state is represented on disk."""

    tag: str
    dir_prefix: str
    loader: Loader

    def dir_name(self, slug: str) -> str:
        """Return the directory name this state gives the spec."""
        return f"{self.dir_prefix}{slug}"


# Single source of truth for the state layout.
# The four draft-family states share a prefix, so only their tag tells them apart.
STATE_LAYOUT = {
    State.DISCOVERY: StateLayout(tag="DISCOVERY", dir_prefix=DRAFT_PREFIX, loader=Loader.STANDARD),
    State.EXPLO: StateLayout(tag="EXPLO", dir_prefix=DRAFT_PREFIX, loader=Loader.EXPLO),
    State.DRAFT: StateLayout(tag="DRAFT", dir_prefix=DRAFT_PREFIX, loader=Loader.STANDARD),
    State.MAYBE_READY: StateLayout(
        tag="MAYBE-READY",
        dir_prefix=DRAFT_PREFIX,
        loader=Loader.STANDARD,
    ),
    State.READY: StateLayout(tag="READY", dir_prefix=READY_PREFIX, loader=Loader.NONE),
    State.ABANDONED: StateLayout(tag="ABANDONED", dir_prefix=KO_PREFIX, loader=Loader.STANDARD),
}

# Directory prefixes in use, in state order; several states may share one.
DIR_PREFIXES = tuple(dict.fromkeys(layout.dir_prefix for layout in STATE_LAYOUT.values()))

# H1 status tag owned by each state.
STATE_TAGS = {state: layout.tag for state, layout in STATE_LAYOUT.items()}
TAG_STATES = {tag: state for state, tag in STATE_TAGS.items()}

# Allowed target states per source state, excluding the universal targets below.
# `discovery` is never a target: the state only exists at `init`, and `DISCOVERY.md` stays
# editable from every later state.
TRANSITIONS = {
    State.DISCOVERY: {State.EXPLO, State.DRAFT},
    State.EXPLO: {State.DRAFT},
    State.DRAFT: {State.EXPLO, State.MAYBE_READY, State.READY},
    State.MAYBE_READY: {State.DRAFT, State.EXPLO, State.READY},
    State.READY: {State.DRAFT, State.MAYBE_READY, State.EXPLO},
    State.ABANDONED: {State.DRAFT, State.EXPLO},
}

# Targets reachable from every state without being listed per source state.
UNIVERSAL_TARGETS = {State.ABANDONED}


class ManageSpecError(Exception):
    """Base for every failure this script reports instead of a traceback."""


class RefusalError(ManageSpecError):
    """A refusal raised before anything was written."""


class PartialChangeError(ManageSpecError):
    """A failure after part of the change landed; the repair command names the way out."""

    def __init__(self, message: str, repair_command: str) -> None:
        super().__init__(f"{message}\n   {repair_command}")
        self.repair_command = repair_command


def get_target_dir(state: State, slug: str, project_root: Path) -> Path:
    """Return the directory a spec occupies in the given state."""
    return project_root / STATE_LAYOUT[state].dir_name(slug)
