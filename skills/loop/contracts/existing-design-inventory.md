# Contract: Existing Design Inventory

**Boundary**: [Extract-Existing-Design] → [Analyze-Reuse], [Define-New-Stages], [Compose-Workflow], [Validate-Consistency]

## Content

Structured index of all stages, artifacts, context specs, and workflow configurations in the existing pipeline.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `stages[]` | array | Existing stage entries |
| `stages[].name` | string | Stage name (verb-noun) |
| `stages[].category` | enum | Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit |
| `stages[].intent` | string | Single verb phrase |
| `stages[].input_contract_summary` | string | One-line summary of the stage's input shape |
| `stages[].output_contract_summary` | string | One-line summary of the stage's output shape |
| `stages[].domain_assumptions` | string[] | Key domain-specific assumptions embedded in the stage |
| `artifacts[]` | array | Existing artifact entries |
| `artifacts[].name` | string | Artifact name |
| `artifacts[].boundary` | string | "[Stage A] → [Stage B]" |
| `artifacts[].field_names` | string[] | Top-level field names in the artifact's structure |
| `context_specs[]` | array | Existing context spec entries |
| `context_specs[].stage_name` | string | Stage this spec applies to |
| `context_specs[].budget_summary` | string | One-line budget description |
| `workflows[]` | array | Existing workflow configurations |
| `workflows[].name` | string | Workflow name |
| `workflows[].gate_count` | integer | Number of gates defined |
| `workflows[].loop_count` | integer | Number of loops defined |
| `workflows[].stage_references` | string[] | Stage names referenced by this workflow's gates and loops |

## Identity Fields

- `stages[].name` — stage names must be unique across the inventory
- `artifacts[].name` — artifact names must be unique across the inventory
- `workflows[].name` — workflow names must be unique across the inventory

## Omitted

Full artifact field definitions, full gate criteria text, full loop configuration details — only summaries needed for reuse analysis and collision detection.

## Validation

- Every `stages[].name` is unique
- Every `artifacts[].name` is unique
- Every `workflows[].name` is unique
- `stage_references` entries all resolve to entries in `stages[].name`

## Reasoning Trace

None — structural extraction, not inferential.
