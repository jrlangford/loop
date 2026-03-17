# Contract: New Stage Definitions

**Boundary**: [Define-New-Stages] → [Compose-Workflow], [Validate-Consistency], [Emit-Extended-Design]

## Content

Fully specified new stages and their artifact contracts, ready for append to shared pipeline artifacts.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `new_stages[]` | array | New stage definitions |
| `new_stages[].name` | string | Verb-noun format, unique across existing and new stages |
| `new_stages[].category` | enum | Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit |
| `new_stages[].intent` | string | Single verb phrase |
| `new_stages[].input` | string | What this stage consumes |
| `new_stages[].output` | string | What this stage produces |
| `new_stages[].sources` | string | External read dependencies or "None" |
| `new_stages[].sinks` | string | External write targets or "None" |
| `new_stages[].fills_gap` | string | Reference to `gap_id` from Reuse-Analysis-Report |
| `new_artifact_contracts[]` | array | New artifact contracts introduced by these stages |
| `new_artifact_contracts[].name` | string | Artifact name, unique across existing and new artifacts |
| `new_artifact_contracts[].boundary` | string | "[Stage A] → [Stage B]" |
| `new_artifact_contracts[].content` | string | What it carries, one sentence |
| `new_artifact_contracts[].structure` | structured | Fields, types, constraints |
| `new_artifact_contracts[].identity_fields` | string[] | Fields that must not mutate |
| `new_artifact_contracts[].omitted` | string | What is deliberately excluded |
| `new_artifact_contracts[].validation` | string | Conformance checks |
| `new_artifact_contracts[].reasoning_trace` | enum | None, Summary, Full — with rationale |
| `new_context_specs[]` | array | Context specs for new stages, if any |
| `new_context_specs[].stage_name` | string | Stage this spec applies to |
| `new_context_specs[].budget` | string | Budget specification |

## Identity Fields

- `new_stages[].name` — stage names are referenced by downstream workflow configuration and validation
- `new_artifact_contracts[].name` — artifact names must be globally unique across the extended design

## Omitted

Gate positions, loop definitions — those are workflow-scoped and handled by Compose-Workflow. Existing stage/artifact definitions — only new entries are included.

## Validation

- No `new_stages[].name` collides with any name in Existing-Design-Inventory
- No `new_artifact_contracts[].name` collides with existing artifact names
- Every `fills_gap` references a valid `gap_id` from Reuse-Analysis-Report
- Every new stage intent is a single verb phrase
- Emit-category stages include idempotency markers in their artifact contracts

## Reasoning Trace

None — structural definitions derived from gap specifications.
