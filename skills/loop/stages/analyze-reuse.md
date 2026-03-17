# Stage: Analyze Reuse

## Intent

Assess each existing stage's applicability to the new workflow's requirements.

## Category & Posture

**Evaluate** — Assess against criteria. Separate observation from judgment. Evidence required. Every reuse verdict must cite specific contract shape or domain assumption evidence.

## Input

- **Artifact**: Existing Design Inventory (from Extract-Existing-Design)
- **Contract**: Read `loop/contracts/existing-design-inventory.md` for the schema.

- **Artifact**: New Workflow Description (pipeline input)
- **Contract**: Read `loop/contracts/new-workflow-description.md` for the schema.

## Output

- **Artifact**: Reuse Analysis Report
- **Write to**: Passed downstream as an in-memory artifact (not written to disk)
- **Contract**: Read `loop/contracts/reuse-analysis-report.md` for the output schema.

## Steps

1. Read the New-Workflow-Description. Internalize the workflow name, description, and key requirements.
2. For each existing stage in the Existing-Design-Inventory, produce a verdict:
   - Compare the stage's contract shape (input/output summaries) and domain assumptions against the new workflow's requirements.
   - Assign `reuse-as-is` if the stage can serve the new workflow without any modification to its contract or behavior.
   - Assign `not-applicable` if the stage's contract shape does not fit, its domain assumptions conflict, or it addresses a concern irrelevant to the new workflow.
   - Write a one-to-two-sentence rationale citing specific evidence (contract field names, domain assumptions, or requirement text).
3. After processing all stages, identify capability gaps: requirements from the New-Workflow-Description that no reused stage satisfies.
   - Assign each gap a unique `gap_id` (e.g., `gap-1`, `gap-2`).
   - Write a one-sentence description of the missing capability.
   - Link each gap to the specific `key_requirements` entries it addresses.
4. Verify completeness: every key requirement must be covered by either a reused stage or a capability gap. If any requirement is unaddressed, add a gap entry for it.
5. Assemble the Reuse-Analysis-Report artifact.

## Sources

None.

## Sinks

None.

## Guidance

- **One stage, one verdict**: Process verdicts sequentially, one existing stage at a time. Do not batch-evaluate — each stage's contract shape and domain assumptions deserve individual attention.
- **Binary verdicts only**: A stage is either `reuse-as-is` or `not-applicable`. There is no "adapt" or "partial-reuse" verdict. If a stage would need modification to serve the new workflow, it is `not-applicable` and the needed capability becomes a gap for a new stage.
- **Evidence over intuition**: Every rationale must reference specific fields from the inventory (contract summaries, domain assumptions) or specific requirements from the workflow description. Avoid vague justifications like "seems related" or "could work".
- **Do not design new stages here**: Capability gaps describe what is missing, not how to fill it. Resist the urge to sketch stage designs — that is the Define-New-Stages concern.
- **Do not load raw workspace files**: The Existing-Design-Inventory already distills the workspace contents. Loading the raw files would be extraneous context.
- **Do not reference gate/loop configurations**: Reuse analysis is about stage contract compatibility, not workflow-level orchestration. Gate and loop concerns belong to Compose-Workflow.
