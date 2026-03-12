# Contract: Claim List

Output of Extract Claims. Input to Classify Claims.

## Structure

```
# Claim List

## Claims

### [claim_id]
- **Text**: [verbatim quote of the claim from the source]
- **Location**: [section heading + paragraph index]
- **Citations**: [list of citation references, or "None"]
- **Has Citation**: [true | false]
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `claim_id` | string | Yes | Stable identifier based on document position (e.g., `claim-3-2` for section 3, claim 2) |
| `text` | string | Yes | Verbatim quote of the claim from the source document |
| `location` | string | Yes | Section heading + paragraph index in the source document |
| `citations` | string[] | Yes | List of citation references associated with this claim (empty list if none) |
| `has_citation` | boolean | Yes | Whether the claim has at least one associated citation |

## Identity Fields

`claim_id`, `text`, `location`, `citations` — these must pass through all downstream stages unchanged.

## Validation Rules

- Every claim has a non-empty `text`
- Every claim has a valid `location` that maps back to the source document
- No duplicate `claim_id` values
- `has_citation` is consistent with `citations` (true iff citations is non-empty)

## Omitted

Surrounding prose, formatting, non-claim sentences, document metadata.

## Reasoning Trace

None — extraction is structural, not interpretive.

## Workspace Path

`research-validation-workspace/claim-list.md`
