# Contract: Codebase Structural Map

**Produced by**: Survey Codebase (Stage 2)
**Consumed by**: Identify Boundaries (Stage 3), Post-Pipeline Consistency Gate
**Workspace path**: `autodoc-workspace/structural-map.md`

## Structure

```yaml
files:
  - path: <file path relative to project root>
    language: <detected language>
    constructs:
      - type: "function" | "method" | "class" | "module"
        name: <identifier>
        signature: <parameter types and return type, language-appropriate>
        line_range: [start, end]
        calls: [<list of construct names this construct calls>]
    test_file: <path to corresponding test file> | null

test_mapping_conventions: <detected test naming pattern, e.g., "*_test.go", "*.spec.ts">
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `path` | string | Yes | File path relative to project root |
| `language` | string | Yes | Detected programming language (not null, not "unknown") |
| `constructs` | list | Yes | Functions, methods, classes, modules in this file |
| `constructs[].type` | enum | Yes | One of: `function`, `method`, `class`, `module` |
| `constructs[].name` | string | Yes | Non-empty identifier |
| `constructs[].signature` | string | Yes | Parameter types and return type |
| `constructs[].line_range` | [int, int] | Yes | Start and end line numbers |
| `constructs[].calls` | list[string] | Yes | Names of constructs this one calls (may be empty) |
| `test_file` | string\|null | Yes | Path to corresponding test file, or null if none identified |
| `test_mapping_conventions` | string | Yes | Detected test naming pattern |

## Identity Fields

`path`, `name`, and `line_range` are source-of-truth references that must not mutate downstream.

## Omitted

- Raw file contents (Stage 3 re-reads source files as needed via tools)
- Inline comments
- Import statements
- Type definitions that are not decision-relevant

This is a compressed representation — signatures and structure, not bodies.

## Validation Rules

1. Every file in `target_scope` is represented in the map
2. Every construct has a non-empty `name` and valid `line_range` (start < end, both positive)
3. `language` is detected for each file (not null or "unknown")
4. At least one construct found across all files (catches total parse failure)
5. `test_mapping_conventions` is populated (test file detection was attempted)

## Reasoning Trace

None. The map is mechanical extraction, no judgment involved.
