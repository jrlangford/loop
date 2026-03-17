# Contract: New Workflow Configuration

**Boundary**: [Compose-Workflow] → [Validate-Consistency], [Emit-Extended-Design]

## Content

The new workflow's gate and loop definitions, referencing reused and newly defined stages.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `workflow_name` | string | Reference to the target workflow name |
| `gates[]` | array | Gate definitions for the new workflow |
| `gates[].name` | string | Gate name |
| `gates[].position` | string | "[Stage A] → [Stage B]" boundary where this gate sits |
| `gates[].criteria` | string[] | Pass/fail criteria as testable statements |
| `gates[].on_fail` | enum | `retry`, `revise`, `halt`, `escalate` |
| `loops[]` | array | Loop definitions for the new workflow |
| `loops[].name` | string | Loop name |
| `loops[].from_stage` | string | Stage name where the loop originates |
| `loops[].to_stage` | string | Stage name where the loop returns |
| `loops[].trigger` | string | Condition that activates the loop |
| `loops[].max_iterations` | integer | Cap on loop repetitions |
| `loops[].loop_type` | enum | `reinforcing`, `balancing` |
| `transformation_update` | string or null | Updated scope text for transformation.md if the new workflow broadens the pipeline's purpose, or null if no update needed |

## Identity Fields

- `workflow_name` — ties this configuration to the target workflow
- `gates[].name` — gate names must not collide with gates in existing workflows
- `loops[].name` — loop names uniquely identify feedback paths

## Omitted

Stage definitions and artifact contracts — those are shared-level concerns already captured in New-Stage-Definitions and Existing-Design-Inventory.

## Validation

- Every `gates[].position` references stages that exist in either the existing inventory or new stage definitions
- Every `loops[].from_stage` and `loops[].to_stage` references a stage that exists in either the existing inventory or new stage definitions
- `max_iterations` is a positive integer
- `on_fail` is one of `retry`, `revise`, `halt`, `escalate`
- `loop_type` is one of `reinforcing`, `balancing`
- No gate name collides with gates in existing workflows

## Reasoning Trace

Summary — gate criteria and loop triggers involve judgment about where quality checks and iteration are needed. Rationale is embedded in the criteria and trigger text.
