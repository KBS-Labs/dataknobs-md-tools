"""Shared test fixtures for dataknobs-md-tools."""

import sys
from pathlib import Path

import pytest

# Ensure src/ is on the Python path for imports like `from python.svg_processor import ...`
SRC_DIR = Path(__file__).parent.parent / "src"
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture
def fixtures_dir() -> Path:
    """Path to the test fixtures directory."""
    return FIXTURES_DIR


@pytest.fixture
def sample_svg() -> str:
    """A minimal Mermaid-generated SVG for testing."""
    return (
        '<?xml version="1.0"?>'
        '<svg id="my-svg" viewBox="0 0 800 600" '
        'style="max-width: 800px; background-color: white;" '
        'aria-roledescription="flowchart-v2" '
        'role="graphics-document document" '
        'xmlns="http://www.w3.org/2000/svg">'
        "<style>#my-svg { fill: red; }</style>"
        "<g><text>Hello</text></g>"
        "</svg>"
    )


@pytest.fixture
def sample_svg_with_foreign_object() -> str:
    """A Mermaid SVG with foreignObject elements (generated when htmlLabels: true).

    This is the SVG structure Mermaid produces for labels containing HTML
    like <br/>, <i>, <b> tags. The foreignObject wraps an XHTML div.
    """
    return (
        '<svg id="my-svg" viewBox="0 0 800 600" '
        'style="max-width: 800px; background-color: white;" '
        'aria-roledescription="flowchart-v2" '
        'role="graphics-document document" '
        'xmlns="http://www.w3.org/2000/svg">'
        "<style>#my-svg { fill: red; }</style>"
        '<g class="node"><foreignObject width="200" height="50">'
        '<div xmlns="http://www.w3.org/1999/xhtml">'
        "<span>Line 1<br/>Line 2</span>"
        "</div></foreignObject></g>"
        '<g class="node"><foreignObject width="150" height="40">'
        '<div xmlns="http://www.w3.org/1999/xhtml">'
        "<span><i>italic</i> and <b>bold</b></span>"
        "</div></foreignObject></g>"
        "</svg>"
    )


@pytest.fixture
def sample_svg_with_markers() -> str:
    """A Mermaid SVG with marker definitions and URL references."""
    return (
        '<svg id="my-svg" viewBox="0 0 500 400" '
        'style="max-width: 500px;" '
        'xmlns="http://www.w3.org/2000/svg">'
        "<defs>"
        '<marker id="my-svg_flowchart-v2-pointEnd">'
        '<path class="arrowMarkerPath" d="M 0 0 L 10 5 L 0 10 z"/>'
        "</marker>"
        "</defs>"
        "<style>#my-svg { fill: #333; } #my-svg_flowchart-v2-pointEnd { stroke: #333; }</style>"
        '<path marker-end="url(#my-svg_flowchart-v2-pointEnd)" d="M 0 0 L 100 100"/>'
        "</svg>"
    )
