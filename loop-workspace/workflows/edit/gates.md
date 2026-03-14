# Gate Specifications — Edit Workflow

## Gate: Staleness Map Validation (after Map Staleness)
- **Position**: Between Map Staleness and selective re-execution
- **Artifact checked**: Staleness Map
- **Type**: Schema + Semantic
- **Criteria**:
  - Schema: Every artifact in the workspace appears in either `stale_artifacts` or `unaffected_artifacts` — none missing. Every stale artifact has `reason`, `cascade_path`, `recommended_stage`, and `cascade_type`. Every `recommended_stage` exists in stages.md. `change_source` is non-empty and references an actual artifact.
  - Semantic: Each `cascade_path` is traceable through the connection graph (forward through stage dependencies, backward through feedback loops and gate failure routes). No stale artifact is flagged without a valid connection to the `change_source`. No artifact that has a direct dependency on the `change_source` is listed as unaffected without justification.
- **Validation context**: Clean subagent with only the staleness map, the current workspace artifacts (for verifying the connection graph), and the validation criteria. Does NOT see the modification request — the gate validates the analysis, not the intent.
- **On failure**:
  - **Routes to**: Map Staleness
  - **Carries**: Schema failures: which artifacts are missing from the map, which stale entries lack required fields, which recommended stages don't exist. Semantic failures: which cascade paths are invalid (with the broken link identified), which directly-dependent artifacts were incorrectly marked unaffected.
  - **Max retries**: 2
  - **Escalation**: Present the staleness map to the user with the validation failures highlighted. The user manually decides which artifacts to re-execute — the map becomes advisory rather than authoritative.

## Gate: Staleness Map Acceptance (human, conditional)
- **Position**: After Staleness Map Validation passes, before re-execution begins
- **Artifact checked**: Staleness Map
- **Type**: Human (conditional)
- **Criteria**: At interaction level `minimal` or `per-stage`, present the staleness map to the user. The user reviews which artifacts are flagged as stale and can: accept the map as-is, modify the stale list (add or remove artifacts), or abort. At interaction level `none`, skip this gate.
- **Pass outcomes**:
  - **Accept as-is**: Gate passes, orchestrator uses the staleness map unchanged.
  - **User modifies stale list**: Gate passes with the user's modified version as the authoritative staleness map. The user's additions/removals (with rationale) are recorded in the map. Removing an artifact from the stale list means the user accepts the risk of inconsistency.
- **On failure** (user says the analysis is fundamentally wrong):
  - **Routes to**: Map Staleness
  - **Carries**: The user's explanation of what the analysis got wrong
  - **Max retries**: 1
  - **Escalation**: N/A — user decision is final. If the user rejects the re-analysis, abort the edit workflow.

## Inherited Gates (from design workflow)

Re-executed stages use the same gates as the design workflow. When a stage is re-run due to staleness, its output must pass the same validation as in a greenfield design:

| Re-executed stage | Gate applied | Source |
|-------------------|-------------|--------|
| Define Transformation | Transformation Completeness | design/gates.md |
| Decompose Stages | Decomposition Validity | design/gates.md |
| Specify Artifacts | Contract Integrity + Re-grounding | design/gates.md |
| Place Gates | Gate Referential Integrity | design/gates.md |
| Budget Context | (ungated — same rationale as design workflow) | design/gates.md |
| Design Feedback | (ungated — same rationale as design workflow) | design/gates.md |
| Review Design | N/A — Review is the final evaluator, not a gated stage | — |

**Important**: When re-executing a mid-pipeline stage (e.g., Specify Artifacts without re-running Decompose Stages), the gate must validate against the *current* upstream artifacts, not the ones from the original design run. The Contract Integrity gate checks references against the current stages.md — if stages.md wasn't re-run, it's the existing one.

## Ungated Boundaries

### Re-executed Budget Context → Review Design
- **Rationale**: Same as design workflow — context specs don't structurally cascade. Review catches issues.

### Re-executed Design Feedback → Review Design
- **Rationale**: Same as design workflow — Review is purpose-built to catch loop anti-patterns.
