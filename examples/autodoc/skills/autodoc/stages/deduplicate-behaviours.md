# Stage: Deduplicate Behaviours

## Intent

Detect and merge behaviour documents covering the same decision.

## Category and Posture

**Category**: Evaluate
**Posture**: Assess against criteria. Separate observation from judgment. Evidence required for every merge decision — explain why two documents cover the same decision, not just that they look similar.

## Input

Read all behaviour documents from `autodoc-workspace/behaviours/`.

Read `autodoc/contracts/behaviour-document.md` for the input document schema.
Read `autodoc/contracts/deduplicated-behaviour-set.md` for the output schema.

## Output

Write deduplicated behaviour documents to `autodoc-workspace/deduplicated/` (one file per kept behaviour).
Write the deduplication report to `autodoc-workspace/deduplication-report.md`.

## Steps

1. Read all behaviour documents from `autodoc-workspace/behaviours/`
2. Build a comparison index: for each document, extract title, description, code references, and contract summaries
3. Group documents by proximity:
   - **Code location proximity**: documents referencing the same file, or the same function
   - **Decision similarity**: documents with similar decision summaries or overlapping contracts
4. For each group of potentially related documents, evaluate:
   - **True duplicate?** Same logical decision implemented in multiple code paths. Evidence: overlapping postconditions, same state transitions, same error handling pattern applied to the same domain concept.
   - **Similar but distinct?** Same pattern but different domain meaning. Evidence: different domain entities, different business rules, different triggers despite similar structure.
5. For true duplicates, merge:
   - Keep the richer document (more complete contracts, more scenarios)
   - Combine all traceability links: code_references, test_references, reference_hints from both documents
   - Preserve identity fields exactly — do not alter IDs, only combine lists
   - Record the merge in the deduplication report with the reason
6. For similar-but-distinct, keep both — no merge
7. Write deduplicated documents to `autodoc-workspace/deduplicated/`
8. Write the deduplication report to `autodoc-workspace/deduplication-report.md`

## Sources

None.

## Sinks

None.

## Guidance

- **Do** require explicit evidence for every merge decision — "these look similar" is not sufficient
- **Do** preserve the richer document when merging — more scenarios and more complete contracts are more valuable
- **Do** combine all traceability links from merged documents — no code references or test references should be lost
- **Do** verify arithmetic consistency: `total_extracted - duplicates_merged = final_count`
- **Do not** alter identity fields (id, code_references, test_references, reference_hints) — only combine lists
- **Do not** merge documents that cover the same pattern in different domain contexts (e.g., validation of payment amount vs. validation of shipping address)
- **Do not** merge documents just because they reference the same file — different functions in the same file are typically distinct behaviours
- **Do not** create new behaviours or modify existing behaviour content during deduplication — this stage only removes duplicates

### Merge Decision Framework

Ask these questions for each candidate pair:

1. **Same domain concept?** Do both documents describe the same business rule or system decision? (If no → keep both)
2. **Same decision type?** Do both documents have the same boundary type and similar decision summary? (If no → keep both)
3. **Overlapping postconditions?** Do the postconditions describe the same state changes? (If no → keep both)
4. **Different code paths, same outcome?** Is the duplication because the same logic appears in multiple places (e.g., handler + middleware)? (If yes → merge)

All four must point to "merge" for a true duplicate.
