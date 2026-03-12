"""Tests for mermaid processor with per-diagram fallback.

Tests are organized into:
- Pure function tests (extract_mermaid_blocks, reassemble_markdown) — no mocks needed
- subprocess-level tests (run_mmdc) — mock subprocess since mmdc is external
- Integration tests (process_mermaid) — mock subprocess for orchestration logic
"""

import subprocess
import tempfile
from pathlib import Path
from unittest.mock import patch

from python.mermaid_processor import (
    RenderResult,
    extract_mermaid_blocks,
    process_mermaid,
    reassemble_markdown,
    run_mmdc,
)

# ---------------------------------------------------------------------------
# Sample markdown content
# ---------------------------------------------------------------------------

SINGLE_DIAGRAM_MD = """# Title

Some text before.

```mermaid
graph TD
    A --> B
```

Some text after.
"""

MULTI_DIAGRAM_MD = """# Title

First paragraph.

```mermaid
graph TD
    A --> B
```

Middle paragraph.

```mermaid
sequenceDiagram
    Alice->>Bob: Hello
```

Another paragraph.

```mermaid
graph LR
    X --> Y --> Z
```

Final paragraph.
"""

NO_MERMAID_MD = """# Title

Just regular markdown with no diagrams.

```python
print("not mermaid")
```
"""


class TestExtractMermaidBlocks:
    """Tests for mermaid block extraction from markdown."""

    def test_single_block(self):
        blocks = extract_mermaid_blocks(SINGLE_DIAGRAM_MD)
        assert len(blocks) == 1
        assert blocks[0].index == 0
        assert "graph TD" in blocks[0].content
        assert "A --> B" in blocks[0].content

    def test_multiple_blocks(self):
        blocks = extract_mermaid_blocks(MULTI_DIAGRAM_MD)
        assert len(blocks) == 3
        assert blocks[0].index == 0
        assert blocks[1].index == 1
        assert blocks[2].index == 2
        assert "graph TD" in blocks[0].content
        assert "sequenceDiagram" in blocks[1].content
        assert "graph LR" in blocks[2].content

    def test_no_mermaid_blocks(self):
        blocks = extract_mermaid_blocks(NO_MERMAID_MD)
        assert len(blocks) == 0

    def test_empty_input(self):
        blocks = extract_mermaid_blocks("")
        assert len(blocks) == 0

    def test_non_mermaid_code_blocks_ignored(self):
        """Code blocks for other languages should not be extracted."""
        md = '```python\nprint("hi")\n```\n\n```mermaid\ngraph TD\n    A\n```\n'
        blocks = extract_mermaid_blocks(md)
        assert len(blocks) == 1
        assert "graph TD" in blocks[0].content

    def test_block_positions_allow_slicing(self):
        """start_pos and end_pos should correctly slice the original content."""
        blocks = extract_mermaid_blocks(SINGLE_DIAGRAM_MD)
        block = blocks[0]
        sliced = SINGLE_DIAGRAM_MD[block.start_pos : block.end_pos]
        assert sliced.startswith("```mermaid")
        assert sliced.rstrip().endswith("```")

    def test_multiple_block_positions_non_overlapping(self):
        blocks = extract_mermaid_blocks(MULTI_DIAGRAM_MD)
        for i in range(len(blocks) - 1):
            assert blocks[i].end_pos <= blocks[i + 1].start_pos

    def test_mermaid_with_extra_whitespace_in_fence(self):
        """Handle variations like '``` mermaid' with space."""
        md = "``` mermaid\ngraph TD\n    A\n```\n"
        blocks = extract_mermaid_blocks(md)
        assert len(blocks) == 1

    def test_content_excludes_fences(self):
        """Block content should not include the fence lines themselves."""
        blocks = extract_mermaid_blocks(SINGLE_DIAGRAM_MD)
        assert "```" not in blocks[0].content


