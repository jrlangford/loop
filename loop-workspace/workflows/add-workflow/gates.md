# Gate Specifications

## Reasoning Trace

Gate placement follows failure mode analysis: gates are placed where validation failures would cascade downstream and where late detection is costly. Pipeline input artifacts receive schema gates to catch malformed inputs early. The Reuse-Analysis-Report boundary gets the heaviest gating because incorrect reuse decisions propagate through the entire remainder of the pipeline. The Validation-Report boundary enforces a hard stop on inconsistent designs before filesystem writes. Simple pass-through boundaries where the next stage inherently validates its input are left ungated with documented rationale.

## Gates

### 1. Pipeline-Input-Directory-Gate

- **Position**: Between [Pipeline Input] and [Extract-Existing-Design]
- **Artifact Checked**: Pipeline-Input-Directory
- **Type**: Schema
- **Criteria**: `workspace_path` field is present and non-empty. The referenced path exists and contains at minimum `stages.md`, `artifacts.md`, `context-specs.md`, and `transformation.md`.
- **On Failure**:
  - **routes_to**: Pipeline Input (user must supply a valid workspace path)
  - **carries**: "Missing required workspace files. Expected: stages.md, artifacts.md, context-specs.md, transformation.md at the specified workspace_path. Found: [list of files actually present]. Please provide a path to a fully populated loop-workspace directory."
  - **max_retries**: 2
  - **escalation**: Abort pipeline — cannot proceed without a valid existing workspace.

### 2. New-Workflow-Description-Gate

- **Position**: Between [Pipeline Input] and [Analyze-Reuse]
- **Artifact Checked**: New-Workflow-Description
- **Type**: Schema
- **Criteria**: `workflow_name` is non-empty kebab-case. `description` is non-empty. `key_requirements` is a non-empty array with at least one entry. `workflow_name` does not collide with any existing workflow name in the workspace.
- **On Failure**:
  - **routes_to**: Pipeline Input (user must supply a valid workflow description)
  - **carries**: "New-Workflow-Description validation failed. Issues: [specific field failures, e.g., 'workflow_name is empty', 'key_requirements array has zero entries', 'workflow_name collides with existing workflow: <name>']. Please provide a corrected workflow description."
  - **max_retries**: 2
  - **escalation**: Abort pipeline — cannot proceed without a valid workflow description.

### 3. Existing-Design-Inventory-Gate

- **Position**: Between [Extract-Existing-Design] and [Analyze-Reuse]
- **Artifact Checked**: Existing-Design-Inventory
- **Type**: Schema + Metric
- **Criteria**:
  - Schema: `stages[]` array is present with at least one entry. Each entry has `name`, `category`, `intent`, `input_contract_summary`, `output_contract_summary`, and `domain_assumptions`. `artifacts[]` array is present. `context_specs[]` array is present. `workflows[]` array is present (may be empty).
  - Metric: Every `stages[].name` is unique. Every `artifacts[].name` is unique. Every `workflows[].name` is unique. All `workflows[].stage_references` entries resolve to entries in `stages[].name`.
- **On Failure**:
  - **routes_to**: Extract-Existing-Design
  - **carries**: "Existing-Design-Inventory is structurally incomplete or inconsistent. Issues: [specific failures, e.g., 'stage entry at index 2 missing domain_assumptions field', 'duplicate stage name: Extract-Entities', 'workflow design references stage Foo which is not in stages[]']. Re-extract from the workspace with complete field coverage."
  - **max_retries**: 2
  - **escalation**: Present to user — extraction failure may indicate a corrupted or non-standard workspace that requires manual inspection.

### 4. Reuse-Analysis-Report-Gate

