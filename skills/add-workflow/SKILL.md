---
description: Add a new workflow to an existing Loop pipeline design. Analyzes stage reuse, incrementally extends shared artifacts, defines workflow-specific gates and loops, and validates cross-workflow consistency. Use when extending a pipeline with a new workflow rather than creating a new pipeline from scratch.
---

# Loop: Add Workflow Pipeline

Orchestrate the add-workflow pipeline. Take an existing Loop pipeline workspace and a new workflow description, then extend the design by sequencing stages 1-5, enforcing gates, managing feedback loops, and writing the results directly to the workspace. Each stage runs in an isolated subagent. The orchestrator's job is sequencing, gate checking, loop management, progress reporting, and final file writes.

## Subagent Types

This skill uses two custom agents distributed with the Loop plugin:

- **`loop-stage-runner`** — Executes pipeline stages in isolated context. Has Read, Write, Edit, Glob, Grep tools. Use for all stage delegations (Phases 1-5).
- **`loop-gate-checker`** — Evaluates semantic gates in clean context. Has Read, Glob, Grep tools (read-only). Use for all semantic gate checks.

When delegating to a subagent, always specify the `subagent_type` parameter in the Agent tool call.

## Pipeline Overview

```
[Extract-Existing-Design] → (G3: Schema+Metric) → [Analyze-Reuse] → (G4: Schema+Semantic+Human) →
  [Define-New-Stages] → (G5: Schema+Metric) → [Compose-Workflow] → (G6: Schema+Semantic) →
    [Validate-Consistency] → (G7: Schema+Metric+Human) → [Orchestrator writes files]

Loops (all Balancing):
  Extraction-Correction:         S1 ← G3 (cap 2)
  Reuse-Analysis-Correction:     S2 ← G4 (cap 2)
  Stage-Definition-Correction:   S3 ← G5 (cap 2)
  Workflow-Config-Correction:    S4 ← G6 (cap 2)
  Validation-Correction:         S5 → G7 → S3 or S4 (cap 3)
```

## Inputs

Collect from the user before starting:

- **Existing workspace path**: Path to the populated `loop-workspace/` directory. Default: `loop-workspace/`.
- **New workflow description**: Collect three fields:
  - `workflow_name`: Kebab-case identifier (e.g., `code-review`)
  - `description`: Free-text purpose and desired behavior (max 500 words)
  - `key_requirements`: Ordered list of concrete requirements the workflow must satisfy (at least one)
- **Interaction level**: `minimal` (default), `per-stage`, or `none`. Controls human review during pipeline execution.
  - `minimal`: Human review only at Gates 4 and 7, and when gates flag uncertainty.
  - `per-stage`: Present every stage's output for approval before proceeding.
  - `none`: Fully automated, no human checkpoints.

## Preconditions

1. **Workspace exists**: Verify the workspace path exists and contains at minimum: `stages.md`, `artifacts.md`, `context-specs.md`, `transformation.md`. If any are missing, abort with a message listing what is missing.
2. **No workflow name collision**: Check whether `workflows/<workflow_name>/` already exists under the workspace. If it does, abort with: "Workflow '<name>' already exists. Use `/loop:edit` to modify an existing workflow, or choose a different name."
3. **Input validation**: `workflow_name` is non-empty kebab-case. `description` is non-empty. `key_requirements` has at least one entry.

If preconditions fail, report the specific failure and do not proceed.

## Execution

### Shared Paths

- **Stage files**: `loop/stages/`
- **Contract files**: `loop/contracts/`
- **Existing workspace**: `<workspace-path>/` (user-provided, default `loop-workspace/`)
- **Workflow directory**: `<workspace-path>/workflows/<workflow-name>/`

Create `<workspace-path>/workflows/<workflow-name>/` at the start to store intermediate artifacts. Intermediate artifacts live alongside the final workflow artifacts — git provides the safety net for rollback.

### Execution Manifest

Maintain an execution manifest at `<workspace-path>/execution-manifest-add-<workflow-name>.json`. The manifest persists execution state across sessions.

