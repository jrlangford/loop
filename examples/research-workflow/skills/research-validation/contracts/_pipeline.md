# Pipeline Constants

## Workspace

All runtime artifacts are read from and written to `research-validation-workspace/`.

### File Layout

```
research-validation-workspace/
  source-document.md              — pipeline input (copied or symlinked)
  claim-list.md                   — output of Extract Claims
  typed-claim-list.md             — output of Classify Claims
  reviewer-1-assessment.md        — output of Verify Claims (reviewer 1)
  reviewer-2-assessment.md        — output of Verify Claims (reviewer 2)
  reviewer-3-assessment.md        — output of Verify Claims (reviewer 3)
  agreement-report.md             — output of Compare Assessments
  reconciled-assessments.md       — output of Reconcile Disagreements (loopback)
  validation-report.md            — pipeline output
```

## Shared Enums

### Claim Type
`factual | analytical | opinion`

### Verdict
`supported | contradicted | insufficient_evidence | unverifiable`

For the final report only, an additional value is permitted:
`opinion_not_verified` — used for claims classified as opinion that are not subject to factual verification.

### Confidence
`high | medium | low`

### Agreement Status
`unanimous | majority | split`

For the final report only, an additional value is permitted:
`unresolvable` — used for claims that could not reach agreement after all reconciliation rounds.

## Artifact File Naming

- Use kebab-case for all file names
- Reviewer assessments are suffixed with the reviewer number: `reviewer-1-assessment.md`, etc.
- On reconciliation rounds 2+, the agreement report and reconciled assessments overwrite their previous versions (the workspace tracks current state, not history)
