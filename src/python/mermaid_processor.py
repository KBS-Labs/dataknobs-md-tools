"""Mermaid diagram processor with per-diagram fallback.

Processes Mermaid diagrams in markdown files with graceful degradation:
when full-document rendering fails, falls back to per-diagram rendering
so that one bad diagram doesn't prevent the others from rendering.
"""

import dataclasses
import logging
import re
import subprocess
import sys
import tempfile
from pathlib import Path

logger = logging.getLogger(__name__)

# Pattern for the opening of a mermaid fenced code block
MERMAID_OPEN_RE = re.compile(r"^\s*```\s*mermaid\b")
# Pattern for a closing fence
FENCE_CLOSE_RE = re.compile(r"^\s*```\s*$")


@dataclasses.dataclass
class MermaidBlock:
    """A single mermaid code block extracted from markdown."""

    index: int  # 0-based position among all mermaid blocks
    content: str  # The mermaid code (without fences)
    start_pos: int  # Character offset of opening fence
    end_pos: int  # Character offset just past closing fence


@dataclasses.dataclass
class RenderResult:
    """Result of rendering a single mermaid block."""

    index: int
    success: bool
    svg_path: Path | None = None
    error: str | None = None


def extract_mermaid_blocks(content: str) -> list[MermaidBlock]:
    """Extract mermaid code blocks from markdown.

    Parses line-by-line looking for ```mermaid ... ``` fences.

    Args:
        content: Full markdown content

    Returns:
        List of MermaidBlock with positions and content
    """
    blocks: list[MermaidBlock] = []
    lines = content.split("\n")
    in_mermaid = False
    block_start_pos = 0
    block_lines: list[str] = []
    char_pos = 0

    for line in lines:
        line_start = char_pos
        # +1 for the newline character
        char_pos += len(line) + 1

        if not in_mermaid:
            if MERMAID_OPEN_RE.match(line):
                in_mermaid = True
                block_start_pos = line_start
                block_lines = []
        else:
            if FENCE_CLOSE_RE.match(line):
                blocks.append(
                    MermaidBlock(
                        index=len(blocks),
                        content="\n".join(block_lines),
                        start_pos=block_start_pos,
                        end_pos=char_pos,
                    )
                )
                in_mermaid = False
                block_lines = []
            else:
                block_lines.append(line)

    return blocks


def run_mmdc(
    input_path: Path,
    output_path: Path,
    mermaid_config: str | None = None,
    puppeteer_config: str | None = None,
) -> tuple[bool, str]:
    """Run mmdc on a markdown file.

    Args:
        input_path: Path to input markdown file
        output_path: Path for output markdown file
        mermaid_config: Optional path to mermaid-config.json
        puppeteer_config: Optional path to puppeteer-config.json

    Returns:
        Tuple of (success, stderr_output)
    """
    cmd = ["mmdc", "-i", str(input_path), "-o", str(output_path)]
    if mermaid_config:
        cmd.extend(["-c", mermaid_config])
    if puppeteer_config:
        cmd.extend(["-p", puppeteer_config])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return result.returncode == 0, result.stderr
    except FileNotFoundError:
        return False, "mmdc not found. Please install @mermaid-js/mermaid-cli."


def _render_per_diagram(
    blocks: list[MermaidBlock],
    output_dir: Path,
    mermaid_config: str | None,
    puppeteer_config: str | None,
) -> list[RenderResult]:
    """Render each mermaid block independently.

    Args:
        blocks: Extracted mermaid blocks
        output_dir: Directory for output SVGs
        mermaid_config: Optional path to mermaid-config.json
        puppeteer_config: Optional path to puppeteer-config.json

    Returns:
        List of RenderResult, one per block
    """
    results: list[RenderResult] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)

        for block in blocks:
            diagram_num = block.index + 1

            # Create a temp markdown with just this one diagram
            single_md = tmp / f"diagram-{diagram_num}.md"
            single_out = tmp / f"diagram-{diagram_num}-out.md"
            single_md.write_text(
                f"```mermaid\n{block.content}\n```\n", encoding="utf-8"
            )

            success, stderr = run_mmdc(
                single_md, single_out, mermaid_config, puppeteer_config
            )

            if success:
                # mmdc names the SVG based on the output file: diagram-N-out-1.svg
                svg_candidates = sorted(
                    tmp.glob(f"diagram-{diagram_num}-out-*.svg")
                )
                if svg_candidates:
                    dest_svg = output_dir / f"processed-{diagram_num}.svg"
                    dest_svg.write_text(
                        svg_candidates[0].read_text(encoding="utf-8"),
                        encoding="utf-8",
                    )
                    results.append(
                        RenderResult(
                            index=block.index,
                            success=True,
                            svg_path=dest_svg,
                        )
                    )
                    logger.info("Diagram %d rendered successfully", diagram_num)
                else:
                    results.append(
                        RenderResult(
                            index=block.index,
                            success=False,
                            error="mmdc succeeded but no SVG was produced",
                        )
                    )
                    logger.warning(
                        "Diagram %d: mmdc succeeded but no SVG produced",
                        diagram_num,
                    )
            else:
                error_msg = stderr.strip() if stderr else "Unknown error"
                results.append(
                    RenderResult(
                        index=block.index,
                        success=False,
                        error=error_msg,
                    )
                )
                logger.warning(
                    "Diagram %d failed: %s", diagram_num, error_msg
                )

    return results


