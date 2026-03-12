#!/usr/bin/env python3
"""
Font Management Module for DataKnobs MD Tools

Provides cross-platform font discovery, listing, and validation.
Works in both native and Docker environments.
"""

import re
import subprocess
import sys


class FontManager:
    """Manages font discovery and validation using fontconfig (fc-list)"""

    # Common font categories for filtering
    CATEGORIES = {
        "serif": [
            "Times",
            "Georgia",
            "Palatino",
            "Garamond",
            "Cambria",
            "Liberation Serif",
            "Noto Serif",
            "DejaVu Serif",
        ],
        "sans-serif": [
            "Arial",
            "Helvetica",
            "Verdana",
            "Tahoma",
            "Segoe UI",
            "Liberation Sans",
            "Noto Sans",
            "DejaVu Sans",
            "Roboto",
            "Open Sans",
        ],
        "monospace": [
            "Courier",
            "Monaco",
            "Menlo",
            "Consolas",
            "Liberation Mono",
            "Noto Mono",
            "DejaVu Sans Mono",
            "Source Code Pro",
            "Fira Code",
            "SF Mono",
        ],
        "cursive": ["Comic Sans", "Brush Script", "Apple Chancery"],
        "fantasy": ["Impact", "Papyrus"],
    }

    def __init__(self) -> None:
        self._font_cache: set[str] | None = None
        self._detailed_cache: list[dict[str, str]] | None = None

    def _run_fc_list(self, args: list[str] | None = None) -> str:
        """Run fc-list command and return output"""
        cmd = ["fc-list"]
        if args:
            cmd.extend(args)

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error running fc-list: {e}", file=sys.stderr)
            return ""
        except FileNotFoundError:
            print("Error: fc-list not found. Please install fontconfig.", file=sys.stderr)
            return ""

    def get_all_fonts(self) -> set[str]:
        """Get set of all available font family names"""
        if self._font_cache is not None:
            return self._font_cache

        output = self._run_fc_list([":", "family"])
        fonts = set()

        for line in output.splitlines():
            # fc-list returns comma-separated family names
            families = [f.strip() for f in line.split(",")]
            fonts.update(families)

        # Filter out empty strings and sort
        self._font_cache = {f for f in fonts if f}
        return self._font_cache

    def get_fonts_detailed(self) -> list[dict[str, str]]:
        """Get detailed font information including family, style, and file path"""
        if self._detailed_cache is not None:
            return self._detailed_cache

        output = self._run_fc_list([":", "family", "style", "file"])
        fonts = []

        for line in output.splitlines():
            # Parse fc-list output: /path/to/font.ttf: Family Name:style=Style
            match = re.match(r"^([^:]+):\s*([^:]+):style=(.+)$", line)
            if match:
                file_path, family, style = match.groups()
                fonts.append(
                    {"family": family.strip(), "style": style.strip(), "file": file_path.strip()}
                )

        self._detailed_cache = sorted(fonts, key=lambda x: (x["family"].lower(), x["style"]))
        return self._detailed_cache

    def search_fonts(self, query: str, case_sensitive: bool = False) -> list[str]:
        """Search for fonts matching a query string"""
        fonts = self.get_all_fonts()

        if case_sensitive:
            return sorted([f for f in fonts if query in f])
        else:
            query_lower = query.lower()
            return sorted([f for f in fonts if query_lower in f.lower()])

    def is_font_available(self, font_name: str) -> bool:
        """Check if a specific font is available"""
        fonts = self.get_all_fonts()

        # Exact match (case-insensitive)
        for font in fonts:
            if font.lower() == font_name.lower():
                return True

        return False

    def find_similar_fonts(self, font_name: str, max_results: int = 5) -> list[str]:
        """Find fonts with similar names (for suggestions)"""
        # Simple similarity: contains same words or starts with same prefix
        fonts = self.get_all_fonts()
        query_lower = font_name.lower()

        # Try exact substring match first
        exact_matches = [f for f in fonts if query_lower in f.lower()]
        if exact_matches:
            return sorted(exact_matches)[:max_results]

        # Try word-based matching
        query_words = set(query_lower.split())
        matches = []

        for font in fonts:
            font_lower = font.lower()
            font_words = set(font_lower.split())

            # Check for common words
            common_words = query_words & font_words
            if common_words:
                matches.append((len(common_words), font))

        # Sort by number of matching words, then alphabetically
        matches.sort(key=lambda x: (-x[0], x[1].lower()))
        return [m[1] for m in matches[:max_results]]

    def get_fonts_by_category(self, category: str) -> list[str]:
        """Get fonts matching a specific category"""
        if category not in self.CATEGORIES:
            return []

        available_fonts = self.get_all_fonts()
        category_fonts = []

        for pattern in self.CATEGORIES[category]:
            matches = [f for f in available_fonts if pattern.lower() in f.lower()]
            category_fonts.extend(matches)

        return sorted(set(category_fonts))

    def validate_font(self, font_name: str, suggest: bool = True) -> tuple[bool, list[str] | None]:
        """
        Validate a font name and optionally return suggestions if not found

        Returns:
            (is_valid, suggestions)
        """
        if self.is_font_available(font_name):
            return (True, None)

        suggestions = None
        if suggest:
            suggestions = self.find_similar_fonts(font_name)

        return (False, suggestions)

    def list_fonts(
        self,
        category: str | None = None,
        search: str | None = None,
        detailed: bool = False,
        limit: int | None = None,
    ) -> list[dict[str, str]] | list[str]:
        """
        List fonts with optional filtering

        Args:
            category: Filter by category (serif, sans-serif, monospace, etc.)
            search: Search query string
            detailed: Return detailed info (family, style, file)
            limit: Maximum number of results

        Returns:
            List of font names or detailed font dicts
        """
        if detailed:
            fonts = self.get_fonts_detailed()

            # Apply filters
            if category:
                category_patterns = self.CATEGORIES.get(category, [])
                fonts = [
                    f
                    for f in fonts
                    if any(p.lower() in f["family"].lower() for p in category_patterns)
                ]

            if search:
                search_lower = search.lower()
                fonts = [f for f in fonts if search_lower in f["family"].lower()]

            if limit:
                fonts = fonts[:limit]

            return fonts
        else:
            if category:
                names = self.get_fonts_by_category(category)
            elif search:
                names = self.search_fonts(search)
            else:
                names = sorted(self.get_all_fonts())

            if limit:
                names = names[:limit]

            return list(names)


