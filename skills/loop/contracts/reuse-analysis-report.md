# Contract: Reuse Analysis Report

**Boundary**: [Analyze-Reuse] → [Define-New-Stages], [Compose-Workflow]

## Content

Per-stage reuse verdict for the new workflow plus identified capability gaps.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `workflow_name` | string | Reference to the target workflow name from New-Workflow-Description |
| `stage_verdicts[]` | array | One entry per existing stage |
| `stage_verdicts[].stage_name` | string | Reference to existing stage name |
| `stage_verdicts[].verdict` | enum | `reuse-as-is`, `not-applicable` |
| `stage_verdicts[].rationale` | string | One to two sentences justifying the verdict |
| `capability_gaps[]` | array | Capabilities the new workflow needs but no existing stage provides |
| `capability_gaps[].gap_id` | string | Unique identifier (e.g., `gap-1`) |
| `capability_gaps[].description` | string | What capability is missing, one sentence |
| `capability_gaps[].requirement_refs` | string[] | Which `key_requirements` from the input this gap maps to |

## Identity Fields

- `workflow_name` — ties this report to the target workflow
- `stage_verdicts[].stage_name` — each existing stage appears exactly once

## Omitted

Suggested stage designs for gaps — that is the Define-New-Stages concern. No partial-reuse or adapt verdicts — stages are either reused as-is or not applicable; adaptation means a new stage.

## Validation

- Every existing stage name appears exactly once in `stage_verdicts`
- Every `capability_gaps[].gap_id` is unique
- `verdict` is one of the enum values (`reuse-as-is`, `not-applicable`)
- At least one entry exists in either reused stages or capability gaps

## Reasoning Trace

Summary — reuse decisions are judgment calls and downstream stages need the rationale to validate them. Rationale is captured per-verdict.
