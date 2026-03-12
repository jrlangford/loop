# Contract: Boundary List

**Produced by**: Identify Boundaries (Stage 3)
**Consumed by**: Extract Behaviours (Stage 4)
**Workspace path**: `autodoc-workspace/boundary-list.md`

## Structure

```yaml
boundaries:
  - id: <temporary sequential index for reference within this artifact>
    location:
      file: <file path>
      function: <function/method name>
      line_range: [start, end]
    type: "conditional_branch" | "error_handling" | "validation_gate"
          | "state_transition" | "integration_point" | "config_driven"
    decision_summary: <one sentence: what choice does the system make here?>
    evidence: |
      <verbatim code snippet showing the branching point, max 10 lines>
    reference_hints:
      - <source_locator values from Reference Index that informed this identification>
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | int | Yes | Temporary sequential index (for reference within this artifact only) |
| `location.file` | string | Yes | File path (must exist in Codebase Structural Map) |
| `location.function` | string | Yes | Function or method name |
| `location.line_range` | [int, int] | Yes | Start and end line numbers of the decision boundary |
| `type` | enum | Yes | Single type from the boundary type enum |
| `decision_summary` | string | Yes | One sentence with a single decision verb |
| `evidence` | string | Yes | Verbatim code snippet, max 10 lines |
| `reference_hints` | list[string] | No | Source locators from Reference Index (empty list when no references matched) |

## Identity Fields

`location` (file, function, line_range) and `evidence` (verbatim snippet) are identity fields.

## Omitted

- Full function body
- Surrounding context and call graph
- Stage 4 re-reads the source file for full context during extraction

## Validation Rules

1. Each boundary has a single `type` from the enum (no multi-type entries)
2. `decision_summary` is one sentence with a single decision verb
3. `evidence` is verbatim source code, not paraphrase
4. `location.file` exists in the Codebase Structural Map
5. No duplicate boundaries (same file + function + overlapping line_range)

## Reasoning Trace

Summary level. `reference_hints` records which references (if any) influenced the decision to include this boundary. This helps Stage 4 understand why a boundary was considered significant.
