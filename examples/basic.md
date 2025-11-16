# Basic Markdown Example

This is a basic markdown file demonstrating common formatting features.

## Text Formatting

You can make text **bold** or *italic* or ***both***. You can also use ~~strikethrough~~.

## Lists

### Unordered List
- First item
- Second item
  - Nested item
  - Another nested item
- Third item

### Ordered List
1. First step
2. Second step
   1. Sub-step A
   2. Sub-step B
3. Third step

### Task List (Checkboxes)
- [ ] Uncompleted task
- [x] Completed task
- [ ] Another uncompleted task
  - [x] Completed subtask
  - [ ] Uncompleted subtask
- [x] Task with **bold** and *italic* text

## Links and Images

Here's a [link to GitHub](https://github.com).

## Code

Inline code: `console.log('Hello, World!')`

Code block:
```javascript
function greet(name) {
    console.log(`Hello, ${name}!`);
}

greet('DataKnobs');
```

## Tables

| Feature | Supported | Notes |
|---------|-----------|-------|
| Markdown | ✓ | All standard features |
| Mermaid | ✓ | Diagrams rendered to SVG |
| PDF | ✓ | Via weasyprint |
| HTML | ✓ | Standalone or linked CSS |

## Blockquotes

> This is a blockquote. It can contain multiple paragraphs.
>
> Here's the second paragraph.

## Horizontal Rule

---

## Math (when supported)

Inline math: $E = mc^2$

Block math:
$$
\frac{n!}{k!(n-k)!} = \binom{n}{k}
$$