"""Tests for SVG processing functions.

These tests focus on the regex-heavy functions that are prone to bugs,
particularly around ID uniquification and sizing normalization.
"""

import pytest
from python.svg_processor import (
    make_svg_ids_unique,
    normalize_svg_sizing,
    clean_svg_attributes,
    decode_base64_svg,
    process_svg_for_pdf,
)


class TestMakeSvgIdsUnique:
    """Tests for the make_svg_ids_unique function.
    
    This function had multiple bugs during development:
    1. Initially didn't handle all ID reference types
    2. Double-suffix bug where IDs got suffixed multiple times
    """
    
    def test_basic_id_replacement(self):
        """Test that basic id attributes are replaced."""
        svg = '<svg id="my-svg"><rect id="my-svg_rect"/></svg>'
        result = make_svg_ids_unique(svg, "1")
        assert 'id="my-svg-1"' in result
        assert 'id="my-svg-1_rect"' in result
        assert 'id="my-svg"' not in result  # Original should be gone
    
    def test_url_references(self):
        """Test that url(#id) references are replaced."""
        svg = '<svg id="my-svg"><path style="marker-end: url(#my-svg_arrow);"/></svg>'
        result = make_svg_ids_unique(svg, "2")
        assert 'url(#my-svg-2_arrow)' in result
        assert 'url(#my-svg_arrow)' not in result
    
    def test_css_selectors(self):
        """Test that CSS selectors like #my-svg are replaced."""
        svg = '<svg id="my-svg"><style>#my-svg { fill: red; }</style></svg>'
        result = make_svg_ids_unique(svg, "3")
        assert '#my-svg-3 { fill: red; }' in result
        assert '#my-svg {' not in result
    
    def test_no_double_suffix(self):
        r"""Test that already-replaced IDs don't get double suffixes.

        This was a critical bug: regex #my-svg would match #my-svg-1,
        creating #my-svg-1-1. The negative lookahead (?!-\d) prevents this.
        """
        svg = '<svg id="my-svg"><style>#my-svg { fill: red; } #my-svg-1 { fill: blue; }</style></svg>'
        result = make_svg_ids_unique(svg, "3")
        # The original #my-svg should become #my-svg-3
        assert '#my-svg-3 { fill: red; }' in result
        # The pre-existing #my-svg-1 should remain unchanged (not become #my-svg-1-3)
        assert '#my-svg-1 { fill: blue; }' in result
        # Should NOT have double suffixes
        assert '#my-svg-1-3' not in result
    
    def test_multiple_id_types_together(self):
        """Test that all ID reference types work together."""
        svg = '''<svg id="my-svg">
            <defs><marker id="my-svg_arrow"/></defs>
            <path style="marker-end: url(#my-svg_arrow);"/>
            <style>#my-svg_arrow { fill: black; }</style>
        </svg>'''
        result = make_svg_ids_unique(svg, "5")
        assert 'id="my-svg-5"' in result
        assert 'id="my-svg-5_arrow"' in result
        assert 'url(#my-svg-5_arrow)' in result
        assert '#my-svg-5_arrow { fill: black; }' in result


class TestNormalizeSvgSizing:
    """Tests for the normalize_svg_sizing function.
    
    This function ensures SVGs expand to full width while constraining height.
    """
    
    def test_removes_large_max_width(self):
        """Test that large pixel max-width values are removed."""
        svg = '<svg viewBox="0 0 3467 996" style="max-width: 3467.26px; background-color: white;"></svg>'
        result = normalize_svg_sizing(svg)
        assert 'max-width: 3467.26px' not in result
        assert 'background-color: white' in result  # Other styles preserved
    
    def test_adds_responsive_sizing(self):
        """Test that responsive sizing styles are added."""
        svg = '<svg viewBox="0 0 1000 500" style="background-color: white;"></svg>'
        result = normalize_svg_sizing(svg)
        assert 'width: 100%' in result
        assert 'height: auto' in result
        assert 'max-height: 9in' in result
    
    def test_handles_svg_without_style(self):
        """Test that SVG without style attribute gets one added."""
        svg = '<svg viewBox="0 0 1000 500"></svg>'
        result = normalize_svg_sizing(svg)
        assert 'style="width: 100%; height: auto; max-height: 9in;"' in result
    
    def test_preserves_other_attributes(self):
        """Test that other SVG attributes are preserved."""
        svg = '<svg viewBox="0 0 1000 500" class="flowchart" id="my-svg" style="max-width: 1000px;"></svg>'
        result = normalize_svg_sizing(svg)
        assert 'viewBox="0 0 1000 500"' in result
        assert 'class="flowchart"' in result
        assert 'id="my-svg"' in result


class TestCleanSvgAttributes:
    """Tests for the clean_svg_attributes function."""
    
    def test_removes_xml_declaration(self):
        """Test that XML declarations are removed."""
        svg = '<?xml version="1.0" encoding="UTF-8"?>\n<svg></svg>'
        result = clean_svg_attributes(svg)
        assert '<?xml' not in result
        assert '<svg></svg>' in result
    
    def test_removes_aria_attributes(self):
        """Test that problematic aria attributes are removed."""
        svg = '<svg aria-roledescription="flowchart-v2" role="graphics-document document"></svg>'
        result = clean_svg_attributes(svg)
        assert 'aria-roledescription' not in result
        assert 'role="graphics-document document"' not in result


class TestDecodeBase64Svg:
    """Tests for the decode_base64_svg function."""
    
    def test_decodes_valid_base64(self):
        """Test that valid base64 SVG data is decoded."""
        svg_content = '<svg><rect/></svg>'
        import base64
        encoded = base64.b64encode(svg_content.encode('utf-8')).decode('utf-8')
        result = decode_base64_svg(encoded)
        assert result == svg_content
    
    def test_raises_on_invalid_base64(self):
        """Test that invalid base64 data raises ValueError."""
        with pytest.raises(ValueError, match="Failed to decode base64 SVG"):
            decode_base64_svg("not-valid-base64!!!")


class TestProcessSvgForPdf:
    """Tests for the main process_svg_for_pdf function."""
    
    def test_complete_processing_pipeline(self):
        """Test that all processing steps are applied."""
        svg = '''<?xml version="1.0"?>
<svg id="my-svg" viewBox="0 0 3467 996" 
     style="max-width: 3467.26px; background-color: white;"
     aria-roledescription="flowchart-v2">
    <style>#my-svg { fill: red; }</style>
</svg>'''
        result = process_svg_for_pdf(svg, 7)
        
        # Check wrapping
        assert result.startswith('<div class="svg-container">')
        assert result.endswith('</div>')
        
        # Check cleaning
        assert '<?xml' not in result
        assert 'aria-roledescription' not in result
        
        # Check ID uniquification
        assert 'id="my-svg-7"' in result
        assert '#my-svg-7 { fill: red; }' in result
        
        # Check sizing
        assert 'width: 100%' in result
        assert 'max-height: 9in' in result
        assert 'max-width: 3467.26px' not in result
