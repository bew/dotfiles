"""Characterisation tests for the spec document type and its file helpers."""

from datetime import datetime
from pathlib import Path

import pytest

from lib.document import (
    DISCOVERY_HEADING,
    EXPLO_POINTER_PARAGRAPH,
    LOADER_PARAGRAPH,
    SpecDocument,
    get_created_at_frontmatter,
    read_document,
    split_frontmatter,
)
from lib.lifecycle import Loader, RefusalError

FRONTMATTER = ["---", "created-at: 20261028T1946", "---"]
LOADER = list(LOADER_PARAGRAPH)


@pytest.fixture
def sample_spec(tmp_path: Path) -> Path:
    """Write a spec file holding a frontmatter block, a tag, a loader, and one body line."""
    specpath = tmp_path / "SPEC.md"
    specpath.write_text(
        "\n".join([*FRONTMATTER, "", "# [DRAFT] My spec", "", *LOADER, "", "Body line."]) + "\n"
    )
    return specpath


@pytest.mark.unit
@pytest.mark.parametrize(
    ("loader", "expected_lines"),
    [
        (Loader.NONE, []),
        (Loader.STANDARD, ["", *LOADER_PARAGRAPH]),
        (Loader.EXPLO, ["", *LOADER_PARAGRAPH, *EXPLO_POINTER_PARAGRAPH]),
    ],
)
def test_render_puts_the_loader_its_kind_names(loader: Loader, expected_lines: list[str]) -> None:
    """The loader block is derived from the kind, with a blank line before the body."""
    document = SpecDocument(frontmatter=[], heading="# [DRAFT] My spec", body=["Body."])
    assert document.render(loader) == "\n".join(
        ["# [DRAFT] My spec", *expected_lines, "", "Body."]
    ) + "\n"


@pytest.mark.unit
def test_render_puts_frontmatter_above_the_heading() -> None:
    """An existing block is re-emitted above the heading, separated by a blank line."""
    document = SpecDocument(frontmatter=FRONTMATTER, heading="# [DRAFT] My spec", body=[])
    assert document.render(Loader.NONE) == "\n".join([*FRONTMATTER, "", "# [DRAFT] My spec"]) + "\n"


@pytest.mark.unit
def test_render_keeps_a_bodyless_document_bodyless() -> None:
    """No trailing blank line is added to a document that has no body."""
    document = SpecDocument(frontmatter=[], heading="# [DRAFT] My spec", body=[])
    assert document.render(Loader.STANDARD) == "\n".join(
        ["# [DRAFT] My spec", "", *LOADER_PARAGRAPH]
    ) + "\n"


@pytest.mark.unit
def test_parse_splits_block_heading_and_body() -> None:
    """Parsing yields the block, the H1, and the body with the loader already stripped."""
    document = SpecDocument.parse([*FRONTMATTER, "", "# [DRAFT] My spec", "", *LOADER, "", "Body."])
    assert document == SpecDocument(
        frontmatter=FRONTMATTER,
        heading="# [DRAFT] My spec",
        body=["Body."],
    )


@pytest.mark.unit
def test_parse_anchors_the_heading_past_leading_blanks() -> None:
    """A leading blank line does not push the H1 out of position."""
    document = SpecDocument.parse([*FRONTMATTER, "", "", "", "# [DRAFT] My spec", "Body."])
    assert (document.heading, document.body) == ("# [DRAFT] My spec", ["Body."])


@pytest.mark.unit
def test_parse_of_an_empty_spec() -> None:
    """Nothing to parse yields an empty heading and body."""
    assert SpecDocument.parse([]) == SpecDocument(frontmatter=[], heading="", body=[])


@pytest.mark.unit
@pytest.mark.parametrize(
    ("heading", "expected_tag", "expected_title"),
    [
        ("# [DRAFT] My spec", "DRAFT", "My spec"),
        ("# [MAYBE-READY] Spaced", "MAYBE-READY", "Spaced"),
        ("# Bare title", None, "Bare title"),
        ("not a heading", None, "not a heading"),
    ],
)
def test_tag_and_title_derive_from_the_heading(
    heading: str,
    expected_tag: str | None,
    expected_title: str,
) -> None:
    """Tag and title come out of the one line that carries them."""
    document = SpecDocument(frontmatter=[], heading=heading, body=[])
    assert document.tag == expected_tag
    assert document.title == expected_title


@pytest.mark.unit
def test_tagged_keeps_the_title_by_default() -> None:
    """Retagging touches the tag alone."""
    document = SpecDocument(frontmatter=FRONTMATTER, heading="# [DRAFT] My spec", body=["Body."])
    assert document.tagged("READY") == SpecDocument(
        frontmatter=FRONTMATTER,
        heading="# [READY] My spec",
        body=["Body."],
    )


@pytest.mark.unit
def test_tagged_replaces_the_title_when_given() -> None:
    """An explicit title wins over the one the heading carried."""
    document = SpecDocument(frontmatter=[], heading="# [DRAFT] My spec", body=[])
    assert document.tagged("DRAFT", "Renamed spec").heading == "# [DRAFT] Renamed spec"


@pytest.mark.unit
def test_as_notes_drops_the_tag_and_the_block() -> None:
    """A notes file keeps the body, loses the tag, and gains the fixed discovery heading."""
    document = SpecDocument(frontmatter=FRONTMATTER, heading="# [DRAFT] My spec", body=["Notes."])
    assert document.as_notes() == SpecDocument(
        frontmatter=[],
        heading=DISCOVERY_HEADING,
        body=["Notes."],
    )


@pytest.mark.unit
@pytest.mark.parametrize(
    ("lines", "expected_frontmatter", "expected_body"),
    [
        ([], [], []),
        (["# [DRAFT] x"], [], ["# [DRAFT] x"]),
        ([*FRONTMATTER, "# [DRAFT] x"], list(FRONTMATTER), ["# [DRAFT] x"]),
        (["", "---", "---"], [], ["", "---", "---"]),
        (["  ---  ", "a: b", " --- "], ["  ---  ", "a: b", " --- "], []),
    ],
)
def test_split_frontmatter(
    lines: list[str],
    expected_frontmatter: list[str],
    expected_body: list[str],
) -> None:
    """Only a fence on line 1 opens a block, and a block never swallows body text."""
    assert split_frontmatter(lines) == (expected_frontmatter, expected_body)


@pytest.mark.unit
def test_split_frontmatter_refuses_unclosed_fence() -> None:
    """An opening fence with no closing one is a refusal, not body text."""
    with pytest.raises(RefusalError, match=r"no closing `---` line"):
        split_frontmatter(["---", "created-at: 1", "# [DRAFT] x"])


@pytest.mark.unit
def test_get_created_at_frontmatter_formats_the_given_time() -> None:
    """The block is a fence pair around a minute-precision stamp."""
    assert get_created_at_frontmatter(datetime(2026, 10, 28, 19, 46)) == [
        "---",
        "created-at: 20261028T1946",
        "---",
    ]


@pytest.mark.integration
def test_read_document_refuses_missing_file(tmp_path: Path) -> None:
    """A missing carrier names the file and says nothing changed."""
    with pytest.raises(RefusalError, match=r"no SPEC\.md in .*; nothing changed\."):
        read_document(tmp_path / "SPEC.md")
