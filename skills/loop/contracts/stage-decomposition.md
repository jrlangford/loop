# Contract: Stage Decomposition

**Boundary**: Decompose Stages → Specify Artifacts
**Workspace path**: `loop-workspace/stages.md`

## Content

Ordered list of pipeline stages with categories, intents, inputs, outputs, and dependencies.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `overview` | string | One-line summary + stage count |
| `stages[]` | array | Ordered list of stages |
| `stages[].name` | string | Verb-noun format |
| `stages[].category` | enum | Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit |
| `stages[].intent` | string | Single verb phrase |
| `stages[].input` | string | What this stage consumes |
| `stages[].output` | string | What this stage produces |
| `stages[].sources` | string | External read dependencies or "None" |
| `stages[].sinks` | string | External write targets or "None" |
| `stages[].complexity` | string | Special handling notes |

## Identity Fields

- `stages[].name` — stage names are referenced by all downstream artifacts

## Omitted

Detailed artifact schemas, gate positions, feedback loops, context budgets — all downstream concerns.

## Validation

- Every stage intent is a single verb phrase (no conjunctions)
- Every stage has a category from the enum
- No two stages share the same name
- Stage count matches overview

## Reasoning Trace

None — the decomposition is structural, not inferential.
