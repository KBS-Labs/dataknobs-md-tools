# Test Fixtures

Markdown files in this directory are used for regression testing. Each file
exercises specific Mermaid diagram features or edge cases.

## Files

| File | What it tests |
|------|---------------|
| `basic-flowchart.md` | Simple flowchart, no special features — baseline |
| `html-labels-flowchart.md` | `<br/>`, `<i>`, `<b>`, `style` directives |
| `xychart.md` | `xychart-beta` diagram type |
| `multi-diagram.md` | Multiple diagrams in one document (SVG ID uniquification) |

## Adding New Fixtures

When a new diagram feature or edge case is discovered:

1. Create a `.md` file that exercises the specific behavior
2. Name it descriptively (e.g., `nested-subgraphs.md`, `gantt-chart.md`)
3. Add a comment at the top explaining what it tests
4. Update this table
