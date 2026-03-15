# Contract: Staleness Map

**Boundary**: Map Staleness → (edit workflow orchestrator)
**Workspace path**: `loop-workspace/staleness-map.md`

## Content

Which design artifacts are stale after a change, why, and which stages need re-execution.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `change_source` | string | Which artifact was modified and what changed |
| `stale_artifacts[]` | array | Artifacts affected by the change |
| `stale_artifacts[].artifact` | string | Artifact name |
| `stale_artifacts[].reason` | string | Why it's stale (forward dependency, backward feedback connection, removed reference, new connection) |
| `stale_artifacts[].cascade_path` | string | Connection path from change source to this artifact |
| `stale_artifacts[].recommended_stage` | string | Which stage to re-run |
| `stale_artifacts[].cascade_type` | enum | structural, content |
| `unaffected_artifacts[]` | array | Artifacts not affected |
| `unaffected_artifacts[].artifact` | string | Artifact name |
| `unaffected_artifacts[].reason` | string | Why it's not affected |

## Identity Fields

- `change_source` — anchors the analysis

## Omitted

The actual re-execution — the orchestrator decides what to run based on the map and user input.

## Validation

- Every artifact in the workspace appears in either `stale_artifacts` or `unaffected_artifacts`
- Every stale artifact has a `cascade_path` traceable from the `change_source`
- Every `recommended_stage` exists in stages.md

## Reasoning Trace

Full — the designer needs to understand why each artifact is considered stale to decide whether to accept the cascade recommendation.
