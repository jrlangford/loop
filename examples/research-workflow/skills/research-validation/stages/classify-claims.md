# Stage: Classify Claims

**Intent**: Categorize each claim as factual, analytical, or opinion.

**Category**: Evaluate — assess against criteria. Separate observation from judgment.

## Input

Read the Claim List from `research-validation-workspace/claim-list.md`.

Read `research-validation/contracts/typed-claim-list.md` for the output schema.

## Steps

1. Read the Claim List
2. For each claim, determine its type:
   - **Factual**: A statement about observable reality that can be verified with evidence (e.g., "The study found a 30% improvement")
   - **Analytical**: An interpretation or reasoning based on evidence (e.g., "This suggests that the approach is more effective")
   - **Opinion**: A value judgment or preference not grounded in verifiable evidence (e.g., "This is the best approach")
3. Write a brief `classification_rationale` for each claim explaining why this type was assigned
4. Preserve all identity fields unchanged (`claim_id`, `text`, `location`, `citations`)
5. Write the Typed Claim List to `research-validation-workspace/typed-claim-list.md`

## Sources

None.

## Guidance

- **Edge cases are expected.** The boundary between factual and analytical, or analytical and opinion, is genuinely ambiguous for some claims. Assign the best-fit type and note the ambiguity in the rationale.
- **Hedged claims need care.** "This suggests that..." is typically analytical. "It is widely believed that..." may be factual (about beliefs) or analytical (about the thing believed). Use rationale to explain the call.
- **Do not evaluate truth.** A factual claim can be false — "factual" means it is the kind of claim that could be verified, not that it has been.
- **Do not modify identity fields.** The `claim_id`, `text`, `location`, and `citations` fields must be exactly as they appear in the Claim List.
- **Do not drop claims.** Every claim from the input must appear in the output.
