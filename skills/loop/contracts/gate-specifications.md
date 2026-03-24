# Contract: Gate Specifications

**Boundary**: Place Gates → Design Feedback
**Workspace path**: `loop-workspace/workflows/<workflow>/gates.md`

## Content

Validation checkpoints between stages — positions, types, criteria, failure routes, escalation paths.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `gates[]` | array | One entry per gate |
| `gates[].name` | string | Descriptive name |
| `gates[].position` | string | "Between [Stage A] and [Stage B]" |
| `gates[].artifact_checked` | string | Artifact name (must match artifacts.md) |
| `gates[].type` | enum | Schema, Metric, Identity, Semantic, Consensus, Human |
| `gates[].criteria` | string | What must be true to pass |
| `gates[].domain_guidelines_applied` | string[] (optional) | Which domain guidelines from `transformation.md` are encoded in this gate's criteria. Omit when no domain guidelines apply to this boundary. |
| `gates[].on_failure.routes_to` | string | Stage name |
| `gates[].on_failure.carries` | string | What feedback the failing stage receives |
| `gates[].on_failure.max_retries` | integer | Maximum retry count |
| `gates[].on_failure.escalation` | string | What happens after max retries (human review, skip, abort) |
| `ungated_boundaries[]` | array | Boundaries without gates |
| `ungated_boundaries[].boundary` | string | "[Stage A] → [Stage B]" |
| `ungated_boundaries[].rationale` | string | Why no gate is needed |
| `human_gate_candidates[]` | array | Boundaries where human review is recommended based on risk assessment (optional — present when Place Gates runs Step 5) |
| `human_gate_candidates[].boundary` | string | "[Stage A] → [Stage B]" |
| `human_gate_candidates[].risk_dimensions` | string[] | Which dimensions triggered (from: Irreversible side effects, Domain authority gap, Subjective quality criteria, High fan-in convergence, Semantic gate stacking, Error reinforcement risk) |
| `human_gate_candidates[].rationale` | string | Why human review is warranted at this boundary |
| `human_gate_candidates[].disposition` | enum | `promoted` (became a Human gate), `documented` (recorded but not gated), `overridden` (designer declined with rationale) |

## Identity Fields

- `gates[].name` — referenced by feedback loops
- `gates[].position` — referenced by feedback loops

## Omitted

Loop configuration, degradation detection — those are the feedback design concern.

## Validation

- Every artifact boundary has either a gate or an ungated boundary with rationale
- Every gate failure route points to a stage that exists in stages.md
- Every gate has max_retries > 0 and a non-empty escalation
- Gate type is from the enum
- Human gates are used only where pipeline interaction level permits
- Every `human_gate_candidates[].disposition` is from the enum: `promoted`, `documented`, `overridden`
- Every `human_gate_candidates[].risk_dimensions` entry is from the set: Irreversible side effects, Domain authority gap, Subjective quality criteria, High fan-in convergence, Semantic gate stacking, Error reinforcement risk
- Every `human_gate_candidates[].boundary` matches a real artifact boundary

## Reasoning Trace

Summary — gate placement decisions involve failure mode analysis worth preserving.
