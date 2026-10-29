import re
from dataclasses import dataclass, replace
from datetime import datetime
from pathlib import Path

from lib.lifecycle import STATE_LAYOUT, Loader, RefusalError, State

H1_TAG_PATTERN = re.compile(r"^#\s+\[(?P<tag>[A-Z][A-Z-]*)\]\s*(?P<title>.*)$")
H1_BARE_PATTERN = re.compile(r"^#\s+(?P<title>.*)$")

# Frontmatter block: a `---` fence, `created-at`, and a closing fence, above the H1.
FRONTMATTER_FENCE = "---"
CREATED_AT_KEY = "created-at"
# strftime pattern of the `created-at` value: date digits, `T`, time digits, at minute precision.
CREATED_AT_FORMAT = "%Y%m%dT%H%M"

# Fixed H1 `init` gives `DISCOVERY.md`: the notes file carries no title and no status tag.
DISCOVERY_HEADING = "# Discovery notes"

LOADER_PARAGRAPH = (
    "> IMPORTANT: Before any drafting/planning/editing of this spec,",
    "> agents MUST load one of the spec-writing skills first.",
)

# Extra blockquote lines appended to the loader while a spec sits in the explo state.
# Contiguous `>` lines keep it part of the same strippable loader block.
EXPLO_POINTER_PARAGRAPH = (
    ">",
    "> IMPORTANT: This spec is still in exploration.",
    "> Exploration material lives in `EXPLO-BRIEF.md`;",
    "> the `design-exploration` skill owns it until the spec is promoted to draft.",
)

# Specs written before the plural wording carry the singular line. Accepting it lets a rewrite
# normalise the loader instead of stacking a second blockquote above the stale one.
LEGACY_LOADER_PARAGRAPH = (
    "> agents MUST load one of the spec-writing skill first.",
)

# The exact lines `manage-spec` owns above the spec body. Stripping matches these verbatim,
# so a body that legitimately opens with another blockquote survives.
LOADER_LINES = frozenset({*LOADER_PARAGRAPH, *EXPLO_POINTER_PARAGRAPH, *LEGACY_LOADER_PARAGRAPH})


@dataclass(frozen=True)
class SpecDocument:
    """A spec file split into the parts `manage-spec` owns and the body it leaves alone."""

    frontmatter: list[str]
    heading: str
    body: list[str]

    @classmethod
    def parse(cls, lines: list[str]) -> "SpecDocument":
        """Read lines into a document, with any loader block stripped from the body."""
        frontmatter_lines, rest = split_frontmatter(lines)
        # A leading blank line must not push the H1 out of position.
        first_content = next((index for index, line in enumerate(rest) if line.strip()), len(rest))
        body = rest[first_content:]
        return cls(
            frontmatter=frontmatter_lines,
            heading=get_h1_line(body),
            body=strip_loader_paragraph(body[1:]),
        )

    @property
    def tag(self) -> str | None:
        """Status tag carried by the heading, or None when it carries none."""
        return parse_h1_tag(self.heading)

    @property
    def title(self) -> str:
        """Title carried by the heading, without the tag or hashes."""
        return parse_h1_title(self.heading)

    def tagged(self, tag: str, title: str | None = None) -> "SpecDocument":
        """Return the document with a new status tag, keeping or replacing the title."""
        return replace(self, heading=f"# [{tag}] {self.title if title is None else title}")

    def as_notes(self) -> "SpecDocument":
        """Return the document as a plain notes file: fixed heading, no frontmatter block."""
        return SpecDocument(frontmatter=[], heading=DISCOVERY_HEADING, body=list(self.body))

    def render(self, loader: Loader) -> str:
        """Render the document, putting the loader block the given kind names above the body."""
        lines = [*self.frontmatter, ""] if self.frontmatter else []
        lines.append(self.heading)
        lines.extend(loader_lines(loader))
        if self.body:
            lines.extend(("", *self.body))
        return "\n".join(lines) + "\n"