- **Position**: Between [Analyze-Reuse] and [Define-New-Stages]
- **Artifact Checked**: Reuse-Analysis-Report
- **Type**: Schema + Semantic + Human
- **Criteria**:
  - Schema: `workflow_name` matches the input New-Workflow-Description's `workflow_name`. `stage_verdicts[]` has exactly one entry per existing stage. Each verdict has `stage_name`, `verdict` (one of `reuse-as-is`, `not-applicable`), and non-empty `rationale`. `capability_gaps[]` entries each have unique `gap_id`, non-empty `description`, and non-empty `requirement_refs`. At least one entry exists across reused stages or capability gaps.
  - Semantic (run in clean context with only the Reuse-Analysis-Report, the Existing-Design-Inventory, and the New-Workflow-Description): Each `reuse-as-is` verdict is justified — the existing stage's input/output contract shapes and domain assumptions are compatible with the new workflow's requirements. Each `not-applicable` verdict correctly identifies incompatibility. The capability gaps collectively cover all key requirements not addressed by reused stages. No requirement from `key_requirements` is left unaddressed by either a reused stage or a capability gap.
  - Human: Present the reuse analysis report to the user for review. The user validates that reuse verdicts align with their domain knowledge and that capability gaps accurately reflect the new workflow's needs. Run after Schema and Semantic checks pass — the user sees a pre-validated report rather than a structurally broken one.
- **On Failure**:
  - **routes_to**: Analyze-Reuse
  - **carries**: "Reuse analysis failed validation. Issues: [specific failures, e.g., 'stage Foo marked reuse-as-is but its domain_assumptions include legal-specific logic incompatible with the medical workflow', 'key_requirement 3 (entity extraction) is not covered by any reused stage or capability gap', 'stage_verdicts missing entry for stage Bar']. Re-analyze with attention to the flagged issues."
  - **max_retries**: 2
  - **escalation**: Present to user — reuse decisions are judgment calls that may require human domain knowledge.

### 5. New-Stage-Definitions-Gate

- **Position**: Between [Define-New-Stages] and [Compose-Workflow]
- **Artifact Checked**: New-Stage-Definitions
- **Type**: Schema + Metric
- **Criteria**:
  - Schema: Every `new_stages[]` entry has `name` (verb-noun format), `category` (valid enum), `intent` (single verb phrase, no conjunctions), `input`, `output`, `sources`, `sinks`, and `fills_gap`. Every `new_artifact_contracts[]` entry has `name`, `boundary`, `content`, `structure` (at least one field), `identity_fields`, `omitted`, `validation`, and `reasoning_trace`.
  - Metric: No `new_stages[].name` collides with any existing stage name. No `new_artifact_contracts[].name` collides with any existing artifact name. Every `fills_gap` references a valid `gap_id` from the Reuse-Analysis-Report. Every Emit-category stage's artifact contracts include idempotency markers.
- **On Failure**:
  - **routes_to**: Define-New-Stages
  - **carries**: "New stage definitions failed validation. Issues: [specific failures, e.g., 'new stage name Analyze-Reuse collides with existing stage', 'stage Foo intent contains conjunction (and)', 'fills_gap references gap-99 which does not exist in the reuse analysis', 'Emit-category stage Bar artifact missing idempotency markers']. Revise definitions to resolve the listed issues."
  - **max_retries**: 2
  - **escalation**: Present to user — naming and structural decisions may need human guidance.

### 6. New-Workflow-Configuration-Gate

- **Position**: Between [Compose-Workflow] and [Validate-Consistency]
- **Artifact Checked**: New-Workflow-Configuration
- **Type**: Schema + Semantic
- **Criteria**:
  - Schema: `workflow_name` matches expected name. `gates[]` entries each have `name`, `position`, `criteria` (non-empty array), and `on_fail` (valid enum). `loops[]` entries each have `name`, `from_stage`, `to_stage`, `trigger`, `max_iterations` (positive integer), and `loop_type` (valid enum). No gate name collides with gates in existing workflows.
  - Semantic (run in clean context with the New-Workflow-Configuration, Existing-Design-Inventory, and New-Stage-Definitions): Every `gates[].position` and `loops[].from_stage` / `loops[].to_stage` references a stage that exists in either the existing inventory or new stage definitions. Gate criteria are testable and non-trivial. Loop triggers describe observable conditions. No reinforcing loop lacks a balancing mechanism or iteration cap.
