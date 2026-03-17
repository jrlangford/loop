# Contract: Validation Report

**Boundary**: [Validate-Consistency] → [Emit-Extended-Design]

## Content

Cross-workflow consistency check results covering the full extended design.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `overall_status` | enum | `pass`, `fail` |
| `checks_performed[]` | array | List of consistency checks run |
| `checks_performed[].check_name` | string | Name of the check |
| `checks_performed[].scope` | enum | `naming`, `gate-compatibility`, `reference-integrity`, `context-spec-compatibility` |
| `checks_performed[].status` | enum | `pass`, `fail` |
| `checks_performed[].details` | string | What was checked, one sentence |
| `inconsistencies[]` | array | Failures found, empty if `overall_status` is `pass` |
| `inconsistencies[].check_name` | string | Reference to the failing check |
| `inconsistencies[].severity` | enum | `error`, `warning` |
| `inconsistencies[].description` | string | What is inconsistent |
| `inconsistencies[].affected_elements` | string[] | Names of stages, artifacts, gates, or workflows involved |
| `inconsistencies[].suggested_fix` | string | Actionable remediation, one sentence |

## Identity Fields

- `checks_performed[].check_name` — each check is uniquely named for traceability

## Omitted

Corrected versions of failing elements — the Emit stage should not proceed if `overall_status` is `fail`. Correction is an upstream concern via feedback loops.

## Validation

- `overall_status` is `fail` if and only if at least one `checks_performed[].status` is `fail`
- Every `inconsistencies[].check_name` references a check in `checks_performed`
- `severity` is one of `error`, `warning`
- `scope` is one of `naming`, `gate-compatibility`, `reference-integrity`, `context-spec-compatibility`

## Reasoning Trace

Summary — validation judgments (especially gate-compatibility on shared stages) require rationale. Captured in `details` and `description` fields.
