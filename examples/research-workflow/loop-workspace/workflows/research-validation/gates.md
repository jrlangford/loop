# Gate Specifications

## Gate: Extraction Completeness (after Extract Claims)
- **Position**: Between Extract Claims and Classify Claims
- **Artifact checked**: Claim List
- **Type**: Schema + Semantic (source-artifact reconciliation)
- **Criteria**:
  - Schema: every claim has non-empty `text`, valid `location`, no duplicate `claim_id` values
  - Semantic: gate context includes both the Claim List and the original source document; evaluator checks whether any verifiable claims in the source were missed. Evaluator runs in a clean context — does not share context with the Extract Claims stage.
- **On failure**:
  - **Routes to**: Extract Claims
  - **Carries**: List of missed claims (section locations where uncaptured claims were identified) + the specific schema violations if any
  - **Max retries**: 2
  - **Escalation**: After 2 retries, proceed with the claims that were extracted and log a warning that extraction may be incomplete. The human researcher consuming the report should be notified of potential incompleteness.

## Gate: Citation Accuracy (after Verify Claims, per reviewer instance)
- **Position**: Between Verify Claims and Compare Assessments (applied independently to each of the 3 reviewer outputs)
- **Artifact checked**: Reviewer Assessment
- **Type**: Schema + Metric
- **Criteria**:
  - Schema: `citation_valid` is non-null for every claim where `has_citation` was true in the Typed Claim List. `verdict` and `confidence` are valid enum values. `evidence_found` entries have non-empty `source_url` and `relevant_excerpt`.
  - Metric: every `claim_id` from the Typed Claim List appears exactly once in the reviewer's `assessments[]` (no dropped claims, no duplicates)
- **On failure**:
  - **Routes to**: The specific reviewer instance that failed (not all 3)
  - **Carries**: List of `claim_id`s with missing citation checks + list of dropped/duplicated claim IDs
  - **Max retries**: 1
  - **Escalation**: After 1 retry, proceed with the reviewer's partial assessment. Claims with missing citation checks are marked `citation_valid: null` with a note. If a reviewer dropped claims entirely, those claims proceed with only 2 reviewer assessments.

## Gate: Agreement Threshold (after Compare Assessments)
- **Position**: Between Compare Assessments and Reconcile Disagreements (routing gate)
- **Artifact checked**: Agreement Report
- **Type**: Schema + Metric (routing)
- **Criteria**:
  - Schema: every `claim_id` from the input appears in exactly one of `agreed_claims` or `disputed_claims`. `agreement_status` values are valid enums. On rounds 2+, `previous_disagreement_points` is non-null for disputed claims.
  - Metric (routing, not pass/fail):
    - If `disputed_claims` is empty → route to Compile Report (skip reconciliation)
    - If `round_number` is 3 and disputes remain → mark remaining as unresolvable, route to Compile Report
    - Otherwise → route to Reconcile Disagreements
- **On failure**:
  - **Routes to**: Compare Assessments (schema failures only)
  - **Carries**: Specific schema violations (missing claim IDs, invalid enums, missing prior-round fields)
  - **Max retries**: 1
  - **Escalation**: After 1 retry, abort pipeline and report the structural failure. A malformed Agreement Report cannot be safely routed.

## Gate: Reconciliation Progress (after Reconcile Disagreements)
- **Position**: Between Reconcile Disagreements and Compare Assessments (loopback gate)
- **Artifact checked**: Reconciled Assessments
- **Type**: Metric + Identity
- **Criteria**:
  - Metric (stagnation detection): at least one `position_changed: true` across all `revised_assessments[]`. If no positions changed, the loop has stagnated — further rounds will not produce agreement.
  - Identity: `claim_id` and `text` fields match the values from the Agreement Report's `disputed_claims`. No claim identity drift across reconciliation rounds.
- **On failure (stagnation)**:
  - **Routes to**: Compile Report (bypass remaining reconciliation rounds)
  - **Carries**: All remaining disputed claims are reclassified as unresolvable with reason "reviewer positions unchanged after reconciliation round [N]"
  - **Max retries**: 0 (stagnation is a termination signal, not a retryable failure)
  - **Escalation**: N/A — stagnation exits the loop gracefully
- **On failure (identity)**:
  - **Routes to**: Reconcile Disagreements
  - **Carries**: Specific identity field mismatches
  - **Max retries**: 1
  - **Escalation**: Abort pipeline — identity drift in the feedback loop indicates a structural problem

## Gate: Report Completeness (after Compile Report)
- **Position**: Between Compile Report and pipeline output
- **Artifact checked**: Validation Report
- **Type**: Schema + Metric
- **Criteria**:
  - Schema: report has valid structure — `summary` fields present, all `claim_results[]` entries have valid enum values for `verdict`, `confidence_score`, `claim_type`, `agreement_status`
  - Metric: `total_claims` in summary equals `len(claim_results[])`. The set of `claim_id`s in `claim_results[]` plus `unverifiable_claims[]` exactly matches the set from the original Claim List (no silent drops, no duplicates). Summary counts (`verified_supported` + `verified_contradicted` + `insufficient_evidence` + `unverifiable` + `opinion_claims`) equals `total_claims`.
- **On failure**:
  - **Routes to**: Compile Report
  - **Carries**: Specific discrepancies — missing claim IDs, count mismatches, invalid enum values
  - **Max retries**: 2
  - **Escalation**: After 2 retries, present the report as-is with a prominent warning about potential incompleteness. The human researcher must be informed.

## Ungated Boundaries

- **Extract Claims → Classify Claims**: Classification is best-effort. Misclassified claims still get verified — the downstream impact is that a reviewer may adjust their approach slightly based on claim type, but the verification itself is not skipped. The cost of a semantic gate here (evaluating classification quality) exceeds the damage of occasional misclassification.
