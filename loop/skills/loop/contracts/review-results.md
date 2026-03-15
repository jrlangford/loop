# Contract: Review Results

**Boundary**: Review Design → (pipeline output)
**Workspace path**: `loop-workspace/workflows/<workflow>/review.md` (per-workflow) or `loop-workspace/review.md` (cross-workflow)

## Content

Anti-pattern findings, consistency checks, and recommendations.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `findings[]` | array | Issues discovered during review |
| `findings[].severity` | enum | ERROR, WARNING, INFO |
| `findings[].anti_pattern` | string | Which anti-pattern or consistency issue (if applicable) |
| `findings[].location` | string | Which artifact and section |
| `findings[].description` | string | What's wrong |
| `findings[].recommendation` | string | What to fix and which phase to re-run |
| `consistency_checks` | structured | Referential integrity results, completeness results |
| `edit_findings` | structured (optional) | Present only in edit workflow |
| `edit_findings.missed_staleness[]` | array | Artifacts that should have been flagged stale but weren't, with evidence of inconsistency |
| `edit_findings.partial_execution_inconsistencies[]` | array | Mismatches between re-executed and non-re-executed artifacts, with the specific conflict described |
| `verdict` | enum | PASS, PASS_WITH_WARNINGS, FAIL |

## Identity Fields

None — review results are ephemeral assessments.

## Omitted

The artifacts themselves — review references them by location, not by copying.

## Validation

- Every ERROR finding has a recommendation
- Verdict is FAIL if any ERROR findings exist

## Reasoning Trace

Full — review reasoning must be transparent for the designer to evaluate and act on findings.
