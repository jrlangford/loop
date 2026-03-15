# Contract: Loop Specifications

**Boundary**: Design Feedback → Review Design
**Workspace path**: `loop-workspace/workflows/<workflow>/loops.md`

## Content

Feedback loop definitions — types, stages involved, termination conditions, degradation detectors.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `loops[]` | array | One entry per feedback loop |
| `loops[].name` | string | Descriptive name |
| `loops[].type` | enum | Reinforcing, Balancing |
| `loops[].stages_involved` | string | "[Stage A] → [Stage B] → [Stage A]" |
| `loops[].purpose` | string | What the loop achieves |
| `loops[].pattern` | string | Established pattern (Evaluator-optimizer, Prompt chaining, etc.) |
| `loops[].termination.semantic` | string | Condition meaning "done" |
| `loops[].termination.hard_cap` | integer | Maximum iterations |
| `loops[].degradation_detector` | string | How to detect things getting worse |
| `loops[].best_iteration_selection` | string | How to pick the best output on degradation |
| `no_loop_justification` | string | If no loops, why (optional) |

## Identity Fields

- `loops[].name` — referenced by orchestrators
- `loops[].stages_involved` — define the connection graph for cascade detection

## Omitted

Runtime execution details — those are the orchestrator's concern.

## Validation

- Every loop has both semantic termination and hard cap
- Every loop's stages exist in stages.md
- Balancing loops have degradation detectors
- Reinforcing loops have novelty gates
- No loop has hard_cap > 10 without explicit justification

## Reasoning Trace

Summary — loop design involves dynamic systems reasoning worth preserving.
