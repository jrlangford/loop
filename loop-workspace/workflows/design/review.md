# Pipeline Design Review — Design Workflow

## Summary
- **Files reviewed**: transformation.md, stages.md, artifacts.md, context-specs.md, workflows/design/gates.md, workflows/design/loops.md
- **Missing files**: None
- **Issues found**: 0 ERROR, 4 WARNING, 3 INFO

## Issues

### WARNING: Decomposition Validity Gate semantic check lacks clean context specification
- **Location**: workflows/design/gates.md — Gate: Decomposition Validity
- **Finding**: The gate includes a semantic check (Kitchen Sink detection, coverage of gap analysis) but does not specify that this semantic evaluation should run in a clean subagent context. The Re-grounding gate correctly specifies a clean validation context, but the Decomposition Validity gate does not. If the semantic check runs in the producing stage's context, the decomposition rationale may bias the evaluation.
- **Suggested fix**: Add a `**Validation context**` field to the Decomposition Validity gate specifying that the semantic check runs in a clean subagent with only stages.md, the Kitchen Sink criteria, and the gap analysis from transformation.md.
- **Skill to re-run**: `/loop:phase-gates design`

### WARNING: Transformation Completeness gate criteria may be too shallow
- **Location**: workflows/design/gates.md — Gate: Transformation Completeness
- **Anti-pattern**: Phantom Feedback Loop (potential)
- **Finding**: The schema criteria check field presence (task is single sentence, input_spec present, gap_analysis non-empty) but not field quality. A transformation definition with "Input: text. Output: text. Gap: it's hard." would pass all schema checks. The human gate catches quality issues at `minimal` and `per-stage` levels, but at interaction level `none`, only the schema gate runs — and it may pass trivially bad definitions.
- **Suggested fix**: Add a metric or semantic check for `none` interaction level: minimum word counts for gap_analysis (e.g., ≥ 50 words), or a semantic check that the gap analysis identifies at least one specific difficulty (not just generic statements).
- **Skill to re-run**: `/loop:phase-gates design`

### WARNING: Worst-case cost ratio exceeds 3× threshold
- **Location**: Pipeline-wide
- **Finding**: Best case: 9 inference calls (7 stages + 2 semantic gates). Worst case: ~34 calls (all loops hit max caps, including cascading re-grounding). Ratio: ~3.8×. The primary cost driver is the Review Correction loop (up to 3 cycles, each potentially re-running a stage + its gates) and the Decomposition Correction loop (3 iterations + 3 semantic gate evaluations).
- **Suggested fix**: Consider reducing the Decomposition Correction hard cap from 3 to 2, or making the Review Correction loop route to at most one stage per cycle (rather than potentially multiple). Alternatively, accept the ratio — the worst case requires every loop to fail maximally, which is unlikely in practice.

### WARNING: Review Correction loop can cascade through upstream gates and loops
- **Location**: workflows/design/loops.md — Loop: Review Correction
- **Finding**: When Review routes a finding to, say, Decompose Stages, the corrected stages.md must then pass through the Decomposition Validity gate (which may trigger the Decomposition Correction loop), then Specify Artifacts must re-run (Contract Integrity gate, Contract Correction loop), then Re-grounding may fire. The total cost of a single review correction can be much higher than one stage re-run. The loops.md acknowledges the Ouroboros risk but doesn't specify how the orchestrator should handle the cascade budget.
- **Suggested fix**: Add an orchestrator guidance note: when Review Correction routes to an upstream stage, the orchestrator should track the total re-execution cost (stages + gates + loops triggered) and cap the cascade at a budget (e.g., max 10 additional calls per review correction). If the budget is exceeded, present the current state to the user rather than continuing.

### INFO: Stage 8 (Map Staleness) unused in design workflow
- **Location**: stages.md — Stage 8
- **Finding**: Map Staleness is defined in stages.md but only used by the edit workflow. This is correct (stages are reusable building blocks, workflows compose them), but worth noting for clarity — the design workflow uses stages 1-7 only.

