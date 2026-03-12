# Contract: Validation Report

Pipeline output — the final structured validation report for human researcher review.

## Structure

```
# Validation Report

## Summary

| Metric | Count |
|--------|-------|
| Total Claims | [N] |
| Verified Supported | [N] |
| Verified Contradicted | [N] |
| Insufficient Evidence | [N] |
| Unverifiable | [N] |
| Opinion (not verified) | [N] |

## Claim Results

### [claim_id]
- **Text**: [verbatim from source]
- **Location**: [where in the source document]
- **Claim Type**: [factual | analytical | opinion]
- **Verdict**: [supported | contradicted | insufficient_evidence | unverifiable | opinion_not_verified]
- **Confidence Score**: [high | medium | low]
- **Citation Valid**: [true | false | N/A]
- **Citation Notes**: [summary of citation check]
- **Agreement Status**: [unanimous | majority | split | unresolvable]
- **Key Evidence**:
  1. **Source**: [URL]
     - **Title**: [source title]
     - **Excerpt**: [relevant excerpt]
     - **Supports Claim**: [true | false]
  2. ...
- **Reconciliation Rounds**: [0 | 1 | 2 | 3]

## Unverifiable Claims

### [claim_id]
- **Text**: [verbatim from source]
- **Reason**: [why agreement could not be reached]
- **Reviewer Positions**:
  - **reviewer-1**: [final verdict and confidence]
  - **reviewer-2**: [final verdict and confidence]
  - **reviewer-3**: [final verdict and confidence]
```

## Fields

### Summary Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `total_claims` | integer | Yes | Total number of claims in the source document |
| `verified_supported` | integer | Yes | Claims with verdict `supported` |
| `verified_contradicted` | integer | Yes | Claims with verdict `contradicted` |
| `insufficient_evidence` | integer | Yes | Claims with verdict `insufficient_evidence` |
| `unverifiable` | integer | Yes | Claims with verdict `unverifiable` |
| `opinion_claims` | integer | Yes | Claims classified as opinion |

### Claim Results Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `claim_id` | string | Yes | From source extraction |
| `text` | string | Yes | Verbatim from source document |
| `location` | string | Yes | Section + paragraph in source |
| `claim_type` | enum | Yes | `factual \| analytical \| opinion` |
| `verdict` | enum | Yes | `supported \| contradicted \| insufficient_evidence \| unverifiable \| opinion_not_verified` |
| `confidence_score` | enum | Yes | `high \| medium \| low` |
| `citation_valid` | boolean \| null | Yes | Citation check result (null if no citation) |
| `citation_notes` | string | Yes | Summary of citation check |
| `agreement_status` | enum | Yes | `unanimous \| majority \| split \| unresolvable` |
| `key_evidence` | object[] | Yes | Top evidence items supporting the verdict |
| `reconciliation_rounds` | integer | Yes | How many rounds it took (0 if agreed initially) |

## Validation Rules

- `total_claims` equals the count of entries in claim results
- The set of `claim_id`s in claim results plus unverifiable claims exactly matches the set from the original Claim List
- No duplicate `claim_id` values
- Summary counts sum to `total_claims`: `verified_supported + verified_contradicted + insufficient_evidence + unverifiable + opinion_claims = total_claims`
- All enum fields use valid values

## Quality Criteria

- Every claim from the source document appears exactly once
- No claim silently dropped
- Citation checks are binary (valid or not)
- Confidence scores reflect reviewer agreement
- Unverifiable claims have explicit reasoning

## Workspace Path

`research-validation-workspace/validation-report.md`
