# Stage: Extract Claims

**Intent**: Identify individual claims and their associated citations from the source document.

**Category**: Extract — index, don't analyse. Resist adding interpretation.

## Input

Read the source document from `research-validation-workspace/source-document.md`.

Read `research-validation/contracts/claim-list.md` for the output schema.

## Steps

1. Read the source document end-to-end
2. Identify every statement that makes a verifiable assertion — factual claims, analytical claims, and opinion statements
3. For compound claims (multiple assertions in one sentence), split them into individual claims
4. For each claim, record:
   - A stable `claim_id` based on document position (e.g., `claim-3-2` for section 3, claim 2)
   - The verbatim text of the claim
   - Its location (section heading + paragraph index)
   - Any citation references associated with the claim
   - Whether it has at least one citation
5. Write the structured Claim List to `research-validation-workspace/claim-list.md`

## Sources

None — works entirely from the input document.

## Guidance

- **Extract, do not evaluate.** Do not assess whether claims are true, well-supported, or reasonable. That is downstream work.
- **Do not classify.** Do not tag claims as factual, analytical, or opinion. That is the Classify Claims stage.
- **Completeness is critical.** Missing a claim is a silent failure — everything downstream only operates on what is extracted here. When in doubt about whether a statement is a claim, include it.
- **Handle implicit claims.** Statements like "This well-known effect..." contain an implicit claim ("the effect is well-known"). Extract these.
- **Preserve verbatim text.** The `text` field must be an exact quote from the source document, not a paraphrase or summary.
- **Split compound claims.** "X is true and Y causes Z" is two claims, not one. Each should have its own `claim_id`.