### INFO: Stochastic validation not addressed
- **Location**: Pipeline-wide
- **Finding**: The design does not address multi-run testing. LLM stages are stochastic — a single test run cannot characterize pipeline reliability. The designer should plan for multiple runs to measure gate pass rates, loop iteration distributions, and output quality variance.

### INFO: No preconditions defined
- **Location**: workflows/design/
- **Finding**: No preconditions.md exists for the design workflow. This pipeline has no external sources or sinks, so preconditions are not strictly needed. However, the pipeline does depend on `/skill-creator` being available (referenced in the implement skill) — if this pipeline is meant to flow into `/loop:implement`, that dependency could be noted.

## Anti-Pattern Check Results

| Anti-pattern | Status | Notes |
|-------------|--------|-------|
| Kitchen Sink Stage | ✓ Pass | All 8 stages pass one-verb heuristic |
| Echo Chamber Loop | ✓ Pass | No reinforcing loops |
| History Avalanche | ✓ Pass | All stages default to no history. Review legitimately needs all artifacts. |
| Phantom Feedback Loop | ⚠ Potential | Transformation Completeness gate at `none` interaction level (see WARNING above) |
| Hardcoded Chain | ✓ Pass | Stages don't reference successors. Stages 4 and 5 are parallel. |
| Ouroboros | ⚠ Acknowledged | Re-grounding → Decompose → Specify → Re-grounding cycle exists but capped at 1 iteration. Review Correction can cascade but capped at 3 cycles. |
| Telephone Game | ✓ Pass | Artifacts use enums (category, gate type, loop type, severity). Identity fields declared. Re-grounding gate at midpoint. |
| Fire-and-Forget Emit | N/A | No Emit stages |

## Structural Check Results

| Check | Status | Notes |
|-------|--------|-------|
| Artifact completeness | ✓ Pass | Every boundary has an artifact spec. Every artifact has a consumer. |
| Gate coverage | ✓ Pass | Critical boundaries gated. Ungated boundaries justified. |
| Context isolation | ✓ Pass | Subagent delegation specified for all stages (except Stage 1 interactive mode). Review and Map Staleness run in independent subagents. |
| Semantic gate isolation | ⚠ Partial | Re-grounding gate specifies clean context. Decomposition Validity gate does not (see WARNING). |
| Loop safety | ✓ Pass | All loops have semantic + hard cap termination. All have degradation detectors. All have best-iteration selection. |
| Handoff drift resilience | ✓ Pass | Enums, identity fields, re-grounding checkpoint all present. |
| Context hygiene | ✓ Pass | No history accumulation. All stages have context specs. |

## Cost Estimate — Design Workflow

| Scenario | Stage calls | Gate calls | Total |
|----------|------------|------------|-------|
| Best case (all gates pass) | 7 | 2 (semantic) | 9 |
| Typical (1-2 loop iterations) | 9 | 4 | 13 |
| Worst case (all loops max) | ~24 | ~10 | ~34 |

Worst/best ratio: ~3.8× (above 3× threshold — see WARNING).

No external API costs — all stages are pure transformations writing to local filesystem.

## Pipeline Health

**Verdict: PASS_WITH_WARNINGS**

The design workflow is well-structured with appropriate gate coverage, all loops properly bounded, and good handoff drift resilience. The four warnings are all addressable:

1. Add clean context spec to the Decomposition Validity semantic gate (straightforward fix)
2. Strengthen the Transformation Completeness gate for `none` interaction level (add minimum quality check)
3. Accept or reduce the worst-case cost ratio (likely acceptable in practice)
4. Add cascade budget guidance for Review Correction (orchestrator-level concern)

None of these block implementation — they're refinements that improve robustness. The design is ready for `/loop:implement` with these warnings noted.