def main() -> None:
    """CLI interface for font management"""
    import argparse

    parser = argparse.ArgumentParser(
        description="DataKnobs Font Manager - List and validate system fonts"
    )

    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # List fonts
    list_parser = subparsers.add_parser("list", help="List available fonts")
    list_parser.add_argument(
        "--category",
        choices=["serif", "sans-serif", "monospace", "cursive", "fantasy"],
        help="Filter by font category",
    )
    list_parser.add_argument("--search", help="Search for fonts")
    list_parser.add_argument(
        "--detailed",
        action="store_true",
        help="Show detailed font info",
    )
    list_parser.add_argument("--limit", type=int, help="Limit number of results")

    # Search fonts
    search_parser = subparsers.add_parser("search", help="Search for fonts")
    search_parser.add_argument("query", help="Search query")
    search_parser.add_argument(
        "--detailed",
        action="store_true",
        help="Show detailed font info",
    )

    # Validate font
    validate_parser = subparsers.add_parser("validate", help="Check if a font is available")
    validate_parser.add_argument("font_name", help="Font name to validate")
    validate_parser.add_argument(
        "--no-suggest",
        action="store_true",
        help="Do not suggest alternatives",
    )

    # Categories
    subparsers.add_parser("categories", help="List available font categories")

    args = parser.parse_args()

    fm = FontManager()

    if args.command == "list":
        fonts = fm.list_fonts(
            category=args.category, search=args.search, detailed=args.detailed, limit=args.limit
        )

        if args.detailed:
            print(f"{'Family':<40} {'Style':<20} File")
            print("-" * 100)
            for entry in fonts:
                assert isinstance(entry, dict)
                print(f"{entry['family']:<40} {entry['style']:<20} {entry['file']}")
        else:
            for font in fonts:
                print(font)

        if fonts:
            print(f"\nTotal: {len(fonts)} fonts", file=sys.stderr)

    elif args.command == "search":
        fonts = fm.search_fonts(args.query)

        if fonts:
            for font in fonts:
                print(font)
            print(f"\nFound {len(fonts)} fonts matching '{args.query}'", file=sys.stderr)
        else:
            print(f"No fonts found matching '{args.query}'", file=sys.stderr)
            sys.exit(1)

    elif args.command == "validate":
        is_valid, suggestions = fm.validate_font(args.font_name, suggest=not args.no_suggest)

        if is_valid:
            print(f"✓ Font '{args.font_name}' is available", file=sys.stderr)
            sys.exit(0)
        else:
            print(f"✗ Font '{args.font_name}' not found", file=sys.stderr)

            if suggestions:
                print("\nDid you mean one of these?", file=sys.stderr)
                for suggestion in suggestions:
                    print(f"  - {suggestion}", file=sys.stderr)

            sys.exit(1)

    elif args.command == "categories":
        print("Available font categories:\n")
        for category, examples in FontManager.CATEGORIES.items():
            print(f"{category}:")
            print(f"  Examples: {', '.join(examples[:3])}")
            print()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
