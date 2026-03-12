# Contract: Reviewer Assessment

Output of Verify Claims (one per reviewer instance). Input to Compare Assessments.

Three instances of this artifact are produced — one per parallel reviewer (`reviewer-1`, `reviewer-2`, `reviewer-3`).

## Structure

```
# Reviewer Assessment

**Reviewer ID**: [reviewer-1 | reviewer-2 | reviewer-3]

## Assessments

### [claim_id]
- **Text**: [verbatim — identity field, unchanged]
- **Claim Type**: [factual | analytical | opinion — identity field, unchanged]
- **Citation Valid**: [true | false | N/A]
- **Citation Notes**: [what the citation actually says vs. what the claim states]
- **Verdict**: [supported | contradicted | insufficient_evidence | unverifiable]
- **Confidence**: [high | medium | low]
- **Evidence Found**:
  1. **Source**: [URL]
     - **Title**: [source title]
     - **Excerpt**: [verbatim quote or close paraphrase]
     - **Supports Claim**: [true | false]
  2. ...
- **Reasoning**: [rationale for verdict and confidence]
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reviewer_id` | string | Yes | `reviewer-1`, `reviewer-2`, or `reviewer-3` |
| `claim_id` | string | Yes | (identity, unchanged) |
| `text` | string | Yes | (identity, unchanged) |
| `claim_type` | enum | Yes | (identity, unchanged from Typed Claim List) |
| `citation_valid` | boolean \| null | Yes | Whether cited sources support the claim. Null only if claim has no citation. |
| `citation_notes` | string | Yes | What the citation says vs. what the claim states. Empty if no citation. |
| `verdict` | enum | Yes | `supported \| contradicted \| insufficient_evidence \| unverifiable` |
| `confidence` | enum | Yes | `high \| medium \| low` |
| `evidence_found` | object[] | Yes | List of evidence items (may be empty for unverifiable claims) |
| `evidence_found[].source_url` | string | Yes | URL of the source consulted |
| `evidence_found[].source_title` | string | Yes | Title or description of the source |
| `evidence_found[].relevant_excerpt` | string | Yes | Verbatim quote or close paraphrase from the source |
| `evidence_found[].supports_claim` | boolean | Yes | Whether this evidence supports or contradicts the claim |
| `reasoning` | string | Yes | Reviewer's rationale for verdict and confidence |

## Identity Fields

`claim_id`, `text`, `claim_type` — unchanged from Typed Claim List.

## Validation Rules

- Every `claim_id` from the Typed Claim List appears exactly once
- `verdict` and `confidence` are valid enum values
- `citation_valid` is non-null for claims where `has_citation` was true in the Typed Claim List
- `evidence_found` entries have non-empty `source_url` and `relevant_excerpt`

## Omitted

Classification rationale (already consumed by reviewer), raw search results, failed search queries.

## Reasoning Trace

Summary — `reasoning` field per claim. The Compare stage needs to understand *why* reviewers reached their verdicts.

## Workspace Path

`research-validation-workspace/reviewer-[N]-assessment.md` (where N is 1, 2, or 3)