- **On Failure**:
  - **routes_to**: Compose-Workflow
  - **carries**: "Workflow configuration failed validation. Issues: [specific failures, e.g., 'gate position references non-existent stage Baz', 'loop from_stage Foo does not exist in any stage list', 'gate name Quality-Check collides with existing workflow gate', 'reinforcing loop Refine-Loop lacks a balancing mechanism']. Revise the workflow configuration to resolve the listed issues."
  - **max_retries**: 2
  - **escalation**: Present to user — workflow composition decisions may require human input on gate/loop strategy.

### 7. Validation-Report-Gate

- **Position**: Between [Validate-Consistency] and [orchestrator Write Phase]
- **Artifact Checked**: Validation-Report
- **Type**: Schema + Metric + Human
- **Criteria**:
  - Schema: `overall_status` is present (one of `pass`, `fail`). `checks_performed[]` is non-empty. Each check has `check_name`, `scope` (valid enum), `status` (valid enum), and `details`. If `overall_status` is `fail`, `inconsistencies[]` is non-empty with each entry having `check_name`, `severity`, `description`, `affected_elements`, and `suggested_fix`.
  - Metric: `overall_status` is `pass`. (If `fail`, this gate blocks the Write Phase.) `overall_status` is `fail` if and only if at least one `checks_performed[].status` is `fail`. Every `inconsistencies[].check_name` references a check in `checks_performed`.
  - Human: After Schema and Metric checks pass, present the validation report and a summary of pending writes to the user. The user confirms that the changes are correct before the orchestrator writes files. This gate absorbs the irreversible-side-effects concern that would otherwise require a post-write gate.
- **On Failure**:
  - **routes_to**: Compose-Workflow (if inconsistencies involve gates/loops) or Define-New-Stages (if inconsistencies involve naming collisions or artifact structure)
  - **carries**: "Cross-workflow validation failed. Inconsistencies found: [list each inconsistency with its severity, description, affected elements, and suggested fix]. Route to the appropriate upstream stage based on the nature of the inconsistency."
  - **max_retries**: 3
  - **escalation**: Present to user — persistent cross-workflow inconsistencies require human design judgment to resolve.

## Ungated Boundaries

_(No ungated boundaries — every artifact boundary has a gate placed. Each boundary carries validation rules where failure would cascade downstream, and the cost of gating is low relative to the cost of late detection in this design pipeline.)_

## Human Gate Candidates

### Candidate 1: Reuse-Analysis-Report Boundary

- **Boundary**: [Analyze-Reuse] → [Define-New-Stages]
- **Risk Dimensions**: Domain authority gap, Subjective quality criteria
- **Rationale**: Reuse analysis is explicitly identified as "the core judgment call" in the stage decomposition. The pipeline lacks an authoritative source for determining whether an existing stage's domain assumptions are compatible with a new workflow's requirements — this depends on domain knowledge the LLM may not have. Additionally, the reuse verdicts involve subjective assessment of "applicability" that cannot be reliably machine-evaluated. The transformation.md gap analysis flags this as a point where "single-pass extraction is unreliable."
- **Disposition**: promoted

### Candidate 2: Validation-Report Boundary (Write Phase)

- **Boundary**: [Validate-Consistency] → [orchestrator Write Phase]
- **Risk Dimensions**: Irreversible side effects
- **Rationale**: The Write Phase appends to shared artifacts (`stages.md`, `artifacts.md`, `context-specs.md`) and creates new workflow files. These writes modify the authoritative design artifacts. While git provides rollback, incorrect appends could corrupt the existing pipeline design. The Human check on Gate 7 confirms pending writes before execution.
- **Disposition**: promoted (absorbed into Gate 7)

### Candidate 3: New-Workflow-Configuration Boundary

- **Boundary**: [Compose-Workflow] → [Validate-Consistency]
- **Risk Dimensions**: Error reinforcement risk
- **Rationale**: The transformation.md complexity signals flag moderate error reinforcement risk: "If the reuse analysis incorrectly classifies a stage as reusable when it is not, downstream stages will build on a flawed foundation." By the time the workflow is composed, any upstream reuse errors have compounded through Define-New-Stages into the gate/loop definitions. A human review here can catch misalignments before the validation stage, which "cannot catch all semantic mismatches" per the gap analysis.
- **Disposition**: documented
