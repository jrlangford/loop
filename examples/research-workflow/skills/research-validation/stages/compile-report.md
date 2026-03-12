# Stage: Compile Report

**Intent**: Assemble the final validation report from all assessments.

**Category**: Synthesise — combine inputs into a new whole. Reference sources, don't paraphrase.

## Input

Read the final Agreement Report from `research-validation-workspace/agreement-report.md` (for agreed claims).

Read the final Reconciled Assessments from `research-validation-workspace/reconciled-assessments.md` (for reconciled and unresolvable claims), if it exists. If no reconciliation occurred (all claims agreed on round 1), this file will not exist.

Read `research-validation/contracts/validation-report.md` for the output schema.

## Steps

1. Collect all claims from their final sources:
   - **Agreed claims**: from the Agreement Report's `agreed_claims` section
   - **Reconciled claims**: from the Reconciled Assessments' `revised_assessments` (claims that reached agreement through reconciliation)
   - **Unresolvable claims**: from the Reconciled Assessments' `unresolvable_claims`
   - **Opinion claims**: claims with `claim_type: opinion` — assign verdict `opinion_not_verified`
2. For each claim, assemble the report entry:
   - Map agreement status: unanimous/majority from agreement, split from reconciliation, unresolvable from failed reconciliation
   - Set `reconciliation_rounds` to 0 for initially agreed claims, or the round number where agreement was reached
   - Select top evidence items for `key_evidence`
3. Calculate summary statistics:
   - Count claims by verdict category
   - Verify that counts sum to `total_claims`
4. Write the Validation Report to `research-validation-workspace/validation-report.md`

## Sources

None — pure assembly from existing artifacts.

## Guidance

- **No new judgments.** This stage assembles and formats. Do not override verdicts, change confidence scores, or add interpretations.
- **Every claim must appear.** Cross-check the claim count against the original Claim List. No claim should be silently dropped.
- **Counts must balance.** `verified_supported + verified_contradicted + insufficient_evidence + unverifiable + opinion_claims` must equal `total_claims`.
- **Preserve verbatim text.** The `text` field in each claim result must be the exact text from the source document, carried through from extraction unchanged.
- **Handle opinion claims correctly.** Claims classified as `opinion` get verdict `opinion_not_verified` — they are not subject to factual verification but must still appear in the report.
