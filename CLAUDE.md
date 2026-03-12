# DataKnobs Markdown Tools

Markdown-to-PDF/HTML converter with Mermaid diagram support. Hybrid project:
shell scripts orchestrate external tools (pandoc, mermaid-cli, WeasyPrint),
Python modules handle SVG post-processing.

## Development Commands

```bash
make check      # Run all checks (lint + typecheck + test)
make test       # Run Python unit tests
make lint       # Run ruff linter
make typecheck  # Run mypy type checker
make fix        # Auto-fix lint issues and format code
make sync       # Install/sync dependencies (including dev)
```

Always use `uv run` to execute Python commands (e.g., `uv run pytest`, `uv run python`).

## Project Structure

- `src/python/` — Python modules (SVG processing, HTML post-processing, font management)
- `src/config/` — Mermaid and Puppeteer configuration files
- `src/templates/` — HTML templates and CSS themes
- `native/dk-md2pdf` — Main conversion pipeline (bash script)
- `bin/` — User-facing wrapper scripts
- `docker/` — Docker build files
- `tests/` — Python unit tests and shell test scripts
- `tests/fixtures/` — Markdown test files for regression testing
- `examples/` — Sample documents for demo purposes

## Conversion Pipeline

```
input.md → [mmdc] → processed.md + SVGs → [pandoc] → output.html
→ [process_html.py] → cleaned HTML with inlined SVGs → [WeasyPrint] → output.pdf
```

## Key Conventions

- Python code lives in `src/python/`, imported as `python.<module>` (e.g., `from python.svg_processor import ...`)
- Test fixtures (markdown files for regression testing) go in `tests/fixtures/`
- Example documents (for demo/documentation) go in `examples/`
- Configuration files go in `src/config/`
- Shell tests (`test_*.sh`) are orchestrated by `tests/run_tests.sh`
- Python tests (`test_*.py`) are run by pytest

## Testing

- Run `make check` before submitting changes
- Add regression test fixtures to `tests/fixtures/` for any new diagram behavior
- Python tests cover SVG processing and HTML post-processing
- Shell tests cover installation, Docker path handling, and wrapper scripts
