from dataclasses import dataclass, field, replace
from pathlib import Path

from lib.document import (
    get_created_at_frontmatter,
    get_h1_line,
    parse_h1_tag,
    read_spec_lines,
)
from lib.lifecycle import (
    DIR_PREFIXES,
    DISCOVERY_FILENAME,
    LEGACY_CONTAINERS,
    SPEC_FILENAME,
    RefusalError,
    State,
    get_target_dir,
)
from lib.operations import (
    LegacyMigration,
    SpecLifecycle,
    apply,
    plan_new_spec,
)
from lib.spec import (
    SessionVars,
    Spec,
    check_dir_matches_tag,
    check_slug,
    check_target_absent,
    check_title,
    check_transition_allowed,
    find_taken_specdirs,
)

REPAIR_INSTRUCTION = "Fix the cause, then repair the directory name from inside it:"


@dataclass(frozen=True)
class CommandResult:
    """What one command reports: its lines, the vars before and after, and any warnings."""

    lines: list[str]
    current: SessionVars | None
    previous: SessionVars | None
    trailing: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class RenameRequest:
    """What a `rename` invocation asks for: a new slug, a new title, or both."""

    slug: str | None
    title: str | None


def parse_rename_request(target: str, new_title: str | None) -> RenameRequest:
    """Read the target argument as a slug or as a title, refusing two titles."""
    is_title_form = " " in target
    if is_title_form and new_title is not None:
        raise RefusalError(
            f"two titles given: {target!r} and {new_title!r}.\n"
            f"   Pass a slug and a title, or a single title."
        )

    if is_title_form:
        check_title(target)
        return RenameRequest(slug=None, title=target)

    check_slug(target)
    if new_title is not None:
        check_title(new_title)
    return RenameRequest(slug=target, title=new_title)


def cmd_init(slug: str, title: str | None) -> CommandResult:
    """Create a spec directory in the discovery state, under the current directory.

    Seeds both carrier files: `SPEC.md` with the frontmatter block, H1 tag, and loader, and
    `DISCOVERY.md` with the fixed discovery heading only.
    The draft skeleton stays with `Phase:Draft`.
    """
    check_slug(slug)
    if title is not None:
        check_title(title)
    project_root = Path.cwd()
    check_outside_spec_dir(project_root)
    specdir = get_target_dir(State.DISCOVERY, slug=slug, project_root=project_root)

    # A slug may only exist once across every state, otherwise two specs drift apart.
    taken = find_taken_specdirs(slug, project_root)
    if taken:
        existing = taken[0]
        # An abandoned spec is not editable in place, so pointing at its directory is not enough.
        is_abandoned = existing.name.startswith(DIR_PREFIXES[2])
        way_out = (
            "run `manage-spec draft` from inside it to revive it, or pick another slug."
            if is_abandoned
            else "cd into it instead, or pick another slug."
        )
        raise RefusalError(
            f"spec {slug!r} already exists at {existing}; nothing changed.\n"
            f"   {way_out}"
        )

    plan = plan_new_spec(
        specdir,
        State.DISCOVERY,
        slug=slug,
        title=title or slug,
        frontmatter_lines=get_created_at_frontmatter(),
    )
    apply(plan)

    notes_path = specdir.relative_to(project_root) / DISCOVERY_FILENAME
    return CommandResult(
        lines=[],
        current=plan.spec.session_vars(),
        previous=None,
        trailing=["", f"Next: record the discovery notes in {notes_path}"],
    )


def cmd_transition(state_name: str, fix: bool) -> CommandResult:
    """Move the spec to another lifecycle state, rewriting the tag and paragraph.

    `fix` repairs a directory name that disagrees with the H1 tag before transitioning.
    """
    lifecycle = SpecLifecycle()
    spec = lifecycle.observe()
    target_state = State(state_name)
    warnings = secondary_carrier_warning(spec)
    lines: list[str] = []

    tag = spec.document.tag if spec.document is not None else None
    if tag is None:
        if fix:
            raise RefusalError(
                f"cannot repair the directory name: the H1 of {spec.carrier_path} "
                f"carries no status tag.\n"
                f"   Give it a status tag, or move the spec dir by hand."
            )
        lines.append("NOTE: H1 has no status tag; using the directory name as the current state.")
    else:
        check_dir_matches_tag(
            spec,
            override=fix,
            repair_hint="rerun with --fix to repair the directory name.",
        )

    previous = spec.session_vars()

    # Repair first: every later step derives the target directory from the tag.
    if fix and tag is not None and spec.target_dir != spec.dir:
        check_target_absent(spec.target_dir)
        repair = lifecycle.plan_relocate(
            spec,
            target_dir=spec.target_dir,
            repair_command=_repair_command(spec, spec.state),
        )
        apply(repair)
        spec = repair.spec
        lines.extend(repair.notes)

    if spec.state == target_state:
        lines.append(f"State: {target_state.value} (already current)")
        return CommandResult(
            lines=lines,
            current=spec.session_vars(),
            previous=previous,
            warnings=warnings,
        )

    check_transition_allowed(spec.state, target_state)

    target_dir = get_target_dir(target_state, slug=spec.slug, project_root=spec.root)
    needs_move = target_dir != spec.dir
    if needs_move:
        check_target_absent(target_dir)

    # The transition retags through the shared helper, so a legacy DISCOVERY.md carrier
    # converges onto SPEC.md on the same step.
    repair_command = _repair_command(spec, target_state)
    plan = lifecycle.plan_retag(spec, state=target_state)
    if needs_move:
        plan = plan.then(
            lifecycle.plan_relocate(plan.spec, target_dir=target_dir, repair_command=repair_command)
        )
    apply(plan)
    spec = plan.spec
    lines.extend(plan.notes)

    lines.append(f"State: {target_state.value}")
    return CommandResult(
        lines=lines,
        current=spec.session_vars(),
        previous=previous,
        warnings=warnings,
    )


