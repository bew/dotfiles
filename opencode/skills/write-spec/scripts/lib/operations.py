import re
import subprocess
from dataclasses import dataclass, field, replace
from datetime import datetime
from pathlib import Path

from lib.document import (
    get_created_at_frontmatter,
    notes_document,
    read_document,
    seed_document,
)
from lib.lifecycle import (
    DIR_PREFIXES,
    DISCOVERY_FILENAME,
    EXPLO_PREFIX,
    FOREIGN_MARKERS,
    LEGACY_CONTAINERS,
    SPEC_FILENAME,
    STATE_LAYOUT,
    STATE_TAGS,
    TAG_FILENAMES,
    TAG_STATES,
    Loader,
    PartialChangeError,
    RefusalError,
    State,
)
from lib.spec import Spec, check_target_absent

# Only a reference ending in `.md` names an exploration file; prose about exploration does not.
LEGACY_EXPLO_PREFIX = "EXPLORATION-"
LEGACY_EXPLO_REFERENCE = re.compile(r"EXPLORATION-([A-Za-z0-9_.-]+\.md)")


@dataclass(frozen=True)
class MakeDir:
    """Create one directory; refuses when it already exists, like `mkdir`."""

    path: Path


@dataclass(frozen=True)
class WriteFile:
    """Replace the whole content of one file."""

    path: Path
    text: str


@dataclass(frozen=True)
class MoveDir:
    """Move a spec directory, preferring `git mv` so a tracked spec keeps its history.

    When the move fails, the repair command says how to recover: by then planning has already
    written something, so the failure is partial rather than a clean refusal.
    """

    source: Path
    target: Path
    project_root: Path
    repair_command: str


@dataclass(frozen=True)
class MoveFile:
    """Move one file, preferring `git mv` so a tracked file keeps its history."""

    source: Path
    target: Path
    project_root: Path


@dataclass(frozen=True)
class RemoveDir:
    """Remove one empty directory."""

    path: Path


type Action = MakeDir | WriteFile | MoveDir | MoveFile | RemoveDir


@dataclass(frozen=True)
class Plan:
    """Everything one operation changes, decided before any of it lands.

    `spec` is the spec as it will stand once every action has been applied.
    """

    actions: list[Action]
    spec: Spec
    notes: list[str] = field(default_factory=list)

    def then(self, next_plan: "Plan") -> "Plan":
        """Return one plan that runs this plan's actions before the next plan's."""
        return Plan(
            actions=[*self.actions, *next_plan.actions],
            spec=next_plan.spec,
            notes=[*self.notes, *next_plan.notes],
        )


def apply(plan: Plan) -> None:
    """Carry out a plan's actions in order, stopping at the first failure."""
    for action in plan.actions:
        _apply_action(action)


def _apply_action(action: Action) -> None:
    """Run one action against the filesystem."""
    if isinstance(action, MakeDir):
        action.path.mkdir()
    elif isinstance(action, WriteFile):
        action.path.write_text(action.text)
    elif isinstance(action, MoveDir):
        _move_dir(action)
    elif isinstance(action, MoveFile):
        move_file(action.source, target=action.target, project_root=action.project_root)
    else:
        action.path.rmdir()


