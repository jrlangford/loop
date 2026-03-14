# Pipeline Design Review — Edit Workflow

## Summary
- **Files reviewed**: transformation.md, stages.md, artifacts.md, context-specs.md, workflows/edit/gates.md, workflows/edit/loops.md (plus design workflow artifacts for inheritance validation)
- **Missing files**: None
- **Issues found**: 0 ERROR, 2 WARNING, 2 INFO

## Issues

### WARNING: Staleness Map Acceptance gate has ambiguous failure routing
- **Location**: workflows/edit/gates.md — Gate: Staleness Map Acceptance
- **Finding**: The failure route says "Routes to: Map Staleness (if the user says the analysis is wrong) or the orchestrator adjusts the execution plan (if the user modifies the stale list)." The second option — orchestrator adjusts the execution plan — is not a stage route. It's an orchestrator-level decision that bypasses the standard gate failure model. This works in practice (the orchestrator modifies its execution plan based on user input), but it's an implicit behavior not captured by the gate→stage routing model.
- **Suggested fix**: Split into two explicit paths: (1) on "analysis is wrong" → route to Map Staleness with user feedback, (2) on "user modifies stale list" → gate passes with a modified staleness map (the user's edits become the authoritative map). The second path is a gate pass, not a failure — the user approved a modified version.
- **Skill to re-run**: `/loop:phase-gates edit`

### WARNING: Edit Review Correction duplicates design Review Correction with minor additions
- **Location**: workflows/edit/loops.md — Loop: Edit Review Correction
- **Finding**: The Edit Review Correction loop is nearly identical to the design workflow's Review Correction, with two additions: (1) check for missed staleness, (2) consistency between re-executed and non-re-executed artifacts. The inheritance table already lists "Review Design | Review Correction | 3 cycles | design/loops.md" — having a separate Edit Review Correction loop creates ambiguity about which loop applies. Are there two review loops, or does Edit Review Correction replace the inherited one?
- **Suggested fix**: Remove Edit Review Correction as a separate loop. Instead, extend the inherited Review Correction with edit-specific addenda: "When running in the edit workflow, Review Correction additionally checks for missed staleness and cross-artifact consistency between re-executed and non-re-executed artifacts." This makes it clear that one loop applies, with workflow-specific extensions.
- **Skill to re-run**: `/loop:phase-feedback edit`

### INFO: No explicit ordering for selective re-execution
- **Location**: workflows/edit/gates.md — Inherited Gates section
- **Finding**: When multiple stages are flagged as stale, the edit workflow doesn't specify the re-execution order. The design workflow's linear sequence (define → decompose → artifacts → context/gates → feedback → review) implies an order, but the edit workflow may need to re-execute a non-contiguous subset (e.g., Specify Artifacts and Place Gates but not Decompose Stages). The orchestrator should follow the original pipeline ordering for the stale subset — never re-execute a downstream stage before its upstream dependency.
- **Suggested fix**: Add an orchestrator note: "Re-execute stale stages in pipeline order (as defined in stages.md). If a stage's upstream dependency was not flagged as stale, use the existing artifact as input."

### INFO: Staleness Map artifact not consumed by inherited gates
- **Location**: workflows/edit/gates.md — Inherited Gates section
- **Finding**: The inherited gates validate re-executed stage outputs against upstream artifacts (e.g., Contract Integrity checks against stages.md). But they don't receive the staleness map — so they can't distinguish a "this stage was re-executed because of a specific change" from "this stage is running fresh." This is fine for most gates (they validate the output regardless of why it was produced), but the Re-grounding gate might benefit from knowing what changed — it could focus its drift check on the area of change rather than the entire artifact chain.
- **Suggested fix**: No action needed — this is an optimization opportunity, not a deficiency. The Re-grounding gate works correctly without the staleness map; it just does a broader check than necessary.

## Anti-Pattern Check Results

| Anti-pattern | Status | Notes |
|-------------|--------|-------|
| Kitchen Sink Stage | ✓ Pass | Map Staleness (Stage 8) passes one-verb heuristic — "trace" |
| Echo Chamber Loop | ✓ Pass | No reinforcing loops |
| History Avalanche | ✓ Pass | Map Staleness needs full workspace (justified — same as Review) |
| Phantom Feedback Loop | ✓ Pass | Staleness Map Validation has specific structural criteria |
| Hardcoded Chain | ✓ Pass | Selective re-execution is inherently flexible |
| Ouroboros | ⚠ Acknowledged | Review → Map Staleness cycle explicitly prevented (review warns user instead of re-invoking Map Staleness) |
| Telephone Game | ✓ Pass | Inherits design workflow's identity fields and re-grounding |
| Fire-and-Forget Emit | N/A | No Emit stages |

## Structural Check Results

| Check | Status | Notes |
|-------|--------|-------|
| Artifact completeness | ✓ Pass | Staleness Map artifact fully specified in artifacts.md |
| Gate coverage | ✓ Pass | Staleness Map has both automated and human gates. Re-executed stages inherit design gates. |
| Context isolation | ✓ Pass | Map Staleness runs in subagent (specified in context-specs.md). Staleness Map Validation runs in clean subagent (specified in gate). |
| Loop safety | ✓ Pass | All loops bounded. Cascade budget inherited. |
| Handoff drift resilience | ✓ Pass | Staleness Map uses enums (cascade_type: structural | content). |

## Cost Estimate — Edit Workflow

| Scenario | Stage calls | Gate calls | Total |
|----------|------------|------------|-------|
| Best case (1 stale artifact, gates pass) | 2 (map + 1 re-execution) + 1 (review) = 3 | 1 (staleness validation semantic) + inherited gates | 5-7 |
| Typical (2-3 stale artifacts, 1 loop iteration) | 5-6 | 3-4 | 8-10 |
| Worst case (full cascade, all loops max) | Similar to design workflow worst case | Similar | ~35 |

The edit workflow's best case is significantly cheaper than the design workflow (5-7 vs. 9) — that's the point. The worst case is similar because a full cascade effectively re-runs the entire pipeline.

## Pipeline Health

**Verdict: PASS_WITH_WARNINGS**

The edit workflow is well-designed. It correctly inherits from the design workflow where appropriate and adds the right edit-specific machinery (staleness mapping, human acceptance gate, missed-staleness detection). The two warnings are minor:

1. Clarify the Staleness Map Acceptance gate's two paths (straightforward)
2. Merge Edit Review Correction into the inherited Review Correction with addenda (reduces ambiguity)

Ready for implementation.
