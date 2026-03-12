# Contract: Agreement Report

Output of Compare Assessments. Input to Reconcile Disagreements (for disputed claims) and Compile Report (for agreed claims).

## Structure

```
# Agreement Report

**Round Number**: [1 | 2 | 3]

## Agreed Claims

### [claim_id]
- **Text**: [verbatim — identity field, unchanged]
- **Claim Type**: [factual | analytical | opinion — identity field, unchanged]
- **Agreement Status**: [unanimous | majority]
- **Consensus Verdict**: [supported | contradicted | insufficient_evidence | unverifiable]
- **Consensus Confidence**: [high | medium | low]
- **Citation Valid**: [true | false | N/A]
- **Consolidated Evidence**:
  1. **Source**: [URL]
     - **Title**: [source title]
     - **Excerpt**: [relevant excerpt]
     - **Supports Claim**: [true | false]
  2. ...

## Disputed Claims

### [claim_id]
- **Text**: [verbatim — identity field, unchanged]
- **Claim Type**: [factual | analytical | opinion — identity field, unchanged]
- **Agreement Status**: split
- **Disagreement Summary**: [what specifically the reviewers disagree on]
- **Reviewer Positions**:
  - **reviewer-1**: Verdict: [verdict], Confidence: [confidence]
    - Key Evidence: [most relevant evidence cited]
    - Reasoning: [condensed rationale]
  - **reviewer-2**: ...
  - **reviewer-3**: ...
- **Previous Disagreement Points**: [points from prior round, or "N/A" on round 1]
- **Position Changed**: [true | false | N/A on round 1]
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `round_number` | integer | Yes | Which comparison round (1 for initial, 2-3 for post-reconciliation) |

### Agreed Claims Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `claim_id` | string | Yes | (identity, unchanged) |
| `text` | string | Yes | (identity, unchanged) |
| `claim_type` | enum | Yes | (identity, unchanged) |
| `agreement_status` | enum | Yes | `unanimous \| majority` |
| `consensus_verdict` | enum | Yes | `supported \| contradicted \| insufficient_evidence \| unverifiable` |
| `consensus_confidence` | enum | Yes | `high \| medium \| low` |
| `citation_valid` | boolean \| null | Yes | Agreed citation check result |
| `consolidated_evidence` | object[] | Yes | Merged evidence from agreeing reviewers |

### Disputed Claims Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `claim_id` | string | Yes | (identity, unchanged) |
| `text` | string | Yes | (identity, unchanged) |
| `claim_type` | enum | Yes | (identity, unchanged) |
| `agreement_status` | enum | Yes | Always `split` |
| `disagreement_summary` | string | Yes | What specifically reviewers disagree on |
| `reviewer_positions` | object[] | Yes | Each reviewer's position with key evidence and reasoning |
| `previous_disagreement_points` | string[] \| null | Yes | Points from prior round. Null on round 1. |
| `position_changed` | boolean \| null | Yes | Whether any reviewer changed position since last round. Null on round 1. |

## Identity Fields

`claim_id`, `text`, `claim_type` — unchanged from upstream.

## Validation Rules

- Every `claim_id` from the input appears in exactly one of `agreed_claims` or `disputed_claims`
- `agreement_status` values are valid enums
- On rounds 2+, `previous_disagreement_points` is non-null for disputed claims
- `round_number` matches the expected round

## Omitted

Full evidence lists for agreed claims (consolidated to key items), raw reviewer assessments (summarised into positions).

## Reasoning Trace

None — the structure itself (agreed vs. disputed, with positions) is the trace.

## Workspace Path

`research-validation-workspace/agreement-report.md`
