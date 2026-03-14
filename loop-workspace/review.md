# Cross-Workflow Consistency Review

## Summary
- **Workflows reviewed**: design, edit
- **Shared artifacts reviewed**: transformation.md, stages.md, artifacts.md, context-specs.md
- **Issues found**: 0 ERROR, 1 WARNING, 2 INFO

## Cross-Workflow Checks

### Shared stage consistency
- **Design workflow** uses stages 1-7 (Define Transformation through Review Design) ✓
- **Edit workflow** uses stage 8 (Map Staleness) then selectively re-executes stages 1-7 ✓
- All 8 stages in stages.md are used by at least one workflow ✓
- No workflow references a stage that doesn't exist in stages.md ✓

### Gate inheritance integrity
- Edit workflow declares inheritance from design/gates.md for all re-executed stages ✓
- Every gate in design/gates.md that applies to a re-executable stage is listed in the edit inheritance table ✓
- Edit-specific gates (Staleness Map Validation, Staleness Map Acceptance) reference Stage 8 which exists ✓
- The "validate against current upstream artifacts" note correctly addresses the partial re-execution case ✓

### Loop inheritance integrity
- Edit workflow declares inheritance from design/loops.md for all re-executed stages ✓
- Every loop in design/loops.md that applies to a re-executable stage is listed in the edit inheritance table ✓
- Edit Review Correction is now addenda to inherited Review Correction (no duplication) ✓
- Cascade budgets match: both workflows use 10-call budget per review cycle ✓

### Artifact contract consistency
- Both workflows produce/consume the same artifact types as defined in artifacts.md ✓
- Staleness Map artifact (edit-only) is fully specified in artifacts.md ✓
- Pipeline inputs differ by workflow (Task Description for design, Existing Workspace + Modification Request for edit) — both specified in artifacts.md ✓

### Context spec consistency
- All 8 stages have context specs in context-specs.md ✓
- Context specs are workflow-independent (as designed — stages are reusable) ✓
- Map Staleness context spec correctly notes it needs full workspace (same justification as Review) ✓

## Issues

### WARNING: Review Design stage output artifact differs by workflow but artifact spec doesn't distinguish
- **Location**: artifacts.md — Review Results artifact; stages.md — Stage 7
- **Finding**: In the design workflow, Review checks a freshly-built design. In the edit workflow, Review checks a partially re-executed design and must additionally verify consistency between re-executed and non-re-executed artifacts. The Review Results artifact spec doesn't have a field to capture edit-specific findings (missed staleness, cross-artifact inconsistency from partial re-execution). The edit workflow addenda to Review Correction describe these checks, but the artifact spec doesn't reflect them.
- **Suggested fix**: Add an optional `edit_findings` section to the Review Results artifact spec — present only when Review runs in the edit workflow. Fields: `missed_staleness[]` (artifacts that should have been flagged stale), `partial_execution_inconsistencies[]` (mismatches between re-executed and non-re-executed artifacts). This keeps the artifact spec complete without burdening the design workflow with unused fields.
- **Skill to re-run**: `/loop:phase-artifacts` (update Review Results spec)

### INFO: Interaction level handling is consistent across workflows
- **Location**: Both workflow gate specs
- **Finding**: Both workflows correctly parameterize human gates by interaction level. Design uses it for Transformation Completeness (conditional human gate) and the semantic-at-`none` addition. Edit uses it for Staleness Map Acceptance (conditional human gate). The `per-stage` level is handled by the orchestrator (present results after each stage) rather than by explicit human gates at every boundary — this is consistent and avoids gate bloat.

### INFO: Re-grounding gate placement differs in edit context
- **Location**: design/gates.md — Re-grounding gate; edit/gates.md — Inherited Gates
- **Finding**: The Re-grounding gate fires after Specify Artifacts in both workflows. In the edit workflow, if only Place Gates was flagged as stale (stages.md and artifacts.md unchanged), the Re-grounding gate won't fire — it only runs after Specify Artifacts. This is correct (if the upstream artifacts haven't changed, there's no drift to detect), but worth noting: the edit workflow relies on the staleness map to determine whether re-grounding is needed, rather than always re-grounding.

## Pipeline Health — Combined

**Verdict: PASS_WITH_WARNINGS**

Both workflows are internally consistent and correctly share stage-level artifacts. The inheritance model (edit inherits design gates and loops, extends with addenda) is clean and avoids duplication. The single warning is a minor artifact spec gap — adding optional edit-specific fields to Review Results.

The design is ready for implementation.
