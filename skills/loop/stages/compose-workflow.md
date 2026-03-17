# Stage: Compose Workflow

## Intent

Assemble the new workflow's gates and loops from reused and newly defined stages.

## Category & Posture

**Synthesise** — Combine inputs into a new whole. Reference sources, don't paraphrase. The output weaves together reused stages and new stages into a coherent workflow with gate and loop definitions.

## Input

- **Artifact**: Reuse Analysis Report (from Analyze-Reuse)
- **Contract**: Read `loop/contracts/reuse-analysis-report.md` for the schema.

- **Artifact**: New Stage Definitions (from Define-New-Stages)
- **Contract**: Read `loop/contracts/new-stage-definitions.md` for the schema.

- **Artifact**: Existing Design Inventory (from Extract-Existing-Design)
- **Contract**: Read `loop/contracts/existing-design-inventory.md` for the schema.

## Output

- **Artifact**: New Workflow Configuration
- **Write to**: Passed downstream as an in-memory artifact (not written to disk)
- **Contract**: Read `loop/contracts/new-workflow-configuration.md` for the output schema.

## Steps

1. Build the complete stage list for the new workflow: collect all stages with `reuse-as-is` verdicts from the Reuse-Analysis-Report, plus all stages from New-Stage-Definitions. This is the full set of stages participating in the workflow.
2. Order the stages following pipeline ordering principles: narrow before wide, fail-fast, cheap before expensive, emit last.
3. Define gates — process one stage boundary at a time:
   - For each boundary between consecutive stages, decide whether a gate is needed.
   - Write gate criteria as testable pass/fail statements.
   - Assign `on_fail` action: `retry`, `revise`, `halt`, or `escalate`.
   - For gates on shared stages (stages reused from existing workflows), check the Existing-Design-Inventory's workflow configurations. The new gate criteria must be compatible — they must not contradict criteria that existing workflows impose on the same stage boundary.
4. Define loops:
   - Identify where iteration is needed: stages whose output quality may require re-processing of upstream stages.
   - For each loop, specify: originating stage, return stage, trigger condition, max iterations, and loop type (`reinforcing` or `balancing`).
   - Every loop must reference stages that exist in the workflow's stage list (from step 1).
5. Assess whether the new workflow broadens the pipeline's overall purpose. If so, draft an updated scope statement for `transformation.md`. If the existing scope already covers the new workflow, set `transformation_update` to null.
6. Assemble the New-Workflow-Configuration artifact.

## Sources

None.

## Sinks

None.

## Guidance

- **Gates before loops**: Define all gates first, then all loops. Gate placement determines the quality checkpoints; loops define iteration paths between them. Mixing the two concerns risks circular reasoning.
- **Shared-stage gate compatibility is critical**: When a stage is reused across workflows, different workflows may impose different gate criteria on the same boundary. These criteria must be compatible — they can be additive (the new workflow checks something extra) but must not be contradictory (the new workflow requires X while an existing workflow requires not-X). Flag any incompatibility explicitly.
- **Channel capacity awareness**: This stage has the highest fan-in in the pipeline (3 input artifacts). Use the inventory's summary-level fields rather than mentally reconstructing full contract details. Focus on stage names, boundaries, and high-level shapes.
- **Do not load raw workspace files**: All needed information is in the three input artifacts. The raw files would be extraneous context.
- **Do not modify existing stage or artifact definitions**: This stage only produces workflow-scoped configuration (gates and loops). Shared-level changes are not in scope.
- **Do not over-gate**: A gate at every boundary creates a Toll Booth Pipeline. Place gates where quality checks genuinely reduce downstream rework risk. Not every boundary needs one.
- **Every loop needs a cap**: `max_iterations` must be a positive integer. Uncapped loops risk unbounded context accumulation (History Avalanche) and infinite cycling (Echo Chamber).
- **Transformation update is conservative**: Only propose a `transformation_update` if the new workflow materially changes what the pipeline does. Adding a workflow that exercises existing capabilities in a new order does not require a scope change.