def cmd_rename(target: str, new_title: str | None, fix: bool) -> CommandResult:
    """Rename the spec slug or its H1 title; a spaced argument is a title.

    `fix` also repairs a directory name that disagrees with the H1 tag, since the target is
    derived from the tag.
    """
    request = parse_rename_request(target, new_title)
    lifecycle = SpecLifecycle()
    spec = lifecycle.observe()

    tag = spec.document.tag if spec.document is not None else None
    if tag is not None:
        check_dir_matches_tag(
            spec,
            override=fix,
            repair_hint="rerun with --fix to repair the directory name.",
        )

    target_slug = request.slug if request.slug is not None else spec.slug
    target_dir = get_target_dir(spec.state, slug=target_slug, project_root=spec.root)
    is_retitle_only = target_dir == spec.dir
    if is_retitle_only and request.title is None:
        raise RefusalError(f"already named {target_slug}; nothing changed.")
    if not is_retitle_only:
        taken = find_taken_specdirs(target_slug, spec.root)
        if taken:
            raise RefusalError(
                f"spec {target_slug!r} already exists at {taken[0]}; nothing changed.\n"
                f"   Pick another slug, or rename that spec instead."
            )

    # Capture the vars before any write: a converging rewrite moves the carrier to SPEC.md.
    previous = spec.session_vars()
    original_slug = spec.slug
    lines: list[str] = []

    # Rename retags through the shared helper: a legacy DISCOVERY.md carrier converges onto
    # SPEC.md here too, so one file owns the tag whatever command touched it.
    plan = lifecycle.plan_retag(spec, state=spec.state, title=request.title)
    if not is_retitle_only:
        plan = plan.then(
            lifecycle.plan_relocate(
                plan.spec,
                target_dir=target_dir,
                repair_command=_repair_command(spec, spec.state),
            )
        )
    apply(plan)
    spec = replace(plan.spec, slug=target_slug)
    lines.extend(plan.notes)

    if is_retitle_only:
        lines.append(f"Retitled: {request.title}")
    else:
        lines.append(f"Renamed: {original_slug} -> {target_slug}")

    return CommandResult(
        lines=lines,
        current=spec.session_vars(),
        previous=previous,
    )


def cmd_rebase(new_base: str) -> CommandResult:
    """Move the spec dir under another base directory inside the project.

    The base is resolved against the project root and must already exist.
    Files, tag, and state are left untouched.
    """
    lifecycle = SpecLifecycle()
    spec = lifecycle.observe()
    previous = spec.session_vars()
    old_location = spec.dir.relative_to(spec.root)

    plan = lifecycle.plan_rebase(spec, new_base)
    apply(plan)
    spec = plan.spec
    new_location = spec.dir.relative_to(spec.root)
    lines = [*plan.notes, f"Rebased: {old_location} -> {new_location}"]
    return CommandResult(lines=lines, current=spec.session_vars(), previous=previous)


def cmd_migrate(path_arg: str | None) -> CommandResult:
    """Move a legacy-layout spec into the current layout, keeping the state its H1 tag names."""
    source_dir = Path(path_arg).resolve() if path_arg else Path.cwd()
    plan = LegacyMigration().plan(source_dir)
    apply(plan)
    spec = plan.spec
    old_location = source_dir.relative_to(spec.root)
    new_location = spec.dir.relative_to(spec.root)
    lines = [
        *plan.notes,
        f"Migrated: {old_location} -> {new_location}",
        f"State: {spec.state.value}",
    ]
    return CommandResult(lines=lines, current=None, previous=None)


def check_outside_spec_dir(project_root: Path) -> None:
    """Refuse to create a spec inside another spec dir or a legacy container."""
    inside_spec = SpecLifecycle().find(project_root) is not None

    # Legacy containers hold specs without being spec dirs themselves.
    inside_container = (
        project_root.name in LEGACY_CONTAINERS
        or project_root.parent.name in LEGACY_CONTAINERS
    )
    if not (inside_spec or inside_container):
        return

    raise RefusalError(
        f"cannot create a spec at {project_root}: that location sits inside a spec tree.\n"
        f"   Run `init` from the project directory, not from inside a spec or its containers."
    )


def secondary_carrier_warning(spec: Spec) -> list[str]:
    """Warn when the non-authoritative carrier still holds a status tag."""
    if spec.carrier_path is None or spec.carrier_path.name != SPEC_FILENAME:
        return []

    discoverypath = spec.dir / DISCOVERY_FILENAME
    if not discoverypath.exists():
        return []

    lines = read_spec_lines(discoverypath)
    if parse_h1_tag(get_h1_line(lines)) is None:
        return []

    return [
        f"!! WARNING: {discoverypath} also carries a status tag.\n"
        f"   {SPEC_FILENAME} wins, so the tag there is ignored; review both files.",
    ]


def _repair_command(spec: Spec, state: State) -> str:
    """Complete a failed move with the way out that fits this spec's current location."""
    return f"{REPAIR_INSTRUCTION}\n      cd {spec.dir} && manage-spec {state.value} --fix"
