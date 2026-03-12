# Stage: Reconcile Disagreements

**Intent**: Re-examine disputed claims with knowledge of other reviewers' findings.

**Category**: Refine — improve based on specific feedback. Change only what the feedback addresses.

## Input

Read the Agreement Report from `research-validation-workspace/agreement-report.md` — specifically the `disputed_claims` section. Agreed claims are not relevant to this stage.

Read `research-validation/contracts/reconciled-assessments.md` for the output schema.

## Steps

1. Read only the disputed claims from the Agreement Report
2. For each disputed claim, examine all reviewers' positions and their key evidence
3. For each reviewer position on each disputed claim:
   a. Consider the other reviewers' evidence and reasoning
   b. Search for additional evidence if the existing evidence is inconclusive
   c. Either revise the verdict (with a substantive `change_rationale`) or maintain it (with explanation of why the other evidence is not persuasive)
   d. Record `position_changed: true` if the verdict changed, `false` if maintained
4. On round 3 only: any claims still without agreement after this round should be added to `unresolvable_claims` with a reason explaining why agreement cannot be reached and each reviewer's final position
5. Write the Reconciled Assessments to `research-validation-workspace/reconciled-assessments.md`

## Sources

- **Web search**: For additional research on disputed claims. May find new evidence that breaks the deadlock.

## Guidance

- **Genuinely reconsider.** Do not simply restate previous positions. Engage with the other reviewers' evidence and reasoning. If the evidence is compelling, change the verdict.
- **But do not capitulate without reason.** Maintaining a position is valid when the other evidence is weak, irrelevant, or misinterpreted. Explain why.
- **Substantive rationale required.** The `change_rationale` field must explain *why* the position changed (or didn't), not just *that* it did. "After reviewing reviewer-2's evidence from [source], the claim is better characterised as contradicted because..." is good. "Changed to match other reviewers" is not.
- **Search for new evidence.** The original reviewers may have missed relevant sources. Fresh searches with different queries can break deadlocks.
- **Only process disputed claims.** Do not re-examine agreed claims. They are settled.
- **Do not modify identity fields.** `claim_id` and `text` pass through unchanged.
- **Round 3 is final.** On round 3, any remaining disputes must be classified as unresolvable. Do not leave claims in limbo.
