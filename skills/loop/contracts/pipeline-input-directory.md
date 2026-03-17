# Contract: Pipeline Input Directory

**Boundary**: [Pipeline Input] → [Extract-Existing-Design]

## Content

Reference to the existing populated loop-workspace directory that the pipeline will extend.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `workspace_path` | string | Absolute or relative path to the existing `loop-workspace/` directory |

## Identity Fields

- `workspace_path` — uniquely identifies the target workspace

## Omitted

Directory contents — the Extract stage reads them directly via source access.

## Validation

- Path exists and contains at least `stages.md`, `artifacts.md`, `context-specs.md`, and `transformation.md`
- May optionally contain a `workflows/` subdirectory with existing workflow configurations

## Reasoning Trace

None — simple path reference.
