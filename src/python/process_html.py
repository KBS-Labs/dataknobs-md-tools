"""CLI script to process HTML files for PDF generation.

This script inlines SVG diagrams into HTML files and cleans them for WeasyPrint.
It uses the svg_processor module for all SVG transformations.
"""

import re
import sys
from pathlib import Path

from python.svg_processor import (
    clean_svg_attributes,
    decode_base64_svg,
    make_svg_ids_unique,
    normalize_svg_sizing,
)


def process_html_file(html_path: str) -> None:
    """Process an HTML file to inline and clean SVG diagrams.

    Args:
        html_path: Path to the HTML file to process (modified in place)
    """
    html_file = Path(html_path)
    if not html_file.exists():
        print(f"Error: File not found: {html_path}", file=sys.stderr)
        sys.exit(1)

    # Read the HTML file
    with open(html_file, encoding="utf-8") as f:
        html_content = f.read()

    # Find all SVG files in the same directory
    svg_files = sorted(html_file.parent.glob("processed-*.svg"))

    # Check if HTML has embedded SVG tags, file references, or base64 encoding
    # Different Pandoc versions handle resources differently:
    # - Pandoc 2.x with --self-contained: base64-encodes SVGs in img tags
    # - Pandoc 3.x with --embed-resources: directly embeds SVGs as <svg> tags
    uses_base64 = bool(re.search(r'<img\s+[^>]*?src="data:image/svg\+xml;base64,', html_content))
    has_embedded_svgs = bool(re.search(r"<svg[^>]*>", html_content))

    if uses_base64:
        # Pandoc 2.x with --self-contained: decode base64-encoded SVGs
        svg_counter = [0]  # Use list to allow modification in nested function

        def replace_base64_svg(match: re.Match[str]) -> str:
            full_tag = match.group(0)
            base64_data = match.group(1)
            svg_counter[0] += 1
            try:
                # Decode base64 and process SVG using our module
                decoded_svg = decode_base64_svg(base64_data)
                cleaned_svg = clean_svg_attributes(decoded_svg)
                cleaned_svg = make_svg_ids_unique(cleaned_svg, str(svg_counter[0]))
                cleaned_svg = normalize_svg_sizing(cleaned_svg)

                # Wrap in div container
                svg_wrapped = f'<div class="svg-container">{cleaned_svg}</div>'
                return svg_wrapped
            except Exception as e:
                # If decoding or processing fails, return original tag
                print(f"Warning: Failed to process base64 SVG: {e}", file=sys.stderr)
                return full_tag

        # Replace all base64-encoded SVG images
        # Pattern matches <img> tags with any attributes before src attribute
        html_content = re.sub(
            r'<img\s+[^>]*?src="data:image/svg\+xml;base64,([^"]+)"[^>]*/?>',
            replace_base64_svg,
            html_content,
        )
    elif has_embedded_svgs:
        # Pandoc 3.x with --embed-resources: process embedded <svg> tags
        svg_counter = [0]

        def process_embedded_svg(match: re.Match[str]) -> str:
            svg_counter[0] += 1
            svg_tag = match.group(0)

            # Apply our sizing normalization
            processed_svg = normalize_svg_sizing(svg_tag)

            # Wrap in container div
            return f'<div class="svg-container">{processed_svg}</div>'

        # Process all <svg> tags
        html_content = re.sub(
            r"<svg[^>]*>.*?</svg>", process_embedded_svg, html_content, flags=re.DOTALL
        )
    else:
        # Replace each SVG img file reference with inline SVG content
        for svg_file in svg_files:
            svg_filename = svg_file.name
            # Extract diagram number from filename (e.g., "processed-1.svg" -> "1")
            diagram_num_match = re.search(r"processed-(\d+)\.svg", svg_filename)
            diagram_num = diagram_num_match.group(1) if diagram_num_match else svg_filename

            # Read and process the SVG content using our module
            with open(svg_file, encoding="utf-8") as f:
                svg_content = f.read()

            # Process SVG using our module functions
            svg_content = clean_svg_attributes(svg_content)
            svg_content = make_svg_ids_unique(svg_content, str(diagram_num))
            svg_content = normalize_svg_sizing(svg_content)

            # Wrap SVG in a container div
            svg_wrapped = f'<div class="svg-container">{svg_content}</div>'

            # Find and replace img tags that reference this SVG file
            img_pattern = r'<img\s+src="\./' + re.escape(svg_filename) + r'"[^>]*/?>'
            html_content = re.sub(img_pattern, svg_wrapped, html_content)

    # Remove figcaption elements that Pandoc adds for images
    # These show up as "diagram" text in the output
    html_content = re.sub(r"<figcaption[^>]*>.*?</figcaption>", "", html_content, flags=re.DOTALL)

    # Remove figure wrapper tags - WeasyPrint doesn't render SVGs inside figure properly
    html_content = re.sub(r"<figure>\s*", "", html_content)
    html_content = re.sub(r"\s*</figure>", "", html_content)

    # Write the modified HTML back
    with open(html_file, "w", encoding="utf-8") as f:
        f.write(html_content)

    print("SVG inlining complete", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python -m python.process_html <html_file>", file=sys.stderr)
        sys.exit(1)

    process_html_file(sys.argv[1])
