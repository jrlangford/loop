# Artifact Specifications

## Pipeline Input: Task Description
- **Content**: Natural language description of what an LLM pipeline should do
- **Format**: Free text — one sentence to multiple paragraphs. May include domain context, constraints, examples.
- **Variability**: High — ranges from vague ("summarize documents") to detailed multi-paragraph specifications with explicit quality criteria

## Pipeline Input: Interaction Level
- **Content**: How much human involvement the user wants during design
- **Format**: Enum — `minimal` | `per-stage` | `none`
- **Variability**: Low — one of three fixed values. Default: `minimal`

## Pipeline Input (edit workflow): Existing Workspace
- **Content**: A complete or partial set of loop-workspace design artifacts
- **Format**: Directory containing markdown files following loop-workspace conventions
- **Variability**: High — may be complete (all 6 artifact types) or partial (only some phases completed)

## Pipeline Input (edit workflow): Modification Request
- **Content**: What the user wants to change in the existing design
- **Format**: Free text describing the change — could be "add a stage", "change this gate", "add a feedback loop from X to Y", etc.
- **Variability**: High — any aspect of the design can be modified

## Artifact: Define Transformation → Decompose Stages
- **Name**: Transformation Definition
- **Content**: Problem definition — what the pipeline does, what it receives, what it produces, what's hard about the transformation, and early complexity signals
- **Structure**:
  - `task`: string — one-sentence pipeline description
  - `input_spec`: structured — format, structure, variability, volume, quality issues
  - `output_spec`: structured — format, structure, quality criteria, consumer
  - `gap_analysis`: structured — hard parts, where single-pass fails, domain knowledge needed, critical-correctness vs. best-effort areas
  - `complexity_signals`: structured — flags for parallelization, refinement, external sources, external sinks, notification needs, error reinforcement risk
- **Identity fields**: `task` (the one-sentence description anchors the entire design)
- **Omitted**: Implementation details, stage suggestions, architecture decisions — those are downstream concerns
- **Validation**: task is a single sentence; input_spec and output_spec are both present and non-empty; gap_analysis identifies at least one difficulty; complexity_signals is present
- **Reasoning trace**: None — the artifact is the user's intent, not the result of inference

## Artifact: Decompose Stages → Specify Artifacts
- **Name**: Stage Decomposition
- **Content**: Ordered list of pipeline stages with categories, intents, inputs, outputs, and dependencies
- **Structure**:
  - `overview`: string — one-line summary + stage count
  - `stages[]`: array of:
    - `name`: string — verb-noun format
    - `category`: enum — Extract | Enrich | Transform | Evaluate | Synthesise | Refine | Emit
    - `intent`: string — single verb phrase
    - `input`: string — what this stage consumes
    - `output`: string — what this stage produces
    - `sources`: string — external read dependencies or "None"
    - `sinks`: string — external write targets or "None"
    - `complexity`: string — special handling notes
- **Identity fields**: `stages[].name` (stage names are referenced by all downstream artifacts)
- **Omitted**: Detailed artifact schemas, gate positions, feedback loops, context budgets — all downstream concerns
- **Validation**: Every stage intent is a single verb phrase (no conjunctions). Every stage has a category from the enum. No two stages share the same name. Stage count matches overview.
- **Reasoning trace**: None — the decomposition is structural, not inferential

## Artifact: Specify Artifacts → Budget Context
- **Name**: Artifact Specifications
- **Content**: Typed contracts for every inter-stage artifact — what crosses each boundary, how it's structured, what's omitted
- **Structure**:
  - `artifacts[]`: array of:
    - `name`: string — descriptive name
    - `boundary`: string — "[Stage A] → [Stage B]"
    - `content`: string — what it carries
    - `structure`: structured — fields, types, constraints
    - `identity_fields`: string[] — fields that must not mutate
    - `omitted`: string — what the upstream stage produced but this artifact excludes
    - `validation`: string — how to check conformance
    - `reasoning_trace`: enum — None | Summary | Full, with rationale
