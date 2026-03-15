# Pipeline Constants — Loop Design Pipeline

## Enums

### Stage Categories
`Extract` | `Enrich` | `Transform` | `Evaluate` | `Synthesise` | `Refine` | `Emit`

### Interaction Levels
`minimal` | `per-stage` | `none`

- **minimal** (default): Human review only on critical issues — ambiguous decomposition boundaries, conflicting quality criteria, unclear domain requirements.
- **per-stage**: Human review after every stage output.
- **none**: Fully automated, no human checkpoints.

### Gate Types
`Schema` | `Metric` | `Identity` | `Semantic` | `Consensus` | `Human`

### Loop Types
`Reinforcing` | `Balancing`

### Review Severity
`ERROR` | `WARNING` | `INFO`

### Cascade Types (edit workflow)
`structural` | `content`

- **structural**: Added/removed stages, changed dependencies — deep cascade.
- **content**: Modified criteria, updated fields — shallow cascade.

### Review Verdicts
`PASS` | `PASS_WITH_WARNINGS` | `FAIL`

### Reasoning Trace Policies
`None` | `Summary` | `Full`

## Workspace Conventions

- **Workspace directory**: `loop-workspace/`
- **Stage-level artifacts** (shared across workflows):
  - `loop-workspace/transformation.md`
  - `loop-workspace/stages.md`
  - `loop-workspace/artifacts.md`
  - `loop-workspace/context-specs.md`
- **Workflow-scoped artifacts**:
  - `loop-workspace/workflows/<workflow-name>/gates.md`
  - `loop-workspace/workflows/<workflow-name>/loops.md`
  - `loop-workspace/workflows/<workflow-name>/review.md`
- **Cross-workflow review**: `loop-workspace/review.md`

## Artifact File Naming

Artifact files in the workspace use kebab-case markdown filenames. Each file follows the schema defined in its corresponding contract under `loop/contracts/`.

## Cascade Budget

Max 10 additional inference calls per review correction cycle (stages + gates + loops triggered by the cascade). Resets at the start of each review cycle.
