# Contract: Reconciled Assessments

Output of Reconcile Disagreements. Loopback input to Compare Assessments.

Contains updated assessments for disputed claims only, after re-examination with knowledge of other reviewers' findings.

## Structure

```
# Reconciled Assessments

**Round Number**: [1 | 2 | 3]

## Revised Assessments

### [claim_id] — [reviewer_id]
- **Text**: [verbatim — identity field, unchanged]
- **Previous Verdict**: [what the reviewer said before]
- **Revised Verdict**: [supported | contradicted | insufficient_evidence | unverifiable]
- **Revised Confidence**: [high | medium | low]
- **Position Changed**: [true | false]
- **Change Rationale**: [why the position changed, or why it was maintained]
- **New Evidence**:
  1. **Source**: [URL]
     - **Title**: [source title]
     - **Excerpt**: [relevant excerpt]
     - **Supports Claim**: [true | false]
  2. ...

## Unresolvable Claims

<!-- Only populated on round 3 -->

### [claim_id]
- **Text**: [verbatim — identity field, unchanged]
- **Reason**: [why agreement could not be reached]
- **Final Positions**:
  - **reviewer-1**: [final verdict and confidence]
  - **reviewer-2**: [final verdict and confidence]
  - **reviewer-3**: [final verdict and confidence]
```

## Fields

### Revised Assessments Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `round_number` | integer | Yes | Which reconciliation round (1, 2, or 3) |
| `claim_id` | string | Yes | (identity, unchanged) |
| `text` | string | Yes | (identity, unchanged) |
| `reviewer_id` | string | Yes | Which reviewer's position this represents |
| `previous_verdict` | enum | Yes | What the reviewer said before |
| `revised_verdict` | enum | Yes | `supported \| contradicted \| insufficient_evidence \| unverifiable` |
| `revised_confidence` | enum | Yes | `high \| medium \| low` |
| `position_changed` | boolean | Yes | Whether this reviewer changed their position |
| `change_rationale` | string | Yes | Why the position changed or was maintained |
| `new_evidence` | object[] | Yes | Additional evidence found in this round (may be empty) |

### Unresolvable Claims Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `claim_id` | string | Yes | (identity, unchanged) |
| `text` | string | Yes | (identity, unchanged) |
| `reason` | string | Yes | Why agreement could not be reached |
| `final_positions` | object[] | Yes | Each reviewer's final position |

## Identity Fields

`claim_id`, `text` — unchanged from upstream.

## Validation Rules

- Every `claim_id` from the Agreement Report's `disputed_claims` appears in either `revised_assessments` or `unresolvable_claims`
- `round_number` matches the expected round
- `unresolvable_claims` is only populated on round 3
- `previous_verdict` matches the reviewer's verdict from the prior round

## Omitted

Agreed claims (not re-examined), full search histories.

## Reasoning Trace

Summary — `change_rationale` field. The Compare stage needs to know whether positions genuinely shifted or were merely restated.

## Workspace Path

`research-validation-workspace/reconciled-assessments.md`