class TestReassembleMarkdown:
    """Tests for reassembling markdown with render results."""

    def _make_blocks_and_results(self, content, successes):
        """Helper to create blocks and matching results."""
        blocks = extract_mermaid_blocks(content)
        results = []
        for i, (block, success) in enumerate(zip(blocks, successes, strict=True)):
            results.append(
                RenderResult(
                    index=block.index,
                    success=success,
                    svg_path=Path(f"processed-{i + 1}.svg") if success else None,
                    error=None if success else f"Error in diagram {i + 1}",
                )
            )
        return blocks, results

    def test_all_successful(self):
        blocks, results = self._make_blocks_and_results(
            MULTI_DIAGRAM_MD, [True, True, True]
        )
        output = reassemble_markdown(MULTI_DIAGRAM_MD, blocks, results)
        assert "![diagram](./processed-1.svg)" in output
        assert "![diagram](./processed-2.svg)" in output
        assert "![diagram](./processed-3.svg)" in output
        assert "```mermaid" not in output

    def test_all_failed(self):
        blocks, results = self._make_blocks_and_results(
            MULTI_DIAGRAM_MD, [False, False, False]
        )
        output = reassemble_markdown(MULTI_DIAGRAM_MD, blocks, results)
        assert "![diagram]" not in output
        assert "failed to render" in output
        assert "graph TD" in output  # Original code preserved in error block

    def test_mixed_success_failure(self):
        """First and third succeed, second fails."""
        blocks, results = self._make_blocks_and_results(
            MULTI_DIAGRAM_MD, [True, False, True]
        )
        output = reassemble_markdown(MULTI_DIAGRAM_MD, blocks, results)
        assert "![diagram](./processed-1.svg)" in output
        assert "![diagram](./processed-3.svg)" in output
        assert "Mermaid diagram 2 failed to render" in output
        assert "sequenceDiagram" in output  # Failed diagram code preserved

    def test_surrounding_text_preserved(self):
        blocks, results = self._make_blocks_and_results(
            MULTI_DIAGRAM_MD, [True, True, True]
        )
        output = reassemble_markdown(MULTI_DIAGRAM_MD, blocks, results)
        assert "# Title" in output
        assert "First paragraph." in output
        assert "Middle paragraph." in output
        assert "Another paragraph." in output
        assert "Final paragraph." in output

    def test_single_block_success(self):
        blocks, results = self._make_blocks_and_results(
            SINGLE_DIAGRAM_MD, [True]
        )
        output = reassemble_markdown(SINGLE_DIAGRAM_MD, blocks, results)
        assert "![diagram](./processed-1.svg)" in output
        assert "Some text before." in output
        assert "Some text after." in output

    def test_error_message_included(self):
        blocks = extract_mermaid_blocks(SINGLE_DIAGRAM_MD)
        results = [
            RenderResult(
                index=0,
                success=False,
                error="Parse error on line 2: unexpected token",
            )
        ]
        output = reassemble_markdown(SINGLE_DIAGRAM_MD, blocks, results)
        assert "Parse error on line 2: unexpected token" in output


class TestRunMmdc:
    """Tests for the mmdc subprocess wrapper.

    Mocks subprocess.run since mmdc is an external binary that launches
    Chromium — no DataKnobs test construct exists for this.
    """

    @patch("python.mermaid_processor.subprocess.run")
    def test_success(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="", stderr=""
        )
        success, stderr = run_mmdc(Path("input.md"), Path("output.md"))
        assert success is True
        assert stderr == ""

    @patch("python.mermaid_processor.subprocess.run")
    def test_failure(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=[], returncode=1, stdout="", stderr="Parse error on line 3"
        )
        success, stderr = run_mmdc(Path("input.md"), Path("output.md"))
        assert success is False
        assert "Parse error" in stderr

    @patch("python.mermaid_processor.subprocess.run")
    def test_mmdc_not_found(self, mock_run):
        mock_run.side_effect = FileNotFoundError()
        success, stderr = run_mmdc(Path("input.md"), Path("output.md"))
        assert success is False
        assert "mmdc not found" in stderr

    @patch("python.mermaid_processor.subprocess.run")
    def test_passes_config_args(self, mock_run):
        mock_run.return_value = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="", stderr=""
        )
        run_mmdc(
            Path("input.md"),
            Path("output.md"),
            mermaid_config="/path/to/mermaid.json",
            puppeteer_config="/path/to/puppeteer.json",
        )
        call_args = mock_run.call_args[0][0]
        assert "-c" in call_args
        assert "/path/to/mermaid.json" in call_args
        assert "-p" in call_args
        assert "/path/to/puppeteer.json" in call_args


