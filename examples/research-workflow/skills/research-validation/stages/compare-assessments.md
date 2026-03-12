# Stage: Compare Assessments

**Intent**: Identify agreement and disagreement across reviewer assessments.

**Category**: Evaluate — assess against criteria. Separate observation from judgment.

## Input

Read all three reviewer assessments:
- `research-validation-workspace/reviewer-1-assessment.md`
- `research-validation-workspace/reviewer-2-assessment.md`
- `research-validation-workspace/reviewer-3-assessment.md`

On rounds 2+, also read the previous Agreement Report from `research-validation-workspace/agreement-report.md` and the Reconciled Assessments from `research-validation-workspace/reconciled-assessments.md`.

Read `research-validation/contracts/agreement-report.md` for the output schema.

## Steps

### Round 1 (initial comparison)

1. For each `claim_id`, collect all three reviewers' verdicts, confidence levels, and reasoning
2. Classify agreement:
   - **Unanimous**: All 3 reviewers assign the same verdict
   - **Majority**: 2 of 3 reviewers agree on the verdict
   - **Split**: All 3 reviewers assign different verdicts, or the disagreement is substantive enough that a majority verdict would be misleading
3. For agreed claims (unanimous or majority): consolidate evidence from agreeing reviewers, record the consensus verdict and confidence
4. For disputed claims (split): summarise what specifically the reviewers disagree on, record each reviewer's position with key evidence and condensed reasoning
5. Write the Agreement Report to `research-validation-workspace/agreement-report.md`

### Rounds 2+ (post-reconciliation comparison)

1. Read the previous Agreement Report for context on prior disagreements
2. Read the Reconciled Assessments — these contain updated positions for previously disputed claims
3. For each previously disputed claim, re-evaluate agreement using the revised positions
4. Claims that now have unanimous or majority agreement move to `agreed_claims`
5. Claims still in dispute remain in `disputed_claims` with updated `previous_disagreement_points` and `position_changed`
6. Overwrite the Agreement Report at `research-validation-workspace/agreement-report.md`

## Sources

None.

## Guidance

- **Compare, do not judge.** This stage determines whether reviewers agree, not which reviewer is right. Do not override a reviewer's verdict.
- **Majority is not always consensus.** If 2 reviewers say "supported" but the third provides strong contradicting evidence, record as `split` rather than `majority` — the dissent is substantive.
- **On rounds 2+, track changes.** Record whether positions actually changed since the last round. If no positions changed, downstream stagnation detection will terminate the loop.
- **Do not modify identity fields.** `claim_id`, `text`, and `claim_type` pass through unchanged.
- **Account for every claim.** Every `claim_id` must appear in exactly one of `agreed_claims` or `disputed_claims`.
