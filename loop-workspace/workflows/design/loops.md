# Feedback Loop Specifications — Design Workflow

## Loop: Transformation Refinement
- **Type**: Balancing
- **Stages involved**: Define Transformation → [Transformation Completeness Gate] → Define Transformation
- **Purpose**: Correct incomplete or ambiguous transformation definitions before they cascade into decomposition
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: All schema criteria pass (task is single sentence, input/output specs present, gap analysis non-empty, complexity signals present). If human gate triggered, user approves.
  - **Hard cap**: 2 iterations
- **Degradation detector**: Compare completeness across iterations — if the second attempt has fewer filled sections than the first, the stage is removing content rather than adding it. Use the more complete version.
- **Best-iteration selection**: Track which iteration has the most complete transformation definition (all sections filled, gap analysis most specific). Select highest-completeness iteration.
- **Anti-pattern risks**: Phantom Feedback — if the gate criteria are too loose (e.g., just checking field presence without quality), the loop may pass on the first attempt every time, providing no actual correction.

## Loop: Decomposition Correction
- **Type**: Balancing
- **Stages involved**: Decompose Stages → [Decomposition Validity Gate] → Decompose Stages
- **Purpose**: Correct Kitchen Sink stages, one-verb violations, and coverage gaps in the decomposition
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: All stages pass the one-verb heuristic. No Kitchen Sink flags. Stage count within range. All gap analysis difficulties from transformation.md are addressed by at least one stage.
  - **Hard cap**: 3 iterations
- **Degradation detector**: Track the number of gate violations per iteration. If violations increase or stay the same across two consecutive iterations, the stage is failing to incorporate feedback. Also watch for oscillation — stage being split in one iteration then merged in the next.
- **Best-iteration selection**: Select the iteration with the fewest gate violations. On tie, prefer the iteration with fewer stages (simpler decomposition).
- **Anti-pattern risks**: Echo Chamber — the stage may keep producing similar decompositions if the feedback isn't specific enough. Gate failure feedback must include the specific intents that violated one-verb and quote the offending text.

## Loop: Contract Correction
- **Type**: Balancing
- **Stages involved**: Specify Artifacts → [Contract Integrity Gate] → Specify Artifacts
- **Purpose**: Correct referential integrity failures and missing artifact specifications
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: Every stage boundary has an artifact. Every artifact has required fields. All stage name references match stages.md exactly. No orphan artifacts.
  - **Hard cap**: 2 iterations
- **Degradation detector**: Track the count of integrity violations per iteration. If the count increases, the stage is introducing new errors while fixing old ones. Use the iteration with fewer violations.
- **Best-iteration selection**: Select iteration with fewest referential integrity violations. On tie, prefer the iteration where identity fields are most explicitly declared.
- **Anti-pattern risks**: Low risk — contract integrity is mostly deterministic (field presence, name matching). Failures here are typically omissions, not quality judgments.

## Loop: Re-grounding Correction
- **Type**: Balancing
- **Stages involved**: [Re-grounding Gate] → Decompose Stages OR Specify Artifacts → ... → [Re-grounding Gate]
- **Purpose**: Correct drift between the design's artifact chain and the original transformation definition
- **Established pattern**: Evaluator-optimizer (with variable routing)
- **Termination**:
  - **Semantic**: The artifact chain from pipeline input to pipeline output faithfully represents the transformation in transformation.md. No scope creep. All gap analysis difficulties are addressed.
  - **Hard cap**: 1 iteration (re-grounding is expensive — it may re-trigger decomposition and contract correction loops)
- **Degradation detector**: Not applicable at 1 iteration. If the single correction attempt doesn't resolve the drift, escalate to user.
- **Best-iteration selection**: Not applicable — single iteration.
- **Anti-pattern risks**: Ouroboros — re-grounding routes back to Decompose Stages, which produces new stages.md, which triggers Specify Artifacts, which triggers re-grounding again. The hard cap of 1 prevents this from cycling, but the orchestrator must track that re-grounding has already fired once and not re-trigger it on the corrected output.

## Loop: Gate Correction
- **Type**: Balancing
- **Stages involved**: Place Gates → [Gate Referential Integrity Gate] → Place Gates
- **Purpose**: Correct broken references in gate specifications (nonexistent artifact names, nonexistent stage names)
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: All artifact_checked references match artifacts.md. All routes_to references match stages.md. All required fields present. All escalation paths non-empty.
  - **Hard cap**: 2 iterations
- **Degradation detector**: Track count of referential integrity violations. If count increases across iterations, use the iteration with fewer violations.
- **Best-iteration selection**: Select iteration with fewest referential integrity violations.
- **Anti-pattern risks**: Low risk — similar to Contract Correction, this is mostly deterministic validation.

## Loop: Review Correction
- **Type**: Balancing
- **Stages involved**: Review Design → [routing based on findings] → affected stage → ... → Review Design
- **Purpose**: Correct cross-cutting anti-patterns and consistency issues that individual gates don't catch
- **Established pattern**: Evaluator-optimizer (with multi-target routing)
- **Termination**:
  - **Semantic**: Review verdict is PASS or PASS_WITH_WARNINGS (no ERROR-severity findings remaining). All consistency checks pass.
  - **Hard cap**: 3 review cycles
- **Degradation detector**: Track the count of ERROR-severity findings per review cycle. If the count increases or stays the same across two consecutive cycles, the corrections are introducing new issues at the same rate as fixing old ones. Also track whether the same finding reappears across cycles — a recurring finding means the corrective stage isn't addressing the root cause.
- **Best-iteration selection**: Select the review cycle with the fewest ERROR-severity findings. If all cycles have errors, present the best attempt with its remaining findings to the user.
- **Anti-pattern risks**:
  - **Ouroboros**: Review routes to Stage X, which changes an artifact, which causes a different review finding at Stage Y, which changes an artifact that re-triggers the original finding. The hard cap of 3 prevents infinite cycling, but the orchestrator should track whether findings are recurring.
  - **Phantom Feedback**: If review criteria are too loose, review always passes on the first attempt. The review stage must check all 7 anti-patterns and verify full referential integrity — not just surface-level structure.

## Cascade Budget for Review Correction

When Review Correction routes to an upstream stage, the corrected artifact must pass through its own gates — which may trigger their own loops. The orchestrator must track the total re-execution cost per review cycle:

- **Budget**: Max 10 additional inference calls per review correction cycle (stages + gates + loops triggered by the cascade).
- **On budget exceeded**: Stop the cascade, present the current state to the user, and report which corrections completed and which were cut short.
- **Tracking**: The orchestrator maintains a call counter that resets at the start of each review cycle. Every subagent invocation (stage re-run, semantic gate evaluation) increments the counter.

This budget also addresses the worst-case cost ratio — it caps the practical maximum even if multiple loops would otherwise cascade.

## Routing Rules for Review Correction

Review findings route to specific stages based on the finding type:

| Finding type | Routes to | Rationale |
|-------------|-----------|-----------|
| Kitchen Sink Stage | Decompose Stages | Decomposition boundary problem |
| Echo Chamber Loop | Design Feedback | Loop classification or termination problem |
| History Avalanche | Budget Context | Context budget problem |
| Phantom Feedback Loop | Place Gates or Design Feedback | Gate criteria too loose, or loop never fires |
| Hardcoded Chain | Decompose Stages | Stage coupling problem |
| Ouroboros | Design Feedback | Circular dependency in loops |
| Telephone Game | Specify Artifacts | Handoff drift in contracts |
| Referential integrity failure | The stage that produced the broken reference | Direct correction |
| Completeness gap | The stage that should have produced the missing element | Direct correction |