class SpecLifecycle:
    """Owns the ordered write steps one spec goes through: retag, rename, move, repair."""

    def find(self, cwd: Path | None = None) -> Spec | None:
        """Return the spec owning the directory, or None when it is not a spec directory."""
        specdir = cwd if cwd is not None else Path.cwd()
        prefix = next(
            (candidate for candidate in DIR_PREFIXES if specdir.name.startswith(candidate)),
            None,
        )
        if prefix is None:
            return None

        return self._open(
            specdir,
            prefix=prefix,
            project_root=specdir.parent,
            slug=specdir.name.removeprefix(prefix),
        )

    def observe(self, cwd: Path | None = None) -> Spec:
        """Resolve the spec owning the directory, refusing when it is not one."""
        spec = self.find(cwd)
        if spec is not None:
            return spec

        raise RefusalError(
            f"not inside a spec directory (cwd: {Path.cwd()}).\n"
            f"   Expected {DIR_PREFIXES[0]}<slug>/, {DIR_PREFIXES[1]}<slug>/, "
            f"or {DIR_PREFIXES[2]}<slug>/."
        )

    def plan_retag(self, spec: Spec, state: State, title: str | None = None) -> Plan:
        """Plan the status-tag rewrite for one state, converging a legacy carrier.

        The title is `title` when given, otherwise the one the carrier already holds.
        """
        if spec.document is None:
            raise RefusalError(f"no status tag to rewrite in {spec.dir}; nothing changed.")

        document = spec.document.tagged(STATE_TAGS[state], title)
        actions = [WriteFile(spec.spec_path, document.render(STATE_LAYOUT[state].loader))]
        if spec.is_legacy_carrier:
            notes = spec.document.as_notes().render(Loader.NONE)
            actions.append(WriteFile(spec.carrier_path, notes))

        return Plan(
            actions=actions,
            spec=replace(spec, state=state, document=document, carrier_path=spec.spec_path),
        )

    def plan_relocate(
        self,
        spec: Spec,
        target_dir: Path,
        *,
        repair_command: str | None = None,
    ) -> Plan:
        """Plan the move of a spec directory, noting the legacy container it drains."""
        move = MoveDir(
            spec.dir,
            target=target_dir,
            project_root=spec.root,
            repair_command=repair_command,
        )
        actions: list[Action] = [move]
        drained = _drained_container(spec.dir)
        if drained is not None:
            actions.append(RemoveDir(drained))
        carrier = spec.carrier_path
        moved_carrier = target_dir / carrier.name if carrier is not None else None
        return Plan(
            actions=actions,
            spec=replace(spec, dir=target_dir, carrier_path=moved_carrier),
            notes=[f"Removed empty {drained.name}/"] if drained is not None else [],
        )

    def plan_rebase(self, spec: Spec, new_base: str) -> Plan:
        """Plan the move of a spec under another base directory inside the project."""
        base_dir = (spec.root / new_base).resolve()

        if not base_dir.is_dir():
            raise RefusalError(
                f"base directory does not exist: {base_dir}\n"
                f"   Create it first; `rebase` never creates directories."
            )

        is_inside_project = base_dir == spec.root or spec.root in base_dir.parents
        if not is_inside_project:
            raise RefusalError(
                f"base directory is outside the project: {base_dir}\n"
                f"   Rebase only moves a spec within {spec.root}."
            )

        if base_dir == spec.dir.parent:
            raise RefusalError(f"spec is already under {base_dir}; nothing changed.")

        target_dir = base_dir / spec.dir.name
        check_target_absent(target_dir)
        repair_command = (
            f"Fix the cause, then rerun `manage-spec rebase {new_base}` from inside {spec.dir}."
        )
        return self.plan_relocate(spec, target_dir=target_dir, repair_command=repair_command)


    def _open(self, specdir: Path, prefix: str, *, project_root: Path, slug: str) -> Spec:
        """Read one spec dir and resolve the state its tag or its directory name names."""
        carrier = _find_carrier(specdir)
        document = read_document(carrier)
        tag = document.tag
        if tag is None:
            # A prefix shared by several states (the draft family) pins none of them.
            states = {
                state for state, layout in STATE_LAYOUT.items() if layout.dir_prefix == prefix
            }
            if len(states) != 1:
                raise RefusalError(
                    f"cannot derive the current state of {specdir}.\n"
                    f"   The H1 of {carrier} carries no status tag, and the directory "
                    f"name does not name a state."
                )
            state = next(iter(states))
        else:
            state = _state_from_tag(tag, carrier)

        return Spec(
            slug=slug,
            root=project_root,
            dir=specdir,
            state=state,
            document=document,
            carrier_path=carrier,
        )