def split_frontmatter(lines: list[str]) -> tuple[list[str], list[str]]:
    """Split lines into the frontmatter block (fences included) and the remaining body.

    The block only counts when the opening fence is the very first line and a closing fence
    follows it; an unclosed fence is refused rather than silently read as body text.
    """
    if not lines or lines[0].strip() != FRONTMATTER_FENCE:
        return [], lines

    closing_index = next(
        (index for index in range(1, len(lines)) if lines[index].strip() == FRONTMATTER_FENCE),
        None,
    )
    if closing_index is None:
        raise RefusalError(
            f"frontmatter opened at line 1 has no closing `{FRONTMATTER_FENCE}` line.\n"
            "   Close the block, or drop the opening fence; nothing changed."
        )

    return lines[: closing_index + 1], lines[closing_index + 1 :]


def read_spec_parts(specpath: Path) -> tuple[list[str], list[str]]:
    """Read a spec file into its frontmatter block and its body anchored at the H1."""
    if not specpath.exists():
        raise RefusalError(f"no {specpath.name} in {specpath.parent}; nothing changed.")

    frontmatter_lines, body = split_frontmatter(specpath.read_text().splitlines())
    # A leading blank line must not push the H1 out of position: the rewrite anchors on body[0].
    first_content = next((index for index, line in enumerate(body) if line.strip()), len(body))
    return frontmatter_lines, body[first_content:]


def read_spec_lines(specpath: Path) -> list[str]:
    """Read a spec file as body lines, with any frontmatter block removed."""
    return read_spec_parts(specpath)[1]


def get_h1_line(lines: list[str]) -> str:
    """Return the H1 line of a spec body, or an empty string when the body has none."""
    return lines[0] if lines else ""


def parse_h1_tag(header: str) -> str | None:
    """Return the H1 status tag, or None when the header carries no `[TAG]` prefix."""
    match = H1_TAG_PATTERN.match(header)
    return match.group("tag") if match else None


def parse_h1_title(header: str) -> str:
    """Return the H1 title, with any status tag and leading hashes stripped."""
    tagged = H1_TAG_PATTERN.match(header)
    if tagged:
        return tagged.group("title")
    bare = H1_BARE_PATTERN.match(header)
    return bare.group("title") if bare else header


def strip_loader_paragraph(lines: list[str]) -> list[str]:
    """Drop the skill-loader blockquote plus the blank lines around it."""
    body = list(lines)
    while body and not body[0].strip():
        body.pop(0)
    if not body or body[0] not in LOADER_LINES:
        return body

    while body and body[0] in LOADER_LINES:
        body.pop(0)
    while body and not body[0].strip():
        body.pop(0)
    return body


def loader_lines(loader: Loader) -> list[str]:
    """Return the blank separator and blockquote lines a loader kind puts above the body."""
    if loader is Loader.NONE:
        return []
    if loader is Loader.EXPLO:
        return ["", *LOADER_PARAGRAPH, *EXPLO_POINTER_PARAGRAPH]
    return ["", *LOADER_PARAGRAPH]


def get_created_at_frontmatter(now: datetime | None = None) -> list[str]:
    """Return the frontmatter block for a new spec, stamped with the given creation time."""
    stamp = (now or datetime.now()).strftime(CREATED_AT_FORMAT)
    return [FRONTMATTER_FENCE, f"{CREATED_AT_KEY}: {stamp}", FRONTMATTER_FENCE]


def read_document(specpath: Path) -> SpecDocument:
    """Read a spec file into a document."""
    if not specpath.exists():
        raise RefusalError(f"no {specpath.name} in {specpath.parent}; nothing changed.")

    return SpecDocument.parse(specpath.read_text().splitlines())


def notes_document() -> SpecDocument:
    """Return the plain discovery-notes page a spec directory carries beside `SPEC.md`."""
    return SpecDocument(frontmatter=[], heading=DISCOVERY_HEADING, body=[])


def seed_document(
    state: State,
    title: str,
    frontmatter_lines: list[str] | None = None,
) -> SpecDocument:
    """Return a carrier document holding the frontmatter block, H1 tag, and empty body."""
    return SpecDocument(
        frontmatter=list(frontmatter_lines or []),
        heading=f"# [{STATE_LAYOUT[state].tag}] {title}",
        body=[],
    )

