# Feedback Loop Specifications — Edit Workflow

## Loop: Staleness Map Correction
- **Type**: Balancing
- **Stages involved**: Map Staleness → [Staleness Map Validation Gate] → Map Staleness
- **Purpose**: Correct invalid cascade paths or missing artifacts in the staleness analysis
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: All artifacts accounted for (stale or unaffected). All cascade paths traceable through the connection graph. All recommended stages exist.
  - **Hard cap**: 2 iterations
- **Degradation detector**: Track the count of validation failures per iteration. If the count increases or stays the same, the stage is not incorporating feedback. Use the iteration with fewer validation failures.
- **Best-iteration selection**: Select iteration with fewest validation failures. On tie, prefer the iteration that flags more artifacts as stale (conservative — better to re-execute unnecessarily than to miss a stale artifact).
- **Anti-pattern risks**: Low — staleness map validation is mostly structural (graph traversal correctness, field presence). The semantic check (cascade path validity) is bounded by the size of the connection graph.

## Inherited Loops (from design workflow)

Re-executed stages use the same feedback loops as the design workflow. When a gate fails on a re-executed stage, the same retry logic applies:

| Re-executed stage | Loop applied | Hard cap | Source |
|-------------------|-------------|----------|--------|
| Define Transformation | Transformation Refinement | 2 | design/loops.md |
| Decompose Stages | Decomposition Correction | 3 | design/loops.md |
| Specify Artifacts | Contract Correction | 2 | design/loops.md |
| Specify Artifacts | Re-grounding Correction | 1 | design/loops.md |
| Place Gates | Gate Correction | 2 | design/loops.md |
| Review Design | Review Correction | 3 cycles | design/loops.md |

## Edit Workflow Addenda to Review Correction

The inherited Review Correction loop applies as defined in design/loops.md, with the following extensions when running in the edit workflow:

**Additional termination criterion**: No new staleness detected — artifacts that were marked unaffected in the staleness map are still consistent with re-executed artifacts.

**Additional degradation signal**: If review discovers artifacts that should have been in the staleness map but weren't, flag this as a staleness map quality issue for future runs.

**Ouroboros prevention**: The orchestrator must NOT re-invoke Map Staleness from within a review correction cycle. If review discovers missed staleness, it flags it as a WARNING for the user rather than restarting the edit workflow. This prevents the cycle: review → Map Staleness → new stale artifacts → more re-execution → review.

**Additional check**: Review must verify consistency between re-executed and non-re-executed artifacts. Partial re-execution can introduce mismatches that a full-pipeline review wouldn't encounter.

## Cascade Budget

Same as design workflow: max 10 additional inference calls per review correction cycle.

## Edit-Specific Routing Rules

In addition to the design workflow's routing rules, the edit workflow adds:

| Finding type | Routes to | Rationale |
|-------------|-----------|-----------|
| Missed staleness (artifact marked unaffected is inconsistent) | User notification (WARNING) | Do not re-invoke Map Staleness mid-review — present to user for next edit cycle |
| Inconsistency between re-executed and non-re-executed artifacts | The re-executed stage that produced the inconsistent output | The non-re-executed artifact is assumed correct; the re-executed one must conform |