- **Identity fields**: `artifacts[].name`, `artifacts[].boundary` (referenced by gates and loops)
- **Omitted**: Context budgets, gate criteria, loop configurations — downstream concerns
- **Validation**: Every stage boundary has an artifact. Every artifact has at least one field in its structure. Every artifact consumed by an Emit stage includes idempotency markers. No orphan artifacts (every artifact is produced by one stage and consumed by at least one).
- **Reasoning trace**: None — contracts are declarative specifications

## Artifact: Budget Context → (consumed by orchestrator)
- **Name**: Context Specifications
- **Content**: Per-stage context window budgets — what goes in, what stays out, load assessment
- **Structure**:
  - `context_specs[]`: array of:
    - `stage`: string — stage name (must match stages.md)
    - `germane_load`: string[] — what to include in context (signal)
    - `extraneous_load`: string[] — what to exclude (noise)
    - `intrinsic_load`: string — inherent complexity assessment, chunking strategy if needed
    - `history_policy`: enum — none | summary | full, with justification
    - `isolation_model`: string — how this stage's context is managed (subagent delegation, clean context)
- **Identity fields**: `context_specs[].stage` (must match stage names in stages.md)
- **Omitted**: Gate criteria, loop configuration — those operate at the workflow level, not the stage level
- **Validation**: Every stage in stages.md has a context spec. History policy defaults to "none" — any deviation has explicit justification. Isolation model is specified for every stage.
- **Reasoning trace**: Summary — context budget decisions involve tradeoffs worth recording for future revision

## Artifact: Place Gates → Design Feedback
- **Name**: Gate Specifications
- **Content**: Validation checkpoints between stages — positions, types, criteria, failure routes, escalation paths
- **Structure**:
  - `gates[]`: array of:
    - `name`: string — descriptive name
    - `position`: string — "Between [Stage A] and [Stage B]"
    - `artifact_checked`: string — artifact name (must match artifacts.md)
    - `type`: enum — Schema | Metric | Identity | Semantic | Consensus | Human
    - `criteria`: string — what must be true to pass
    - `on_failure.routes_to`: string — stage name
    - `on_failure.carries`: string — what feedback the failing stage receives
    - `on_failure.max_retries`: integer
    - `on_failure.escalation`: string — what happens after max retries (human review, skip, abort)
  - `ungated_boundaries[]`: array of:
    - `boundary`: string — "[Stage A] → [Stage B]"
    - `rationale`: string — why no gate is needed
- **Identity fields**: `gates[].name`, `gates[].position` (referenced by feedback loops)
- **Omitted**: Loop configuration, degradation detection — those are `/loop:phase-feedback`'s concern
- **Validation**: Every artifact boundary has either a gate or an ungated boundary with rationale. Every gate failure route points to a stage that exists in stages.md. Every gate has max_retries > 0 and a non-empty escalation. Gate type is from the enum. Human gates are used only where interaction level permits.
- **Reasoning trace**: Summary — gate placement decisions involve failure mode analysis worth preserving

## Artifact: Design Feedback → Review Design
- **Name**: Loop Specifications
- **Content**: Feedback loop definitions — types, stages involved, termination conditions, degradation detectors
- **Structure**:
  - `loops[]`: array of:
    - `name`: string — descriptive name
    - `type`: enum — Reinforcing | Balancing
    - `stages_involved`: string — "[Stage A] → [Stage B] → [Stage A]"
    - `purpose`: string — what the loop achieves
    - `pattern`: string — established pattern (Evaluator-optimizer, Prompt chaining, etc.)
    - `termination.semantic`: string — condition meaning "done"
    - `termination.hard_cap`: integer — maximum iterations
    - `degradation_detector`: string — how to detect things getting worse
    - `best_iteration_selection`: string — how to pick the best output on degradation
  - `no_loop_justification`: string — if no loops, why (optional)
- **Identity fields**: `loops[].name`, `loops[].stages_involved` (define the connection graph for cascade detection)
- **Omitted**: Runtime execution details — those are the orchestrator's concern
- **Validation**: Every loop has both semantic termination and hard cap. Every loop's stages exist in stages.md. Balancing loops have degradation detectors. Reinforcing loops have novelty gates. No loop has hard_cap > 10 without explicit justification.
- **Reasoning trace**: Summary — loop design involves dynamic systems reasoning worth preserving

