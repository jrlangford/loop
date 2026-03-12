# Contract: Typed Claim List

Output of Classify Claims. Input to Verify Claims.

## Structure

```
# Typed Claim List

## Claims

### [claim_id]
- **Text**: [verbatim quote — identity field, unchanged]
- **Location**: [section heading + paragraph index — identity field, unchanged]
- **Citations**: [citation references — identity field, unchanged]
- **Has Citation**: [true | false]
- **Claim Type**: [factual | analytical | opinion]
- **Classification Rationale**: [brief summary of why this type was assigned]
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `claim_id` | string | Yes | (identity, unchanged from Claim List) |
| `text` | string | Yes | (identity, unchanged) |
| `location` | string | Yes | (identity, unchanged) |
| `citations` | string[] | Yes | (identity, unchanged) |
| `has_citation` | boolean | Yes | (identity, unchanged) |
| `claim_type` | enum | Yes | `factual \| analytical \| opinion` |
| `classification_rationale` | string | Yes | Brief summary of why this type was assigned |

## Identity Fields

`claim_id`, `text`, `location`, `citations` — unchanged from Claim List.

## Validation Rules

- Every claim from the Claim List is present (no drops)
- Every claim has a valid `claim_type` enum value
- All identity fields match the Claim List exactly

## Omitted

Nothing additional omitted from upstream.

## Reasoning Trace

Summary — `classification_rationale` field. Downstream reviewers may adjust verification approach based on claim type.

## Workspace Path

`research-validation-workspace/typed-claim-list.md`
