# Contract: Artifact Specifications

**Boundary**: Specify Artifacts → Budget Context / Place Gates
**Workspace path**: `loop-workspace/artifacts.md`

## Content

Typed contracts for every inter-stage artifact — what crosses each boundary, how it's structured, what's omitted.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `artifacts[]` | array | One entry per inter-stage artifact |
| `artifacts[].name` | string | Descriptive name |
| `artifacts[].boundary` | string | "[Stage A] → [Stage B]" |
| `artifacts[].content` | string | What it carries |
| `artifacts[].structure` | structured | Fields, types, constraints |
| `artifacts[].identity_fields` | string[] | Fields that must not mutate |
| `artifacts[].omitted` | string | What the upstream stage produced but this artifact excludes |
| `artifacts[].validation` | string | How to check conformance |
| `artifacts[].reasoning_trace` | enum | None, Summary, Full — with rationale |

## Identity Fields

- `artifacts[].name` — referenced by gates and loops
- `artifacts[].boundary` — referenced by gates and loops

## Omitted

Context budgets, gate criteria, loop configurations — downstream concerns.

## Validation

- Every stage boundary has an artifact
- Every artifact has at least one field in its structure
- Every artifact consumed by an Emit stage includes idempotency markers
- No orphan artifacts (every artifact is produced by one stage and consumed by at least one)

## Reasoning Trace

None — contracts are declarative specifications.
