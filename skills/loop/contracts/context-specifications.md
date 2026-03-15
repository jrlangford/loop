# Contract: Context Specifications

**Boundary**: Budget Context → (consumed by orchestrator)
**Workspace path**: `loop-workspace/context-specs.md`

## Content

Per-stage context window budgets — what goes in, what stays out, load assessment.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `context_specs[]` | array | One entry per stage |
| `context_specs[].stage` | string | Stage name (must match stages.md) |
| `context_specs[].germane_load` | string[] | What to include in context (signal) |
| `context_specs[].extraneous_load` | string[] | What to exclude (noise) |
| `context_specs[].intrinsic_load` | string | Inherent complexity assessment, chunking strategy if needed |
| `context_specs[].history_policy` | enum | none, summary, full — with justification |
| `context_specs[].isolation_model` | string | How this stage's context is managed (subagent delegation, clean context) |

## Identity Fields

- `context_specs[].stage` — must match stage names in stages.md

## Omitted

Gate criteria, loop configuration — those operate at the workflow level, not the stage level.

## Validation

- Every stage in stages.md has a context spec
- History policy defaults to "none" — any deviation has explicit justification
- Isolation model is specified for every stage

## Reasoning Trace

Summary — context budget decisions involve tradeoffs worth recording for future revision.
