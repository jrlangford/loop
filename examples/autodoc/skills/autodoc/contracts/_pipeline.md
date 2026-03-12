# Pipeline Constants

## Workspace

All runtime artifacts are read from and written to `autodoc-workspace/` in the current working directory.

### Workspace Layout

```
autodoc-workspace/
  analysis-request.md          # Pipeline input (user-provided or orchestrator-generated)
  reference-index.md           # Stage 1 output
  structural-map.md            # Stage 2 output
  boundary-list.md             # Stage 3 output
  behaviours/                  # Stage 4 output (one file per boundary)
    BHV-<hex>.md
  deduplicated/                # Stage 5 output (final behaviour documents)
    BHV-<hex>.md
  deduplication-report.md      # Stage 5 output (merge report)
```

## Shared Vocabularies

### Boundary Types

One of: `conditional_branch` | `error_handling` | `validation_gate` | `state_transition` | `integration_point` | `config_driven`

### Behaviour Categories

- `specified` — traceable to a provided reference document
- `implicit` — assumed by convention but never formally specified
- `undefined` — cannot be confidently classified

Note: `emergent` (cross-component interaction) is intentionally omitted — too unreliable for static analysis extraction.

### Behaviour Source

Always `implementation` in this pipeline (reverse-engineered from code).

### Behaviour Status

Always `draft` on first extraction.

### Behaviour Significance

One of: `critical` | `important` | `minor`

### Behaviour ID Format

`BHV-<4-6 hex chars>`, non-sequential. Generate with: `printf 'BHV-%04x' $((RANDOM % 65536))`

### Reference Source Types

One of: `file` | `url` | `notion`

## Artifact File Naming

- Contract files: kebab-cased artifact name (e.g., `reference-index.md`)
- Stage files: kebab-cased stage name (e.g., `gather-references.md`)
- Workspace behaviour files: named by behaviour ID (e.g., `BHV-a3f7.md`)
