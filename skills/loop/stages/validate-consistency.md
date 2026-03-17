# Stage: Validate Consistency

## Intent

Verify cross-workflow consistency across all workflows including the new one.

## Category & Posture

**Evaluate** — Assess against criteria. Separate observation from judgment. Evidence required. Each check must produce a clear pass/fail result with supporting details.

## Input

- **Artifact**: Existing Design Inventory (from Extract-Existing-Design)
- **Contract**: Read `loop/contracts/existing-design-inventory.md` for the schema.

- **Artifact**: New Stage Definitions (from Define-New-Stages)
- **Contract**: Read `loop/contracts/new-stage-definitions.md` for the schema.

- **Artifact**: New Workflow Configuration (from Compose-Workflow)
- **Contract**: Read `loop/contracts/new-workflow-configuration.md` for the schema.

## Output

- **Artifact**: Validation Report
- **Write to**: Passed downstream as an in-memory artifact (not written to disk)
- **Contract**: Read `loop/contracts/validation-report.md` for the output schema.

## Steps

1. **Naming collision checks** (scope: `naming`):
   - Verify no new stage name in New-Stage-Definitions collides with any existing stage name in Existing-Design-Inventory.
   - Verify no new artifact name collides with any existing artifact name.
   - Verify the new workflow name does not collide with any existing workflow name.
   - Record pass/fail for each check with details.

2. **Reference integrity checks** (scope: `reference-integrity`):
   - Verify every stage referenced in New-Workflow-Configuration gates (in `position` fields) exists in either the existing inventory or new stage definitions.
   - Verify every stage referenced in New-Workflow-Configuration loops (`from_stage`, `to_stage`) exists in either the existing inventory or new stage definitions.
   - Verify every `fills_gap` reference in New-Stage-Definitions resolves to a valid `gap_id` in the Reuse-Analysis-Report (if available) or is otherwise traceable.
   - Verify every new artifact's boundary references valid stage names.
   - Record pass/fail for each check.

3. **Gate compatibility checks** (scope: `gate-compatibility`):
   - Identify shared stages: stages that appear in both the new workflow's gate/loop references and in existing workflow `stage_references`.
   - For each shared stage, read the existing workflow gate criteria from source files and compare against the new workflow's gate criteria.
   - Flag contradictions: criteria that require mutually exclusive conditions on the same boundary.
   - Additive criteria (new workflow checks something extra) are acceptable — record as pass with a note.
   - Record pass/fail for each shared-stage comparison.

4. **Context spec compatibility checks** (scope: `context-spec-compatibility`):
   - If new context specs are defined in New-Stage-Definitions, verify they do not conflict with existing context specs (e.g., contradictory isolation models for the same stage).
   - Verify that new stages with high fan-in have context specs that address channel capacity risks.
   - Record pass/fail.

5. Assemble the Validation-Report artifact:
   - Set `overall_status` to `pass` if all checks pass; `fail` if any check fails.
   - For each failure, record: check name, severity (`error` or `warning`), description, affected elements, and a one-sentence suggested fix.

## Sources

- Existing `loop-workspace/` workflow directories (for full-fidelity gate criteria comparison in step 3)

## Sinks

None.

## Guidance

- **Process checks sequentially by scope**: Run naming checks first, then reference integrity, then gate compatibility, then context spec compatibility. This ordering lets you short-circuit: if naming collisions exist, reference integrity results may be unreliable.
- **Highest context load in the pipeline**: This stage consumes 3 input artifacts plus source file access. Mitigate by focusing on summary-level fields from the inventory for naming and reference checks. Only access raw source files for gate compatibility checks where full criteria text is needed.
- **Severity classification**: Naming collisions and dangling references are `error` severity — they prevent correct emit. Gate compatibility warnings and missing context specs for low-fan-in stages are `warning` severity — they indicate risk but do not block the pipeline.
- **Do not fix inconsistencies**: This stage detects and reports. It does not modify any artifact. Corrections are an upstream concern driven by feedback loops.
- **Do not load the New-Workflow-Description**: Requirements have already been materialized into the other artifacts. The raw description is extraneous context at this point.
- **Do not load the Reuse-Analysis-Report unless needed for reference integrity**: The reuse verdicts are already reflected in the stage lists and workflow configuration. Only reference the report if a `fills_gap` field needs validation.
- **Actionable suggested fixes**: Every inconsistency must include a specific, actionable remediation — not "fix the naming collision" but "rename new stage X to Y to avoid collision with existing stage X".
