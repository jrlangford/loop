# Contract: Deduplicated Behaviour Document Set

**Produced by**: Deduplicate Behaviours (Stage 5)
**Consumed by**: Post-Pipeline Consistency Gate, pipeline output
**Workspace path**: `autodoc-workspace/deduplicated/` (behaviour files) + `autodoc-workspace/deduplication-report.md`

## Behaviour Documents

Same structure as Behaviour Document contract. After deduplication:
- Merged documents retain the richer version's content
- All traceability links from merged documents are combined into the kept document
- Identity fields are preserved exactly (ids, code_references, test_references, reference_hints combined)

## Deduplication Report

Written to `autodoc-workspace/deduplication-report.md`:

```yaml
total_extracted: <count from Stage 4>
duplicates_merged: <count of merge operations>
final_count: <count of output documents>
merges:
  - kept: <BHV-id of preserved document>
    merged_from: [<BHV-ids of documents merged into it>]
    reason: <why these were considered duplicates>
```

## Merge Rules

- **True duplicate**: same logical decision implemented in multiple code paths (e.g., validation in handler + middleware). Merge into one document, combine all traceability links.
- **Similar but distinct**: same pattern but different domain meaning (e.g., validating payment amount vs. validating shipping address). Keep both.
- When merging, preserve the richer document (more complete contracts, more scenarios) and add traceability from the thinner one.

## Validation Rules

1. `total_extracted - duplicates_merged = final_count` (arithmetic consistency)
2. Every BHV-id from the input set appears either in the output set OR in a merge record's `merged_from` list (no documents silently lost)
3. For each merge: the kept document contains all `code_references` and `test_references` from both the kept and merged documents
4. No BHV-id appears in both the output set AND a `merged_from` list (merged documents are removed, not duplicated)

## Quality Criteria (Pipeline Output)

1. Every behaviour has at least one scenario
2. Pre/postconditions are testable, or explicitly marked non-testable with rationale
3. Every behaviour traceable to at least one code reference or test
4. No duplicate behaviours covering the same decision boundary