**Initialization** (on first run): Create the manifest with:
- `pipeline_name`: `"loop-add-workflow"`
- `workflow_name`: the user-provided workflow name
- `run_id`: generate a UUID
- `started_at`: current timestamp
- `stages`: entries for `extract-existing-design`, `analyze-reuse`, `define-new-stages`, `compose-workflow`, `validate-consistency`, `write-phase`, all set to `pending`
- `gates`: empty array (populated as gates are attempted)
- `loops`: entries for each loop (`extraction-correction`, `reuse-analysis-correction`, `stage-definition-correction`, `workflow-config-correction`, `validation-correction`), each with `iteration_count: 0` and the appropriate `cap`
- `cascade_budgets`: empty array (no cascade budgets in this pipeline)
- `decisions`: empty array

**Checkpoint protocol**: Update the manifest and write to disk after every state transition (phase start/complete, gate attempt, loop iteration, human decision, error). Always update `updated_at` on every write.

---

### Phase 1: Extract-Existing-Design

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`) with this prompt:

> Read the stage file at `loop/stages/extract-existing-design.md`. Read the input contract at `loop/contracts/pipeline-input-directory.md` and the output contract at `loop/contracts/existing-design-inventory.md`. The workspace path is: [workspace-path]. Read all files in the workspace: `stages.md`, `artifacts.md`, `context-specs.md`, `transformation.md`, and any `workflows/*/gates.md` and `workflows/*/loops.md` files. Write the output artifact to `<workspace-path>/workflows/<workflow-name>/inventory.md`.

After the subagent completes, read `<workspace-path>/workflows/<workflow-name>/inventory.md` to verify it exists and is non-empty.

At `per-stage` interaction: present the inventory to the user and wait for approval before proceeding.

**Gate 3: Existing-Design-Inventory-Gate (Schema+Metric)**

Schema checks (run inline):
- [ ] `stages[]` array is present with at least one entry
- [ ] Each stage entry has `name`, `category`, `intent`, `input_contract_summary`, `output_contract_summary`, and `domain_assumptions`
- [ ] `artifacts[]` array is present
- [ ] `context_specs[]` array is present
- [ ] `workflows[]` array is present (may be empty)

Metric checks (run inline):
- [ ] Every `stages[].name` is unique
- [ ] Every `artifacts[].name` is unique
- [ ] Every `workflows[].name` is unique
- [ ] All `workflows[].stage_references` entries resolve to entries in `stages[].name`

**On gate failure** (Loop 1: Extraction-Correction):
- Route to: Phase 1
- Carry: specific schema/metric failures
- Max retries: 2
- Degradation: track violation count per iteration; if count does not decrease, stop and use iteration with fewest violations
- Escalation: present to user — extraction failure may indicate a corrupted or non-standard workspace

---

### Phase 2: Analyze-Reuse

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/analyze-reuse.md`. Read the input contracts at `loop/contracts/existing-design-inventory.md` and `loop/contracts/new-workflow-description.md`. Read the output contract at `loop/contracts/reuse-analysis-report.md`. Read the input artifact from `<workspace-path>/workflows/<workflow-name>/inventory.md`. The new workflow description is: workflow_name=[name], description=[description], key_requirements=[requirements]. Write the output artifact to `<workspace-path>/workflows/<workflow-name>/reuse-analysis.md`.

After the subagent completes, read the output to verify it exists and is non-empty.

At `per-stage` interaction: present the reuse analysis to the user before proceeding.

**Gate 4: Reuse-Analysis-Report-Gate (Schema+Semantic+Human)**

Schema checks (run inline):
- [ ] `workflow_name` matches the input workflow name
- [ ] `stage_verdicts[]` has exactly one entry per existing stage (count matches inventory)
- [ ] Each verdict has `stage_name`, `verdict` (one of `reuse-as-is`, `not-applicable`), and non-empty `rationale`
- [ ] `capability_gaps[]` entries each have unique `gap_id`, non-empty `description`, and non-empty `requirement_refs`
- [ ] At least one entry exists across reused stages or capability gaps

Semantic check (delegate to the `loop-gate-checker` subagent — Agent tool, `subagent_type: "loop-gate-checker"`):

