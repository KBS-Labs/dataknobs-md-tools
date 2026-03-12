"""Tests for HTML processing functions.

These tests cover the process_html module which handles SVG inlining
for PDF generation across different Pandoc versions.
"""

import base64
import tempfile
from pathlib import Path

from python.process_html import process_html_file


class TestProcessHtmlFileWithBase64:
    """Tests for Pandoc 2.x base64-encoded SVG handling."""

    def _make_base64_svg(self, svg_content: str) -> str:
        """Encode SVG content as a base64 data URI img tag."""
        encoded = base64.b64encode(svg_content.encode("utf-8")).decode("utf-8")
        return f'<img src="data:image/svg+xml;base64,{encoded}" alt="diagram"/>'

    def test_decodes_and_inlines_base64_svg(self, sample_svg: str) -> None:
        """Base64-encoded SVGs should be decoded and wrapped in svg-container."""
        img_tag = self._make_base64_svg(sample_svg)
        html = f"<html><body><h1>Title</h1>{img_tag}</body></html>"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert '<div class="svg-container">' in result
        assert "<svg" in result
        assert "data:image/svg+xml;base64" not in result

    def test_base64_svg_gets_unique_ids(self, sample_svg: str) -> None:
        """Each base64 SVG should get unique IDs to prevent conflicts."""
        img1 = self._make_base64_svg(sample_svg)
        img2 = self._make_base64_svg(sample_svg)
        html = f"<html><body>{img1}{img2}</body></html>"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert 'id="my-svg-1"' in result
        assert 'id="my-svg-2"' in result

    def test_base64_svg_gets_normalized_sizing(self, sample_svg: str) -> None:
        """Base64 SVGs should have sizing normalized for PDF output."""
        img_tag = self._make_base64_svg(sample_svg)
        html = f"<html><body>{img_tag}</body></html>"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert "width: 100%" in result
        assert "max-width: 800px" not in result


class TestProcessHtmlFileWithForeignObject:
    """Tests for handling SVGs with foreignObject (htmlLabels: true).

    With htmlLabels enabled, Mermaid generates foreignObject elements
    containing XHTML for formatted labels. These must survive the full
    HTML processing pipeline including base64 decoding and embedded SVG handling.
    """

    def _make_base64_svg(self, svg_content: str) -> str:
        encoded = base64.b64encode(svg_content.encode("utf-8")).decode("utf-8")
        return f'<img src="data:image/svg+xml;base64,{encoded}" alt="diagram"/>'

    def test_base64_foreign_object_preserved(
        self, sample_svg_with_foreign_object
    ) -> None:
        """foreignObject content must survive base64 decode + processing."""
        img_tag = self._make_base64_svg(sample_svg_with_foreign_object)
        html = f"<html><body>{img_tag}</body></html>"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert "<foreignObject" in result
        assert "Line 1<br/>Line 2" in result
        assert "<i>italic</i>" in result

    def test_embedded_foreign_object_preserved(
        self, sample_svg_with_foreign_object
    ) -> None:
        """foreignObject content must survive embedded SVG processing."""
        html = f"<html><body>{sample_svg_with_foreign_object}</body></html>"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert "<foreignObject" in result
        assert "Line 1<br/>Line 2" in result
        assert '<div class="svg-container">' in result


class TestProcessHtmlFileWithEmbeddedSvg:
    """Tests for Pandoc 3.x embedded SVG handling."""

    def test_wraps_embedded_svg_in_container(self) -> None:
        """Embedded SVGs should be wrapped in svg-container divs."""
        svg = '<svg viewBox="0 0 100 100" style="max-width: 100px;"><rect/></svg>'
        html = f"<html><body><h1>Title</h1>{svg}</body></html>"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert '<div class="svg-container">' in result
        assert "width: 100%" in result

    def test_multiple_embedded_svgs(self) -> None:
        """Multiple embedded SVGs should each be wrapped."""
        svg1 = '<svg viewBox="0 0 100 100"><rect/></svg>'
        svg2 = '<svg viewBox="0 0 200 200"><circle/></svg>'
        html = f"<html><body>{svg1}<p>text</p>{svg2}</body></html>"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert result.count('<div class="svg-container">') == 2


class TestProcessHtmlFileWithFileReferences:
    """Tests for SVG file reference handling."""

    def test_inlines_svg_file_references(self) -> None:
        """SVG file references should be replaced with inline SVG content."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create SVG file
            svg_content = (
                '<svg id="my-svg" viewBox="0 0 100 100" style="max-width: 100px;"><rect/></svg>'
            )
            svg_path = Path(tmpdir) / "processed-1.svg"
            svg_path.write_text(svg_content)

            # Create HTML with img reference
            html = '<html><body><img src="./processed-1.svg" alt="diagram"/></body></html>'
            html_path = Path(tmpdir) / "output.html"
            html_path.write_text(html)

            process_html_file(str(html_path))
            result = html_path.read_text()

        assert '<div class="svg-container">' in result
        assert '<img src="./processed-1.svg"' not in result
        assert "<svg" in result


class TestProcessHtmlFileCleaning:
    """Tests for HTML cleaning (figcaption, figure removal)."""

    def test_removes_figcaption(self) -> None:
        """Figcaption elements added by Pandoc should be removed."""
        html = (
            "<html><body>"
            "<figure>"
            '<svg viewBox="0 0 100 100"><rect/></svg>'
            "<figcaption>diagram</figcaption>"
            "</figure>"
            "</body></html>"
        )

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert "<figcaption" not in result
        assert "diagram</figcaption>" not in result

    def test_removes_figure_wrapper(self) -> None:
        """Figure wrapper tags should be removed (WeasyPrint SVG-in-figure issue)."""
        html = '<html><body><figure><svg viewBox="0 0 100 100"><rect/></svg></figure></body></html>'

        with tempfile.NamedTemporaryFile(mode="w", suffix=".html", delete=False) as f:
            f.write(html)
            f.flush()
            process_html_file(f.name)
            result = Path(f.name).read_text()

        assert "<figure>" not in result
        assert "</figure>" not in result