def reassemble_markdown(
    original_content: str,
    blocks: list[MermaidBlock],
    results: list[RenderResult],
) -> str:
    """Replace mermaid blocks with SVG references or error annotations.

    Processes blocks in reverse order so character positions remain valid.

    Args:
        original_content: Original markdown content
        blocks: Extracted mermaid blocks (with positions)
        results: Render results (parallel to blocks)

    Returns:
        Modified markdown content
    """
    output = original_content

    # Process in reverse order to keep positions valid
    for block, result in reversed(list(zip(blocks, results, strict=True))):
        diagram_num = block.index + 1

        if result.success:
            replacement = f"![diagram](./processed-{diagram_num}.svg)"
        else:
            # Indent the original code for a blockquote code block
            indented_code = "\n".join(
                f"> {line}" for line in block.content.split("\n")
            )
            error_msg = result.error or "Unknown error"
            replacement = (
                f"> **Mermaid diagram {diagram_num} failed to render:** "
                f"{error_msg}\n>\n> ```\n{indented_code}\n> ```"
            )

        output = output[: block.start_pos] + replacement + output[block.end_pos :]

    return output


def process_mermaid(
    input_path: str,
    output_dir: str,
    mermaid_config: str | None = None,
    puppeteer_config: str | None = None,
    verbose: bool = False,
) -> bool:
    """Process mermaid diagrams with per-diagram fallback.

    Strategy:
    1. Try full-document mmdc (fast path - single Chromium instance)
    2. On failure, render each diagram independently
    3. Successful diagrams get SVGs, failed ones get error annotations

    Args:
        input_path: Path to input markdown file
        output_dir: Directory for output files (processed.md + SVGs)
        mermaid_config: Optional path to mermaid-config.json
        puppeteer_config: Optional path to puppeteer-config.json
        verbose: Enable verbose output

    Returns:
        True if all diagrams rendered, False if any failed
    """
    if verbose:
        logging.basicConfig(level=logging.INFO, stream=sys.stderr)

    input_file = Path(input_path)
    out_dir = Path(output_dir)
    output_md = out_dir / "processed.md"

    markdown = input_file.read_text(encoding="utf-8")
    blocks = extract_mermaid_blocks(markdown)

    if not blocks:
        # No mermaid blocks — just copy input
        output_md.write_text(markdown, encoding="utf-8")
        return True

    # Fast path: try full document
    success, stderr = run_mmdc(
        input_file, output_md, mermaid_config, puppeteer_config
    )

    if success:
        if verbose:
            logger.info("Full-document mermaid processing succeeded")
        return True

    # Full-doc failed — fall back to per-diagram processing
    logger.warning(
        "Full-document mermaid processing failed, trying per-diagram fallback"
    )
    if stderr:
        logger.warning("mmdc error: %s", stderr.strip())

    results = _render_per_diagram(
        blocks, out_dir, mermaid_config, puppeteer_config
    )

    # Reassemble markdown with results
    processed = reassemble_markdown(markdown, blocks, results)
    output_md.write_text(processed, encoding="utf-8")

    succeeded = sum(1 for r in results if r.success)
    failed = sum(1 for r in results if not r.success)

    if failed > 0:
        logger.warning(
            "%d of %d diagrams failed to render", failed, len(results)
        )
    if succeeded > 0:
        logger.info(
            "%d of %d diagrams rendered successfully", succeeded, len(results)
        )

    return failed == 0


def main() -> None:
    """CLI entry point for mermaid processing."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Process Mermaid diagrams with per-diagram fallback"
    )
    parser.add_argument("input_path", help="Path to input markdown file")
    parser.add_argument(
        "output_dir", help="Directory for output files"
    )
    parser.add_argument(
        "--mermaid-config", help="Path to mermaid-config.json"
    )
    parser.add_argument(
        "--puppeteer-config", help="Path to puppeteer-config.json"
    )
    parser.add_argument(
        "--verbose", action="store_true", help="Enable verbose output"
    )

    args = parser.parse_args()

    # Configure logging for CLI usage
    logging.basicConfig(
        level=logging.INFO if args.verbose else logging.WARNING,
        format="%(levelname)s: %(message)s",
        stream=sys.stderr,
    )

    success = process_mermaid(
        input_path=args.input_path,
        output_dir=args.output_dir,
        mermaid_config=args.mermaid_config,
        puppeteer_config=args.puppeteer_config,
        verbose=args.verbose,
    )

    if not success:
        # Exit with 0 — partial rendering is still useful.
        # The warning messages indicate which diagrams failed.
        print(
            "Some diagrams failed to render (see warnings above)",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
