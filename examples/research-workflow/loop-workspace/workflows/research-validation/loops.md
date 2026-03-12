# Feedback Loop Specifications

## Loop: Reconciliation Consensus
- **Type**: Balancing
- **Stages involved**: Compare Assessments → Reconcile Disagreements → Compare Assessments
- **Purpose**: Resolve reviewer disagreements through iterative re-examination with knowledge of other reviewers' positions. Each round narrows the dispute set — agreed claims exit the loop, only remaining disputes continue.
- **Established pattern**: Consensus (parallelisation with comparison)
- **Termination**:
  - **Semantic**: `disputed_claims` is empty in the Agreement Report (all claims resolved to unanimous or majority agreement)
  - **Hard cap**: 3 rounds
- **Degradation detector**: Stagnation detection via the Reconciliation Progress gate — if no reviewer has `position_changed: true` in a round, the loop exits immediately. No score-based tracking needed because the loop narrows (resolves claims) rather than producing competing versions.
- **Best-iteration selection**: Not applicable — the loop is monotonically narrowing. Each round resolves a subset of claims; agreed claims are removed and not re-examined. There is no "best version" to select; the output is the accumulation of all resolved claims plus any remaining unresolvable ones.
- **Anti-pattern risks**:
  - **Echo Chamber**: Reviewers could converge on the same wrong answer. Mitigated by: (1) requiring `change_rationale` to explain substantive reasons for position changes, (2) stagnation detector preventing pointless cycling, (3) web search access in Reconcile stage enabling new evidence discovery.
  - **Phantom Feedback**: Reconciliation step could make only cosmetic changes (rewording without reassessment). Mitigated by the `position_changed` boolean check — if no positions actually changed, the loop terminates via stagnation rather than cycling through cosmetic iterations.

## Loop: Extraction Retry
- **Type**: Balancing
- **Stages involved**: Extract Claims → [Extraction Completeness gate] → Extract Claims
- **Purpose**: Ensure claim extraction completeness by re-running extraction with specific feedback about missed claims
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: Extraction Completeness gate passes (no missed claims detected by the semantic evaluator)
  - **Hard cap**: 2 retries
- **Degradation detector**: Not needed at 2 retries. The semantic gate runs in a clean context (source document + claim list, no producer context), ensuring genuinely independent evaluation.
- **Best-iteration selection**: Always use last — each retry receives the list of missed claims from the gate, so later iterations should produce supersets of earlier ones. If retry 2 still fails, escalation proceeds with the most recent (most complete) extraction + incompleteness warning.
- **Anti-pattern risks**: Low. Independent evaluator context prevents the producing stage's trajectory from biasing validation.

## Loop: Citation Retry
- **Type**: Balancing
- **Stages involved**: Verify Claims (single instance) → [Citation Accuracy gate] → Verify Claims (same instance)
- **Purpose**: Fill in missing citation checks for claims that a reviewer failed to verify
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: Citation Accuracy gate passes (all cited claims have non-null `citation_valid`, all claim IDs present)
  - **Hard cap**: 1 retry
- **Degradation detector**: Not needed at 1 retry.
- **Best-iteration selection**: Always use last — retry carries specific `claim_id`s with missing citation checks, so the retry output should be more complete.
- **Anti-pattern risks**: Low. Single retry with specific feedback.
- **Note**: This loop runs independently per reviewer instance. A failure in reviewer-2 does not trigger retries for reviewer-1 or reviewer-3.

## Loop: Report Retry
- **Type**: Balancing
- **Stages involved**: Compile Report → [Report Completeness gate] → Compile Report
- **Purpose**: Fix compilation errors — dropped claims, count mismatches, invalid enum values
- **Established pattern**: Evaluator-optimizer
- **Termination**:
  - **Semantic**: Report Completeness gate passes (all claims accounted for, counts match, valid structure)
  - **Hard cap**: 2 retries
- **Degradation detector**: Not needed. Report compilation is near-deterministic assembly. If 2 retries fail, the issue is structural (likely a bug in how upstream artifacts feed into compilation), not stochastic.
- **Best-iteration selection**: Always use last — retry carries specific discrepancies (missing claim IDs, count mismatches) for targeted correction.
- **Anti-pattern risks**: Low. Assembly task with deterministic validation criteria.