## Artifact: Review Design → (pipeline output)
- **Name**: Review Results
- **Content**: Anti-pattern findings, consistency checks, and recommendations
- **Structure**:
  - `findings[]`: array of:
    - `severity`: enum — ERROR | WARNING | INFO
    - `anti_pattern`: string — which anti-pattern or consistency issue (if applicable)
    - `location`: string — which artifact and section
    - `description`: string — what's wrong
    - `recommendation`: string — what to fix and which phase to re-run
  - `consistency_checks`: structured — referential integrity results, completeness results
  - `edit_findings` (optional, edit workflow only):
    - `missed_staleness[]`: array of — artifacts that should have been flagged stale but weren't, with evidence of inconsistency
    - `partial_execution_inconsistencies[]`: array of — mismatches between re-executed and non-re-executed artifacts, with the specific conflict described
  - `verdict`: enum — PASS | PASS_WITH_WARNINGS | FAIL
- **Identity fields**: None — review results are ephemeral assessments
- **Omitted**: The artifacts themselves — review references them by location, not by copying
- **Validation**: Every ERROR finding has a recommendation. Verdict is FAIL if any ERROR findings exist.
- **Reasoning trace**: Full — review reasoning must be transparent for the designer to evaluate and act on findings

## Artifact: Map Staleness → (edit workflow orchestrator)
- **Name**: Staleness Map
- **Content**: Which design artifacts are stale after a change, why, and which stages need re-execution
- **Structure**:
  - `change_source`: string — which artifact was modified and what changed
  - `stale_artifacts[]`: array of:
    - `artifact`: string — artifact name
    - `reason`: string — why it's stale (forward dependency, backward feedback connection, removed reference, new connection)
    - `cascade_path`: string — the connection path from change source to this artifact
    - `recommended_stage`: string — which stage to re-run
    - `cascade_type`: enum — structural | content — whether the change is structural (added/removed stages) or content (modified criteria)
  - `unaffected_artifacts[]`: array of:
    - `artifact`: string — artifact name
    - `reason`: string — why it's not affected
- **Identity fields**: `change_source` (anchors the analysis)
- **Omitted**: The actual re-execution — the orchestrator decides what to run based on the map and user input
- **Validation**: Every artifact in the workspace appears in either stale_artifacts or unaffected_artifacts. Every stale artifact has a cascade_path traceable from the change_source. Every recommended_stage exists in stages.md.
- **Reasoning trace**: Full — the designer needs to understand why each artifact is considered stale to decide whether to accept the cascade recommendation

## Pipeline Input (add-workflow): Workspace Path
- **Name**: Pipeline-Input-Directory
- **Content**: Reference to the existing populated loop-workspace directory that the pipeline will extend
- **Structure**:
  - `workspace_path`: string — absolute or relative path to the existing `loop-workspace/` directory
- **Identity fields**: `workspace_path`
- **Omitted**: Directory contents — the Extract stage reads them directly via source access
- **Validation**: Path exists and contains at least `stages.md`, `artifacts.md`, `context-specs.md`, and `transformation.md`. May optionally contain a `workflows/` subdirectory.
- **Reasoning trace**: None — simple path reference

## Pipeline Input (add-workflow): Workflow Description
- **Name**: New-Workflow-Description
- **Content**: The user's natural-language description of the new workflow to be added
- **Structure**:
  - `workflow_name`: string — kebab-case identifier (e.g., `code-review`)
  - `description`: string — free-text purpose and desired behavior, max 500 words
  - `key_requirements`: string[] — ordered list of concrete requirements
- **Identity fields**: `workflow_name`
- **Omitted**: Implementation details, gate/loop preferences — downstream concerns
- **Validation**: `workflow_name` is non-empty kebab-case. `description` is non-empty. `key_requirements` has at least one entry.
- **Reasoning trace**: None — user-provided input

## Artifact: Extract-Existing-Design → Analyze-Reuse, Define-New-Stages, Compose-Workflow, Validate-Consistency
- **Name**: Existing-Design-Inventory
- **Content**: Structured index of all stages, artifacts, context specs, and workflow configurations in the existing pipeline
- **Structure**:
  - `stages[]`: array of `{name, category, intent, input_contract_summary, output_contract_summary, domain_assumptions[]}`
  - `artifacts[]`: array of `{name, boundary, field_names[]}`
  - `context_specs[]`: array of `{stage_name, budget_summary}`
  - `workflows[]`: array of `{name, gate_count, loop_count, stage_references[]}`
