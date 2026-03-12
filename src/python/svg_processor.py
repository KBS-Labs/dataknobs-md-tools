"""SVG processing utilities for Markdown to PDF conversion.

This module contains functions for cleaning and normalizing SVG content,
particularly for Mermaid diagrams that need to be embedded in PDFs.
"""

import base64
import re


def make_svg_ids_unique(svg_content: str, suffix: str) -> str:
    """Make all IDs in an SVG unique by adding a suffix.

    This is critical when embedding multiple SVG diagrams in a single HTML document,
    as duplicate IDs cause rendering failures in PDF generators like WeasyPrint.

    Args:
        svg_content: The SVG content as a string
        suffix: A unique suffix to append to IDs (e.g., diagram number)

    Returns:
        SVG content with uniquified IDs

    Example:
        >>> svg = '<svg id="my-svg"><rect id="my-svg_rect"/></svg>'
        >>> make_svg_ids_unique(svg, "1")
        '<svg id="my-svg-1"><rect id="my-svg-1_rect"/></svg>'
    """
    # Replace id attributes: id="my-svg" -> id="my-svg-1"
    svg_content = re.sub(r'id="my-svg', f'id="my-svg-{suffix}', svg_content)

    # Replace URL references: url(#my-svg...) -> url(#my-svg-1...)
    svg_content = re.sub(r"url\(#my-svg", f"url(#my-svg-{suffix}", svg_content)

    # Replace CSS selectors: #my-svg -> #my-svg-1
    # Use negative lookahead to avoid matching already-replaced IDs like #my-svg-1
    svg_content = re.sub(r"#my-svg(?!-\d)", f"#my-svg-{suffix}", svg_content)

    return svg_content


def normalize_svg_sizing(svg_content: str) -> str:
    """Normalize SVG sizing for PDF output - expand to full width, constrain tall diagrams.

    Mermaid generates SVGs with inline max-width styles based on diagram dimensions.
    This causes issues in PDFs where we want consistent sizing behavior:
    - All diagrams should expand to full page width for readable text
    - Tall diagrams should be constrained to fit within page height

    Args:
        svg_content: The SVG content as a string

    Returns:
        SVG content with normalized sizing styles
    """

    def replace_svg_style(match: re.Match[str]) -> str:
        full_tag = match.group(0)

        # Remove the max-width pixel value from the style
        # Change "max-width: 3467.26px;" to ""
        modified_tag = re.sub(r"max-width:\s*[\d.]+px;?", "", full_tag)

        # Add sizing styles for PDF:
        # - width: 100% makes diagrams expand to full page width (readable text)
        # - height: auto maintains aspect ratio
        # - max-height: 9in constrains tall diagrams to fit on page
        if 'style="' in modified_tag:
            # Append to existing style
            modified_tag = modified_tag.replace(
                'style="', 'style="width: 100%; height: auto; max-height: 9in; '
            )
        else:
            # Add new style attribute
            modified_tag = modified_tag.replace(
                ">", ' style="width: 100%; height: auto; max-height: 9in;">', 1
            )

        return modified_tag

    # Match the opening <svg> tag with all its attributes
    svg_content = re.sub(r"<svg[^>]*>", replace_svg_style, svg_content, count=1)

    return svg_content


def clean_svg_attributes(svg_content: str) -> str:
    """Remove problematic SVG attributes that cause issues in PDF rendering.

    Args:
        svg_content: The SVG content as a string

    Returns:
        SVG content with problematic attributes removed
    """
    # Remove XML declaration if present
    svg_content = re.sub(r"<\?xml[^?]*\?>\s*", "", svg_content)

    # Remove aria attributes that can cause issues
    svg_content = re.sub(r'\s*aria-roledescription="[^"]*"', "", svg_content)
    svg_content = re.sub(r'\s*role="graphics-document document"', "", svg_content)

    return svg_content


def decode_base64_svg(base64_data: str) -> str:
    """Decode a base64-encoded SVG string.

    Pandoc often converts SVG file references to base64 data URLs.
    This function decodes them back to SVG strings for processing.

    Args:
        base64_data: Base64-encoded SVG data

    Returns:
        Decoded SVG content as a string

    Raises:
        ValueError: If the base64 data is invalid
    """
    try:
        return base64.b64decode(base64_data).decode("utf-8")
    except Exception as e:
        raise ValueError(f"Failed to decode base64 SVG: {e}") from e


def process_svg_for_pdf(svg_content: str, diagram_number: int) -> str:
    """Process an SVG for embedding in a PDF document.

    This is the main entry point that applies all necessary transformations:
    1. Cleans problematic attributes
    2. Makes IDs unique to prevent conflicts
    3. Normalizes sizing for PDF output
    4. Wraps in a container div

    Args:
        svg_content: The SVG content as a string
        diagram_number: Unique identifier for this diagram (used for ID suffixes)

    Returns:
        Processed SVG wrapped in a container div, ready for PDF embedding
    """
    # Clean the SVG
    cleaned = clean_svg_attributes(svg_content)

    # Make IDs unique
    cleaned = make_svg_ids_unique(cleaned, str(diagram_number))

    # Normalize sizing
    cleaned = normalize_svg_sizing(cleaned)

    # Wrap in container div
    wrapped = f'<div class="svg-container">{cleaned}</div>'

    return wrapped