class TestProcessMermaid:
    """Integration tests for the full process_mermaid orchestrator.

    Mocks subprocess.run to test the orchestration logic without mmdc.
    """

    def _write_input(self, tmpdir, content):
        """Write markdown content to a temp input file."""
        input_path = Path(tmpdir) / "input.md"
        input_path.write_text(content, encoding="utf-8")
        return str(input_path)

    @patch("python.mermaid_processor.subprocess.run")
    def test_fast_path_success(self, mock_run):
        """When full-doc mmdc succeeds, use its output directly."""
        with tempfile.TemporaryDirectory() as tmpdir:
            input_path = self._write_input(tmpdir, SINGLE_DIAGRAM_MD)
            output_dir = Path(tmpdir) / "out"
            output_dir.mkdir()

            # Mock mmdc success: it writes processed.md and SVG
            def mock_mmdc(cmd, **kwargs):
                # Simulate mmdc writing output files
                out_path = Path(cmd[cmd.index("-o") + 1])
                out_path.write_text(
                    "![diagram](./processed-1.svg)", encoding="utf-8"
                )
                svg_path = out_path.parent / "processed-1.svg"
                svg_path.write_text("<svg>ok</svg>", encoding="utf-8")
                return subprocess.CompletedProcess(
                    args=cmd, returncode=0, stdout="", stderr=""
                )

            mock_run.side_effect = mock_mmdc

            result = process_mermaid(input_path, str(output_dir))

            assert result is True
            assert (output_dir / "processed.md").exists()
            # Full-doc mmdc was called exactly once (no per-diagram fallback)
            assert mock_run.call_count == 1

    @patch("python.mermaid_processor.subprocess.run")
    def test_fallback_on_failure(self, mock_run):
        """When full-doc fails, fall back to per-diagram rendering."""
        with tempfile.TemporaryDirectory() as tmpdir:
            input_path = self._write_input(tmpdir, MULTI_DIAGRAM_MD)
            output_dir = Path(tmpdir) / "out"
            output_dir.mkdir()

            call_count = [0]

            def mock_mmdc(cmd, **kwargs):
                call_count[0] += 1
                out_path = Path(cmd[cmd.index("-o") + 1])

                if call_count[0] == 1:
                    # First call (full doc) fails
                    return subprocess.CompletedProcess(
                        args=cmd, returncode=1, stdout="",
                        stderr="Error in diagram 2"
                    )
                else:
                    # Per-diagram calls succeed
                    out_path.write_text("processed", encoding="utf-8")
                    svg_path = out_path.parent / (
                        out_path.stem + "-1.svg"
                    )
                    svg_path.write_text("<svg>ok</svg>", encoding="utf-8")
                    return subprocess.CompletedProcess(
                        args=cmd, returncode=0, stdout="", stderr=""
                    )

            mock_run.side_effect = mock_mmdc

            result = process_mermaid(input_path, str(output_dir))

            assert result is True
            processed_md = (output_dir / "processed.md").read_text()
            assert "![diagram](./processed-1.svg)" in processed_md
            assert "![diagram](./processed-2.svg)" in processed_md
            assert "![diagram](./processed-3.svg)" in processed_md
            # 1 full-doc + 3 per-diagram = 4 calls
            assert mock_run.call_count == 4

    @patch("python.mermaid_processor.subprocess.run")
    def test_partial_failure(self, mock_run):
        """When some per-diagram renders fail, annotate failures."""
        with tempfile.TemporaryDirectory() as tmpdir:
            input_path = self._write_input(tmpdir, MULTI_DIAGRAM_MD)
            output_dir = Path(tmpdir) / "out"
            output_dir.mkdir()

            call_count = [0]

            def mock_mmdc(cmd, **kwargs):
                call_count[0] += 1
                out_path = Path(cmd[cmd.index("-o") + 1])

                if call_count[0] == 1:
                    # Full doc fails
                    return subprocess.CompletedProcess(
                        args=cmd, returncode=1, stdout="", stderr="error"
                    )
                elif call_count[0] == 3:
                    # Second diagram fails
                    return subprocess.CompletedProcess(
                        args=cmd, returncode=1, stdout="",
                        stderr="Bad syntax in sequenceDiagram"
                    )
                else:
                    # Diagrams 1 and 3 succeed
                    out_path.write_text("processed", encoding="utf-8")
                    svg_path = out_path.parent / (
                        out_path.stem + "-1.svg"
                    )
                    svg_path.write_text("<svg>ok</svg>", encoding="utf-8")
                    return subprocess.CompletedProcess(
                        args=cmd, returncode=0, stdout="", stderr=""
                    )

            mock_run.side_effect = mock_mmdc

            result = process_mermaid(input_path, str(output_dir))

            assert result is False  # Not all succeeded
            processed_md = (output_dir / "processed.md").read_text()
            assert "![diagram](./processed-1.svg)" in processed_md
            assert "![diagram](./processed-3.svg)" in processed_md
            assert "Mermaid diagram 2 failed to render" in processed_md
            assert "sequenceDiagram" in processed_md  # Original code preserved
            # Surrounding text preserved
            assert "First paragraph." in processed_md
            assert "Final paragraph." in processed_md

    def test_no_mermaid_blocks(self):
        """Input with no mermaid blocks should just copy content."""
        with tempfile.TemporaryDirectory() as tmpdir:
            input_path = self._write_input(tmpdir, NO_MERMAID_MD)
            output_dir = Path(tmpdir) / "out"
            output_dir.mkdir()

            result = process_mermaid(input_path, str(output_dir))

            assert result is True
            processed = (output_dir / "processed.md").read_text()
            assert processed == NO_MERMAID_MD