> You are a reuse analysis reviewer. Read `<workspace-path>/workflows/<workflow-name>/reuse-analysis.md`, `<workspace-path>/workflows/<workflow-name>/inventory.md`, and the new workflow description: workflow_name=[name], description=[description], key_requirements=[requirements]. Check: (1) Each `reuse-as-is` verdict is justified — the stage's contract shapes and domain assumptions are compatible. (2) Each `not-applicable` verdict correctly identifies incompatibility. (3) Capability gaps collectively cover all key requirements not addressed by reused stages. Report violations with specific stage names and reasons.

Human gate (at `minimal` or `per-stage` — skip at `none`): After Schema and Semantic checks pass, present the reuse analysis report to the user via `AskUserQuestion`. Ask: "Review the reuse analysis above. Are the reuse verdicts and capability gaps correct? Approve to proceed, or provide corrections."

**On gate failure** (Loop 2: Reuse-Analysis-Correction):
- Route to: Phase 2
- Carry: specific failures
- Max retries: 2
- Degradation: track semantic + schema failure count; if total does not decrease, stop and use best iteration (fewest semantic failures preferred)
- Escalation: present to user — reuse decisions are judgment calls requiring human domain knowledge

---

### Phase 3: Define-New-Stages

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/define-new-stages.md`. Read the input contracts at `loop/contracts/reuse-analysis-report.md` and `loop/contracts/existing-design-inventory.md`. Read the output contract at `loop/contracts/new-stage-definitions.md`. Read the input artifacts from `<workspace-path>/workflows/<workflow-name>/reuse-analysis.md` and `<workspace-path>/workflows/<workflow-name>/inventory.md`. Write the output artifact to `<workspace-path>/workflows/<workflow-name>/new-stages.md`.

After the subagent completes, read the output to verify it exists and is non-empty.

At `per-stage` interaction: present the new stage definitions to the user before proceeding.

**Gate 5: New-Stage-Definitions-Gate (Schema+Metric)**

Schema checks (run inline):
- [ ] Every `new_stages[]` entry has `name` (verb-noun format), `category` (valid enum), `intent` (single verb phrase, no conjunctions), `input`, `output`, `sources`, `sinks`, and `fills_gap`
- [ ] Every `new_artifact_contracts[]` entry has `name`, `boundary`, `content`, `structure`, `identity_fields`, `omitted`, `validation`, and `reasoning_trace`

Metric checks (run inline):
- [ ] No `new_stages[].name` collides with any existing stage name from the inventory
- [ ] No `new_artifact_contracts[].name` collides with any existing artifact name from the inventory
- [ ] Every `fills_gap` references a valid `gap_id` from the reuse analysis
- [ ] Every Emit-category stage's artifact contracts include idempotency markers

**On gate failure** (Loop 3: Stage-Definition-Correction):
- Route to: Phase 3
- Carry: specific failures
- Max retries: 2
- Degradation: track violation count; if it does not decrease, stop and use iteration with fewest violations
- Escalation: present to user

---

### Phase 4: Compose-Workflow

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/compose-workflow.md`. Read the input contracts at `loop/contracts/reuse-analysis-report.md`, `loop/contracts/new-stage-definitions.md`, and `loop/contracts/existing-design-inventory.md`. Read the output contract at `loop/contracts/new-workflow-configuration.md`. Read the input artifacts from `<workspace-path>/workflows/<workflow-name>/reuse-analysis.md`, `<workspace-path>/workflows/<workflow-name>/new-stages.md`, and `<workspace-path>/workflows/<workflow-name>/inventory.md`. Write the output artifact to `<workspace-path>/workflows/<workflow-name>/workflow-config.md`.

After the subagent completes, read the output to verify it exists and is non-empty.

At `per-stage` interaction: present the workflow configuration to the user before proceeding.

**Gate 6: New-Workflow-Configuration-Gate (Schema+Semantic)**

Schema checks (run inline):
- [ ] `workflow_name` matches the expected name
- [ ] `gates[]` entries each have `name`, `position`, `criteria` (non-empty array), and `on_fail` (valid enum)
- [ ] `loops[]` entries each have `name`, `from_stage`, `to_stage`, `trigger`, `max_iterations` (positive integer), and `loop_type` (valid enum)
- [ ] No gate name collides with gates in existing workflows (cross-reference inventory)