class LegacyMigration:
    """Owns the one-way move of a legacy-layout spec into the current layout."""

    def plan(self, source_dir: Path) -> Plan:
        """Plan the migration of one legacy spec dir, keeping the state its H1 tag names."""
        spec = _open_legacy(source_dir)
        notes: list[str] = []
        if spec.document is not None and spec.document.tag is None:
            notes.append("NOTE: H1 has no status tag; migrating as draft.")

        check_target_absent(spec.target_dir)
        renames = _collect_legacy_explo_renames(spec.dir)
        actions: list[Action] = [
            MoveFile(source, target=target, project_root=spec.root) for source, target in renames
        ]
        notes += [f"Renamed: {source.name} -> {target.name}" for source, target in renames]

        reference_writes = _plan_explo_reference_writes(spec.dir, renames)
        actions += reference_writes
        if reference_writes:
            notes.append(f"Updated exploration references in {len(reference_writes)} file(s).")

        layout = STATE_LAYOUT[spec.state]
        if spec.document is None:
            seed = seed_document(
                spec.state,
                title=spec.slug,
                frontmatter_lines=get_created_at_frontmatter(now=_legacy_created_at(spec.dir)),
            )
            actions.append(WriteFile(spec.spec_path, seed.render(layout.loader)))
            actions.append(
                WriteFile(spec.dir / DISCOVERY_FILENAME, notes_document().render(Loader.NONE))
            )
            notes.append(
                f"NOTE: no {SPEC_FILENAME}; seeded {SPEC_FILENAME} and {DISCOVERY_FILENAME} "
                f"in the {spec.state.value} state."
            )
            spec = replace(spec, carrier_path=spec.spec_path)
        else:
            document = spec.document.tagged(layout.tag)
            actions.append(WriteFile(spec.carrier_path, document.render(layout.loader)))
            spec = replace(spec, document=document)

        repair_command = f"Fix the cause, then rerun `manage-spec migrate {spec.dir}`."
        move = SpecLifecycle().plan_relocate(
            spec, target_dir=spec.target_dir, repair_command=repair_command
        )
        return Plan(actions=actions, spec=spec, notes=notes).then(move)


def _legacy_created_at(specdir: Path) -> datetime:
    """Return when a legacy spec dir was written, from the oldest file it still holds.

    A legacy spec carries no `created-at` of its own, so the oldest file mtime is the closest
    record of its creation; a fresh clone loses it and the migration time stands in.
    """
    stamps = [path.stat().st_mtime for path in specdir.iterdir() if path.is_file()]
    if not stamps:
        return datetime.now()

    return datetime.fromtimestamp(min(stamps))


def plan_new_spec(
    specdir: Path,
    state: State,
    slug: str,
    title: str,
    frontmatter_lines: list[str] | None = None,
) -> Plan:
    """Plan a fresh spec dir: `SPEC.md` carries the tag, `DISCOVERY.md` is an empty notes file."""
    specpath = specdir / SPEC_FILENAME
    seed = seed_document(state, title=title, frontmatter_lines=frontmatter_lines)
    spec = Spec(
        slug=slug,
        root=specdir.parent,
        dir=specdir,
        state=state,
        document=None,
        carrier_path=specpath,
    )
    return Plan(
        actions=[
            MakeDir(specdir),
            WriteFile(specpath, seed.render(STATE_LAYOUT[state].loader)),
            WriteFile(specdir / DISCOVERY_FILENAME, notes_document().render(Loader.NONE)),
        ],
        spec=spec,
    )



def move_maybe_tracked(source: Path, target: Path, project_root: Path) -> bool:
    """Move source to target with `git mv` when git tracks it; return whether git moved it.

    Returns False when the source is untracked or outside the repository, leaving the move to
    the caller. A failing `git mv` raises RefusalError.
    """
    repo_root = get_git_root(project_root)
    if repo_root is None:
        return False

    try:
        relative_source = source.relative_to(repo_root)
        relative_target = target.relative_to(repo_root)
    except ValueError:
        return False

    if not run_git(repo_root, "ls-files", "--", str(relative_source)).strip():
        return False

    run_git(repo_root, "mv", "--", str(relative_source), str(relative_target))
    return True


def move_file(source: Path, target: Path, project_root: Path) -> None:
    """Move one file, preferring `git mv` so a tracked file keeps its history."""
    if move_maybe_tracked(source, target=target, project_root=project_root):
        return
    source.rename(target)


def _drained_container(specdir: Path) -> Path | None:
    """Return the legacy container a pending move of specdir would leave empty."""
    container = specdir.parent
    if container.name not in LEGACY_CONTAINERS:
        return None

    return container if [*container.iterdir()] == [specdir] else None


def _move_dir(action: MoveDir) -> None:
    """Move a spec dir, preferring `git mv` so a tracked spec keeps its history.

    Raises PartialChangeError carrying the action's repair command when the move fails,
    because planning has already written something by then.
    """
    action.target.parent.mkdir(parents=True, exist_ok=True)

    try:
        tracked = move_maybe_tracked(
            action.source, target=action.target, project_root=action.project_root
        )
        if not tracked:
            action.source.rename(action.target)
    except (OSError, RefusalError) as exc:
        raise PartialChangeError(
            f"could not move {action.source} to {action.target}: {exc}\n"
            f"   The directory did not move.",
            action.repair_command,
        ) from exc