- **Identity fields**: `stages[].name`, `artifacts[].name`, `workflows[].name`
- **Omitted**: Full artifact field definitions, full gate criteria text, full loop configuration details — only summaries needed for reuse analysis and collision detection
- **Validation**: Every name is unique within its array. All `workflows[].stage_references` resolve to `stages[].name`.
- **Reasoning trace**: None — structural extraction, not inferential

## Artifact: Analyze-Reuse → Define-New-Stages, Compose-Workflow
- **Name**: Reuse-Analysis-Report
- **Content**: Per-stage reuse verdict for the new workflow plus identified capability gaps
- **Structure**:
  - `workflow_name`: string — reference to target workflow
  - `stage_verdicts[]`: array of `{stage_name, verdict (reuse-as-is | not-applicable), rationale}`
  - `capability_gaps[]`: array of `{gap_id, description, requirement_refs[]}`
- **Identity fields**: `workflow_name`, `stage_verdicts[].stage_name`
- **Omitted**: Suggested stage designs for gaps — that is Define-New-Stages' concern. No partial-reuse verdicts — stages are reused as-is or not applicable.
- **Validation**: Every existing stage appears exactly once in `stage_verdicts`. Every `gap_id` is unique. At least one entry exists across reused stages or capability gaps.
- **Reasoning trace**: Summary — reuse decisions are judgment calls; rationale captured per-verdict

## Artifact: Define-New-Stages → Compose-Workflow, Validate-Consistency, orchestrator Write Phase
- **Name**: New-Stage-Definitions
- **Content**: Fully specified new stages and their artifact contracts, ready for append to shared pipeline artifacts
- **Structure**:
  - `new_stages[]`: array of `{name, category, intent, input, output, sources, sinks, fills_gap}`
  - `new_artifact_contracts[]`: array of `{name, boundary, content, structure, identity_fields[], omitted, validation, reasoning_trace}`
  - `new_context_specs[]`: array of `{stage_name, budget}`
- **Identity fields**: `new_stages[].name`, `new_artifact_contracts[].name`
- **Omitted**: Gate positions, loop definitions — workflow-scoped, handled by Compose-Workflow
- **Validation**: No name collisions with existing stages/artifacts. Every `fills_gap` references a valid `gap_id`. Emit-category stages include idempotency markers.
- **Reasoning trace**: None — structural definitions derived from gap specifications

## Artifact: Compose-Workflow → Validate-Consistency, orchestrator Write Phase
- **Name**: New-Workflow-Configuration
- **Content**: The new workflow's gate and loop definitions, referencing reused and newly defined stages
- **Structure**:
  - `workflow_name`: string
  - `gates[]`: array of `{name, position, criteria[], on_fail}`
  - `loops[]`: array of `{name, from_stage, to_stage, trigger, max_iterations, loop_type}`
  - `transformation_update`: string or null
- **Identity fields**: `workflow_name`, `gates[].name`, `loops[].name`
- **Omitted**: Stage definitions and artifact contracts — shared-level concerns
- **Validation**: All stage references resolve. `max_iterations` is positive. No gate name collides with existing workflows.
- **Reasoning trace**: Summary — gate criteria and loop triggers involve judgment

## Artifact: Validate-Consistency → orchestrator Write Phase
- **Name**: Validation-Report
- **Content**: Cross-workflow consistency check results covering the full extended design
- **Structure**:
  - `overall_status`: enum — `pass` | `fail`
  - `checks_performed[]`: array of `{check_name, scope (naming | gate-compatibility | reference-integrity | context-spec-compatibility), status, details}`
  - `inconsistencies[]`: array of `{check_name, severity (error | warning), description, affected_elements[], suggested_fix}`
- **Identity fields**: `checks_performed[].check_name`
- **Omitted**: Corrected versions of failing elements — correction is an upstream concern via feedback loops
- **Validation**: `overall_status` is `fail` iff at least one check status is `fail`. Every inconsistency references a check in `checks_performed`.
- **Reasoning trace**: Summary — validation judgments require rationale, captured in `details` and `description` fields
