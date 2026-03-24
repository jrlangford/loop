# Stage: Define New Stages

## Intent

Specify new stages needed to fill capability gaps identified in the reuse analysis.

## Category & Posture

**Transform** — Convert representations. Input and output are structurally different. The input is a list of capability gaps; the output is fully specified stage definitions and artifact contracts.

## Input

- **Artifact**: Reuse Analysis Report (from Analyze-Reuse)
- **Contract**: Read `loop/contracts/reuse-analysis-report.md` for the schema.

- **Artifact**: Existing Design Inventory (from Extract-Existing-Design)
- **Contract**: Read `loop/contracts/existing-design-inventory.md` for the schema.

## Output

- **Artifact**: New Stage Definitions
- **Write to**: Passed downstream as an in-memory artifact (not written to disk)
- **Contract**: Read `loop/contracts/new-stage-definitions.md` for the output schema.

## Steps

1. Read the capability gaps from the Reuse-Analysis-Report. These are the requirements that no existing stage satisfies.
2. Collect all existing stage names and artifact names from the Existing-Design-Inventory. These are the collision avoidance sets.
3. For each capability gap, define one or more new stages:
   - **Name**: Verb-noun format. Check against the collision avoidance set — no duplicates allowed.
   - **Category**: Assign from the enum (Extract, Enrich, Transform, Evaluate, Synthesise, Emit).
   - **Intent**: Single verb phrase. Apply the one-verb heuristic — if you need "and", "then", or a semicolon, split into two stages.
   - **Input**: What this stage consumes (reference to existing or new artifacts).
   - **Output**: What this stage produces.
   - **Sources**: External read dependencies, or "None".
   - **Sinks**: External write targets, or "None".
   - **fills_gap**: Reference to the `gap_id` this stage addresses.
4. For each new stage, define corresponding artifact contracts for its outputs:
   - **Name**: Check against existing artifact names for collisions.
   - **Boundary**: "[Producing Stage] -> [Consuming Stage]" format.
   - **Content**: One-sentence description of what the artifact carries.
   - **Structure**: Fields, types, and constraints.
   - **Identity fields**: Fields that must not mutate.
   - **Omitted**: What is deliberately excluded, with rationale.
   - **Validation**: Conformance checks.
   - **Reasoning trace**: None, Summary, or Full — with justification for the choice.
5. If any new stage needs a context spec, define it: germane load, extraneous load, intrinsic load guidance, history policy, isolation model.
6. Final collision check: re-scan all new names against existing names. Verify no new stage or artifact name duplicates any existing or other new name.
7. Assemble the New-Stage-Definitions artifact.

## Sources

None.

## Sinks

None.

## Guidance

- **One gap at a time**: Process each capability gap sequentially. Define the stage, then its artifact contract(s), then verify naming before moving to the next gap. This prevents cross-gap naming collisions and keeps reasoning focused.
- **Append-only constraint**: New definitions must integrate cleanly into the existing artifact dependency structure. New stages should consume existing artifacts or artifacts produced by other new stages — avoid creating orphaned artifacts with no consumer.
- **One-verb heuristic is strict**: If a gap seems to require a stage with a compound intent, split it into two stages. Each stage must do exactly one thing.
- **Do not reference reuse verdicts**: Only the capability gaps matter here. Stages marked `reuse-as-is` are not your concern — do not re-evaluate them or attempt to improve them.
- **Do not design gates or loops**: Gate positions and loop triggers are workflow-scoped concerns handled by Compose-Workflow. Define the stages and their contracts, nothing more.
- **Emit-category stages require idempotency**: If any new stage has category Emit, its artifact contract must include idempotency markers (e.g., hash, timestamp, or deduplication key) to support safe re-runs.
- **Context specs are optional**: Only define context specs for new stages with non-trivial context management needs (high fan-in, large input volume, or judgment-heavy reasoning). Simple stages can omit them.