Semantic check (delegate to the `loop-gate-checker` subagent — Agent tool, `subagent_type: "loop-gate-checker"`):

> You are a workflow configuration reviewer. Read `<workspace-path>/workflows/<workflow-name>/workflow-config.md`, `<workspace-path>/workflows/<workflow-name>/inventory.md`, and `<workspace-path>/workflows/<workflow-name>/new-stages.md`. Check: (1) Every gate position and loop stage reference resolves to a stage in either the existing inventory or new stage definitions. (2) Gate criteria are testable and non-trivial. (3) Loop triggers describe observable conditions. (4) No reinforcing loop lacks a balancing mechanism or iteration cap. Report violations.

**On gate failure** (Loop 4: Workflow-Config-Correction):
- Route to: Phase 4
- Carry: specific failures
- Max retries: 2
- Degradation: track schema + semantic failure count; if total does not decrease, stop and use best iteration
- Escalation: present to user

---

### Phase 5: Validate-Consistency

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/validate-consistency.md`. Read the input contracts at `loop/contracts/existing-design-inventory.md`, `loop/contracts/new-stage-definitions.md`, and `loop/contracts/new-workflow-configuration.md`. Read the output contract at `loop/contracts/validation-report.md`. Read the input artifacts from `<workspace-path>/workflows/<workflow-name>/inventory.md`, `<workspace-path>/workflows/<workflow-name>/new-stages.md`, and `<workspace-path>/workflows/<workflow-name>/workflow-config.md`. Also read existing workflow directories for cross-workflow comparison: read all `<workspace-path>/workflows/*/gates.md` and `<workspace-path>/workflows/*/loops.md` files. Write the output artifact to `<workspace-path>/workflows/<workflow-name>/validation.md`.

After the subagent completes, read the output to verify it exists and is non-empty.

At `per-stage` interaction: present the validation report to the user before proceeding.

**Gate 7: Validation-Report-Gate (Schema+Metric+Human)**

Schema checks (run inline):
- [ ] `overall_status` is present (one of `pass`, `fail`)
- [ ] `checks_performed[]` is non-empty, each with `check_name`, `scope`, `status`, and `details`
- [ ] If `overall_status` is `fail`, `inconsistencies[]` is non-empty with required fields

Metric checks (run inline):
- [ ] `overall_status` is `pass`
- [ ] `overall_status` is `fail` if and only if at least one check status is `fail`
- [ ] Every `inconsistencies[].check_name` references a check in `checks_performed`

Human gate (at `minimal` or `per-stage` — skip at `none`): After Schema and Metric checks pass, present the validation report and a summary of what will be written to the user via `AskUserQuestion`:

> "Validation passed. The following changes will be applied:
> - Append [N] new stages to `stages.md`
> - Append [N] new artifacts to `artifacts.md`
> - Append [N] new context specs to `context-specs.md`
> - Create `workflows/<name>/gates.md` with [N] gates
> - Create `workflows/<name>/loops.md` with [N] loops
> [If transformation_update]: Update `transformation.md` scope
>
> Approve to write, or reject to abort."

**On gate failure** (Loop 5: Validation-Correction):
- Route to: Phase 4 (Compose-Workflow) if inconsistencies involve gates/loops, or Phase 3 (Define-New-Stages) if inconsistencies involve naming collisions or artifact structure
- Carry: full list of inconsistencies with severity, description, affected elements, and suggested fixes
- Max retries: 3
- After routing to the upstream phase, re-run all subsequent phases and gates through Gate 7
- Degradation: track error-severity inconsistency count; if it does not decrease, stop and use iteration with fewest errors. Monitor for oscillation.
- Escalation: present to user — persistent inconsistencies require human judgment

---

### Write Phase (orchestrator-inline)

After Gate 7 passes (including Human approval), the orchestrator writes files directly. These are mechanical append/create operations — no subagent needed.

1. **Read** `<workspace-path>/workflows/<workflow-name>/new-stages.md` for new stage entries, artifact contracts, and context specs
2. **Read** `<workspace-path>/workflows/<workflow-name>/workflow-config.md` for gates, loops, and optional transformation update
3. **Append** new stage entries to `<workspace-path>/stages.md`
4. **Append** new artifact contracts to `<workspace-path>/artifacts.md`
5. **Append** new context specs to `<workspace-path>/context-specs.md`
6. **Write** `<workspace-path>/workflows/<workflow-name>/gates.md` from the workflow config's gates
7. **Write** `<workspace-path>/workflows/<workflow-name>/loops.md` from the workflow config's loops
8. **If** `transformation_update` is non-null, update `<workspace-path>/transformation.md`

After writing, verify each file was modified/created successfully. If any write fails, report the failure and stop — git allows the user to recover.

---

## Resumption

The execution manifest is the primary resumption mechanism. On invocation, check for an existing manifest at `<workspace-path>/execution-manifest-add-<workflow-name>.json`.

- **If manifest found**: Read it. Present status summary (which phases complete, loop counts, human decisions). Ask: "Resume from [next incomplete phase], or start fresh?" If resuming, restore all state from the manifest — skip `complete` phases, restore loop iteration counts, don't re-ask recorded decisions. If starting fresh, rename the manifest to `execution-manifest-add-<workflow-name>.<timestamp>.json`.
- **If no manifest but workflow artifacts exist**: Fall back to artifact-presence resumption. Warn about lost execution state.

**Fallback** (no manifest): Use artifact presence in `<workspace-path>/workflows/<workflow-name>/`:

| Artifact | If present, skip to |
|---|---|
| `inventory.md` | Phase 2 |
| `reuse-analysis.md` | Phase 3 |
| `new-stages.md` | Phase 4 |
| `workflow-config.md` | Phase 5 |
| `validation.md` AND `gates.md` | Pipeline complete |

Warn: "No execution manifest found. Resuming from artifact presence — loop iteration counts and human decisions could not be restored."

## Error Handling

**Stage failure (subagent errors out)**: Read whatever partial output exists. Present the error to the user. Offer to retry the failed phase or abort. Completed artifacts are preserved in the workflow directory.

**Human escalation**: When a gate escalates to human review, present the artifact and the specific problem clearly. Wait for the user's decision: fix and retry, accept with warning, or abort.

**Pipeline abort**: Preserve the workflow directory and execution manifest as-is. The manifest records exactly where execution stopped. Re-invoking `/loop:add-workflow` will read the manifest and offer precise resumption. If writes were partially completed, the user can `git checkout` to restore the workspace.

**Write failure**: If any file write in the Write Phase fails, report which writes succeeded and which failed. Do not attempt partial cleanup — git provides rollback.

## Pipeline Run Summary

After the pipeline completes, derive the summary from the execution manifest and report:

- **Artifacts produced**: List all files written with their paths
- **Gate results**: For each gate, pass/fail and retry count (from `gates[].attempts` in the manifest)
- **Loop iterations**: For each loop that fired, iteration count and outcome (from `loops[]` in the manifest)
- **Human decisions**: Decisions made during the run (from `decisions[]`)
- **Files modified**: List of shared artifacts appended to and new workflow files created
- **Total run duration**: From manifest `started_at` to final `updated_at`

## Guidance

- Delegate each stage to the `loop-stage-runner` subagent for context isolation. The subagent sees only the stage file, relevant contracts, and input artifacts — not the orchestrator's reasoning or prior stages' reasoning.
- Run semantic gates in the `loop-gate-checker` subagent with clean context. Do not evaluate a stage's output in the same context that produced it.
- Gates are checkpoints, not bottlenecks. Run schema, metric, and identity checks inline. Reserve `loop-gate-checker` delegation for semantic checks only.
- Track degradation across loop iterations. A loop that is not improving is wasting inference budget.
- Preserve workflow directory artifacts. Never delete or overwrite artifacts from completed phases unless re-running that phase as part of a correction loop.
- Report progress to the user between phases. After each phase, state what was completed, any gate results, and what comes next.
- When re-running a phase during a correction loop, include the gate failure feedback in the subagent prompt so the stage knows what to fix.
- Intermediate artifacts live in the workflow directory (`workflows/<name>/`). The Write Phase appends to shared artifacts and creates final workflow files. Git provides the rollback safety net.
- All stages execute sequentially. There are no parallel opportunities in this pipeline due to strict data dependencies.