def get_git_root(path: Path) -> Path | None:
    """Return the repository root containing path, or None outside a repo."""
    try:
        result = subprocess.run(
            ["git", "-C", str(path), "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return Path(result.stdout.strip())


def run_git(repo_root: Path, *args: str) -> str:
    """Run a git command and return its stdout, raising RefusalError on failure."""
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            capture_output=True,
            text=True,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise RefusalError(f"could not run git {' '.join(args)}: {exc}") from exc

    if result.returncode != 0:
        raise RefusalError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


def _find_carrier(specdir: Path) -> Path:
    """Return the file carrying the status tag, refusing when the dir holds neither one."""
    carrier = _carrier_path(specdir)
    if carrier is not None:
        return carrier

    raise RefusalError(f"no {SPEC_FILENAME} or {DISCOVERY_FILENAME} in {specdir}; nothing changed.")


def _carrier_path(specdir: Path) -> Path | None:
    """Return the file that would carry the status tag, or None when the dir holds neither."""
    return next(
        (specdir / filename for filename in TAG_FILENAMES if (specdir / filename).exists()),
        None,
    )


def _open_legacy(source_dir: Path) -> Spec:
    """Read a spec dir written in the legacy `_WIP_SPECS/` or `_SPECS/` layout."""
    container = source_dir.parent
    if container.name not in LEGACY_CONTAINERS:
        raise RefusalError(
            f"not a legacy spec directory: {source_dir}\n"
            f"   Expected <dir>/{LEGACY_CONTAINERS[0]}/<slug>/ or "
            f"<dir>/{LEGACY_CONTAINERS[1]}/<slug>/."
        )

    project_root = container.parent
    carrier = _carrier_path(source_dir)
    if carrier is None:
        # An exploration-only legacy dir: no spec yet, so it enters the explo state.
        return Spec(
            slug=source_dir.name,
            root=project_root,
            dir=source_dir,
            state=State.EXPLO,
            document=None,
            carrier_path=None,
        )

    document = read_document(carrier)
    state = State.DRAFT if document.tag is None else _state_from_tag(document.tag, carrier)
    return Spec(
        slug=source_dir.name,
        root=project_root,
        dir=source_dir,
        state=state,
        document=document,
        carrier_path=carrier,
    )


def _state_from_tag(tag: str, carrier: Path) -> State:
    """Return the lifecycle state a known H1 status tag names."""
    state = TAG_STATES.get(tag)
    if state is not None:
        return state

    message = (
        f"unknown status tag [{tag}] in {carrier}.\n"
        f"   Expected one of: {', '.join(STATE_TAGS.values())}."
    )
    if tag in FOREIGN_MARKERS:
        message += (
            f"\n   [{tag}] sits ahead of the spec tag, so another tool wrote it and this "
            f"heading has a second owner."
            f"\n   Stop and ask the user to reset the tag before running manage-spec again."
        )
    raise RefusalError(message)


def _plan_explo_reference_writes(
    specdir: Path,
    renames: list[tuple[Path, Path]],
) -> list[WriteFile]:
    """Plan the rewrites that point references at the new exploration filenames."""
    renamed_to = {source.name: target for source, target in renames}
    writes = []
    for path in sorted(specdir.glob("*.md")):
        text = path.read_text()
        updated = LEGACY_EXPLO_REFERENCE.sub(r"EXPLO-\1", text)
        if updated == text:
            continue
        writes.append(WriteFile(renamed_to.get(path.name, path), updated))
    return writes



def _collect_legacy_explo_renames(specdir: Path) -> list[tuple[Path, Path]]:
    """Return the `EXPLORATION-*` files to rename, refusing to overwrite an `EXPLO-*` file."""
    renames = []
    for path in sorted(specdir.iterdir()):
        if not path.is_file() or not path.name.startswith(LEGACY_EXPLO_PREFIX):
            continue

        target = path.with_name(EXPLO_PREFIX + path.name.removeprefix(LEGACY_EXPLO_PREFIX))
        if target.exists():
            raise RefusalError(
                f"cannot rename {path.name}: {target.name} already exists.\n"
                f"   Merge the two files by hand first; `migrate` never overwrites."
            )
        renames.append((path, target))
    return renames

