# Contract: New Workflow Description

**Boundary**: [Pipeline Input] → [Analyze-Reuse]

## Content

The user's natural-language description of the new workflow to be added.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `workflow_name` | string | Kebab-case identifier for the new workflow (e.g., `code-review`) |
| `description` | string | Free-text description of the workflow's purpose and desired behavior, max 500 words |
| `key_requirements` | string[] | Ordered list of concrete requirements the workflow must satisfy |

## Identity Fields

- `workflow_name` — referenced by all downstream artifacts

## Omitted

Implementation details, gate/loop preferences — downstream concerns.

## Validation

- `workflow_name` is non-empty kebab-case
- `description` is non-empty
- `key_requirements` has at least one entry

## Reasoning Trace

None — user-provided input.
