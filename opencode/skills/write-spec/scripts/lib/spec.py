import re
from dataclasses import dataclass
from pathlib import Path

from lib.document import SpecDocument
from lib.lifecycle import (
    DIR_PREFIXES,
    SPEC_FILENAME,
    TRANSITIONS,
    UNIVERSAL_TARGETS,
    RefusalError,
    State,
    get_target_dir,
)


@dataclass(frozen=True)
class SessionVars:
    """The session variables a caller carries while working on a spec."""

    slug: str
    specdir: str
    specpath: str


@dataclass(frozen=True)
class Spec:
    """One spec directory, the state it sits in, and the document carrying its tag.

    `document` and `carrier_path` are None only for a legacy directory that holds no file yet,
    which `migrate` seeds before anything else reads them.
    """

    slug: str
    root: Path
    dir: Path
    state: State
    document: SpecDocument | None
    carrier_path: Path | None

    @property
    def spec_path(self) -> Path:
        """Path of the spec file, whether or not it exists yet."""
        return self.dir / SPEC_FILENAME

    @property
    def is_legacy_carrier(self) -> bool:
        """Whether the tag still lives on a legacy file rather than on the spec file."""
        return self.carrier_path is not None and self.carrier_path.name != SPEC_FILENAME

    @property
    def target_dir(self) -> Path:
        """Directory the spec's current state and slug call for."""
        return get_target_dir(self.state, slug=self.slug, project_root=self.root)

    def session_vars(self) -> SessionVars:
        """Return the caller's session variables, with paths relative to the project root."""
        carrier = self.carrier_path or self.spec_path
        return SessionVars(
            slug=self.slug,
            specdir=f"{self.dir.relative_to(self.root)}/",
            specpath=str(carrier.relative_to(self.root)),
        )


def check_transition_allowed(from_state: State, to_state: State) -> None:
    """Refuse a state change the transition table does not allow."""
    allowed = TRANSITIONS[from_state] | UNIVERSAL_TARGETS
    if to_state in allowed:
        return

    raise RefusalError(
        f"transition {from_state.value} → {to_state.value} is not allowed.\n"
        f"   Allowed from {from_state.value}: "
        f"{', '.join(sorted(state.value for state in allowed))}."
    )


def check_target_absent(target: Path) -> None:
    """Refuse to collide with an existing spec directory."""
    if target.exists():
        raise RefusalError(
            f"target directory already exists: {target}\n"
            f"   Move or remove it first; merging two specs is a manual decision."
        )


def check_slug(slug: str) -> None:
    """Refuse a slug that is empty or carries whitespace, a path separator, or a leading dash."""
    if not slug or re.search(r"[\s/]", slug) or slug.startswith("-"):
        raise RefusalError(
            f"invalid slug {slug!r}; "
            f"use a bare slug with no whitespace, path separator, or leading dash."
        )


def check_title(title: str) -> None:
    """Refuse a title that has no space, since a single word reads as a slug."""
    if not re.search(r"\s", title):
        raise RefusalError(
            f"invalid title {title!r}; a title needs more than one word.\n"
            f"   A single word is read as a slug — pass the title as two or more words."
        )


def check_dir_matches_tag(spec: Spec, override: bool, *, repair_hint: str) -> None:
    """Refuse when the directory name disagrees with the H1 tag.

    The H1 tag is authoritative: an override skips the check and the caller then works from the
    state the tag names. Repairing the directory name is the repair step's job.
    `repair_hint` completes the error message with the way out available to this command.
    """
    expected_dir = spec.target_dir
    if expected_dir == spec.dir or override:
        return

    raise RefusalError(
        f"directory name and H1 status tag disagree.\n"
        f"   Directory:   {spec.dir}\n"
        f"   Tag implies: {expected_dir}\n"
        f"   The H1 tag wins: {repair_hint}"
    )


def find_taken_specdirs(slug: str, project_root: Path) -> list[Path]:
    """Return every existing spec dir for a slug, across all states."""
    # States share prefixes, so dedupe the candidate paths instead of reporting one per state.
    candidates = {project_root / f"{prefix}{slug}" for prefix in DIR_PREFIXES}
    return sorted(specdir for specdir in candidates if specdir.exists())
