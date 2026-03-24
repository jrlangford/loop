---
description: "Workflow: full Loop design pipeline — takes a task description and produces a complete pipeline design with stages, artifacts, context budgets, gates, loops, and review."
interaction: plan
---

# Loop: Design Pipeline

Orchestrate the complete design pipeline. Take a task description and produce a full Loop pipeline design by sequencing stages 1-7, enforcing gates, managing feedback loops, and handling failures. By default, stages run inline in the main conversation so the user can participate in design decisions. Stages can optionally be delegated to isolated subagents for automated execution. The orchestrator's job is sequencing, gate checking, loop management, and progress reporting.

## Subagent Types

This skill uses two custom agents distributed with the Loop plugin:

- **`loop-stage-runner`** — Executes pipeline stages in isolated context. Has Read, Write, Edit, Glob, Grep tools. Used for delegated (non-inline) stage execution.
- **`loop-gate-checker`** — Evaluates semantic gates in clean context. Has Read, Glob, Grep tools (read-only). Use for all semantic gate checks.

When delegating to a subagent, always specify the `subagent_type` parameter in the Agent tool call.

## Pipeline Overview

```
[Define Transformation] → (Transformation Completeness) → [Decompose Stages] → (Decomposition Validity) →
  [Specify Artifacts] → (Contract Integrity) → (Re-grounding) → [Budget Context] ──────────────┐
                                                                  [Place Gates] → (Gate Ref Int) ─┤
                                                                                                  ├→ [Design Feedback] → [Review Design]
                                                                                                  │
Loops:                                                                                            │
  Transformation Refinement:  Stage 1 ← Gate 1 (max 2)                                           │
  Decomposition Correction:   Stage 2 ← Gate 2 (max 3)                                           │
  Contract Correction:        Stage 3 ← Gate 3 (max 2)                                           │
  Re-grounding Correction:    Gate 4 → Stage 2 or 3 → ... → Gate 4 (max 1)                       │
  Gate Correction:            Stage 5 ← Gate 5 (max 2)                                           │
  Review Correction:          Stage 7 → affected stage → ... → Stage 7 (max 3 cycles, 10 calls)  │
```

Stages 4 (Budget Context) and 5 (Place Gates) run in parallel — they share the same inputs and have no dependency between them.

## Inputs

Collect from the user before starting:

- **Task description**: Natural language description of what the pipeline should do. One sentence to multiple paragraphs.
- **Execution mode**: Controls how design stages are executed. Present these options to the user:
  - `interactive` (default): All stages run inline in the main conversation. The user can ask questions, provide domain knowledge, and steer decisions during each phase. Recommended for most design work.
  - `semi-automatic`: Creative phases (1–3: transformation, decomposition, artifacts) run inline for rich interaction. Mechanical phases (4–7: budgets, gates, feedback loops, review) are delegated to subagents. Good balance of collaboration and speed.
  - `automatic`: All stages delegated to subagents. No mid-stage interaction. Fastest execution. Equivalent to the previous default behavior.
  - `custom`: The user specifies which phases run inline and which are delegated. Ask: "Which phases should run interactively? (1: Transformation, 2: Decomposition, 3: Artifacts, 4: Context Budgets, 5: Gates, 6: Feedback Loops, 7: Review)". Record the user's selection as a list of inline phase numbers; all others are delegated.
- **Pipeline interaction level**: `minimal` (default), `per-stage`, or `none`. Controls what interaction level the *designed pipeline* will have at runtime — determines whether the pipeline being designed includes Human gates for its end users. This is independent of execution mode.
  - `minimal`: Human gates only for critical ambiguities. Most gates automated.
  - `per-stage`: Human gates after every stage, in addition to automated gates.
  - `none`: All gates automated. Human gate candidates are documented but not promoted.
- **Workflow name**: Name for this workflow (used for workflow-scoped artifacts under `loop-workspace/workflows/<name>/`). Default: `design`.

### Execution Mode Resolution

Resolve the execution mode into a per-phase inline/delegated decision before starting:

| Mode | Phases inline | Phases delegated |
|---|---|---|
| `interactive` | 1, 2, 3, 4, 5, 6, 7 | — |
| `semi-automatic` | 1, 2, 3 | 4, 5, 6, 7 |
| `automatic` | — | 1, 2, 3, 4, 5, 6, 7 |
| `custom` | user-specified | remaining |

Record this resolution in the execution manifest as `execution_mode` and `inline_phases: [...]`.

## Preconditions

Check for an existing execution manifest at `loop-workspace/execution-manifest.json` (or `execution-manifest-<workflow-name>.json`).

- **If manifest found**: Read it. Present a status summary (which phases complete, where it stopped, loop iteration counts, any errors). Ask: "Resume from [next incomplete phase], or start fresh?" If resuming, restore all state from the manifest. If starting fresh, rename the manifest to `execution-manifest[-<workflow>].<timestamp>.json` and confirm before deleting existing workspace artifacts.
- **If no manifest but workspace artifacts exist**: Fall back to artifact-presence resumption (check which output files exist, skip those phases). Warn the user that execution state (loop counts, cascade budgets, decisions) could not be restored.
- **If no workspace artifacts**: Proceed with a fresh run.

No external dependencies are required.

## Execution

### Shared Paths

- **Stage files**: `loop/stages/`
- **Contract files**: `loop/contracts/`
- **Workspace**: `loop-workspace/`
- **Workflow directory**: `loop-workspace/workflows/<workflow-name>/`

Create `loop-workspace/` and `loop-workspace/workflows/<workflow-name>/` if they do not exist.

### Execution Manifest

Maintain an execution manifest at `loop-workspace/execution-manifest.json` (single workflow) or `loop-workspace/execution-manifest-<workflow-name>.json` (multi-workflow). The manifest persists execution state across sessions.

**Initialization** (on first run): Create the manifest with:
- `pipeline_name`: `"loop-design"`
- `workflow_name`: the user-provided workflow name
- `execution_mode`: the selected mode (`interactive`, `semi-automatic`, `automatic`, or `custom`)
- `inline_phases`: array of phase numbers that run inline (e.g., `[1, 2, 3]` for semi-automatic)
- `run_id`: generate a UUID
- `started_at`: current timestamp
- `stages`: one entry per phase (`define-transformation`, `decompose-stages`, `specify-artifacts`, `budget-context`, `place-gates`, `design-feedback`, `review-design`), all set to `pending`
- `gates`: empty array (populated as gates are attempted)
- `loops`: entries for each loop (`transformation-refinement`, `decomposition-correction`, `contract-correction`, `re-grounding-correction`, `gate-correction`, `review-correction`), each with `iteration_count: 0` and the appropriate `cap`
- `cascade_budgets`: `[{ "context": "review-correction", "total": 10, "used": 0, "cycle": 0 }]`
- `decisions`: empty array

**Checkpoint protocol**: Update the manifest and write to disk:
- Before starting a phase: set its stage status to `in_progress`, record `started_at`
- After completing a phase: set status to `complete`, record `completed_at`
- After each gate attempt: append to the gate's `attempts` array
- After each loop iteration: increment the loop's `iteration_count`
- After each cascade call in review correction: increment `cascade_budgets[0].used`
- After each human decision: append to `decisions` array
- On error: set stage status to `failed`, record the error
- Always update `updated_at` on every write

Also track in the manifest (as custom fields):
- `re_grounding_fired`: boolean (Gate 4 can only fire once)

---

### Phase 1: Define Transformation

**If inline** (phase 1 is in `inline_phases`):

Read the stage file at `loop/stages/define-transformation.md` and the output contract at `loop/contracts/transformation-definition.md`. Using the task description as input, work through the transformation definition collaboratively with the user:
- Present your initial framing of the task, input spec, and output spec
- Ask the user to confirm or refine before proceeding to gap analysis
- Discuss complexity signals and potential difficulties together
- Write the agreed result to `loop-workspace/transformation.md`

**If delegated** (phase 1 is not in `inline_phases`):

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`) with this prompt:

> Read the stage file at `loop/stages/define-transformation.md`. Read the output contract at `loop/contracts/transformation-definition.md`. The task description is: [task description]. Write the output artifact to `loop-workspace/transformation.md`.

After the subagent completes, read `loop-workspace/transformation.md` to verify it exists and is non-empty. Present the artifact to the user and wait for approval before proceeding.

**Gate 1: Transformation Completeness**

Schema checks (run inline):
- [ ] `task` field is a single sentence
- [ ] `input_spec` is present and non-empty
- [ ] `output_spec` is present and non-empty
- [ ] `gap_analysis` contains at least one difficulty
- [ ] `complexity_signals` is present

Semantic checks (at `none` interaction level only):
- [ ] `gap_analysis` is at least 50 words
- [ ] `input_spec` describes format and variability
- [ ] `output_spec` includes quality criteria

Human gate (at `minimal` or `per-stage`): trigger when the task description was vague (fewer than 2 sentences), gap analysis flags uncertainty about staging, or complexity signals are ambiguous. Present the transformation definition and ask the user to confirm or clarify.

**On gate failure** (Loop 1: Transformation Refinement):
- Route to: Phase 1
- Carry: which sections are missing or incomplete
- Max retries: 2
- Degradation: compare completeness between iterations; if no improvement, stop
- Escalation: at `none`, abort pipeline; otherwise present as-is with warning and proceed

---

### Phase 2: Decompose Stages

**If inline** (phase 2 is in `inline_phases`):

Read the stage file at `loop/stages/decompose-stages.md`, the input contract at `loop/contracts/transformation-definition.md`, and the output contract at `loop/contracts/stage-decomposition.md`. Read the input artifact from `loop-workspace/transformation.md`. Work through the decomposition collaboratively:
- Propose an initial stage breakdown with rationale
- Discuss with the user: are these the right cuts? Should any stage be split or merged?
- Surface tricky decomposition decisions (e.g., "Should extraction and validation be one stage or two?") and ask for the user's domain judgment
- Write the agreed result to `loop-workspace/stages.md`

**If delegated** (phase 2 is not in `inline_phases`):

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/decompose-stages.md`. Read the input contract at `loop/contracts/transformation-definition.md` and the output contract at `loop/contracts/stage-decomposition.md`. Read the input artifact from `loop-workspace/transformation.md`. Write the output artifact to `loop-workspace/stages.md`.

After the subagent completes, read `loop-workspace/stages.md` to verify it exists and is non-empty. Present the artifact to the user and wait for approval before proceeding.

**Gate 2: Decomposition Validity**

Schema checks (run inline):
- [ ] All required fields present on every stage
- [ ] Every `category` is from the enum: Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit
- [ ] Every stage name is unique
- [ ] Stage count matches the overview

Metric checks (run inline):
- [ ] Stage count is between 2 and 15
- [ ] Every stage intent is a single verb phrase (no conjunctions — no "and", "then", semicolons)

Semantic check (delegate to the `loop-gate-checker` subagent — Agent tool, `subagent_type: "loop-gate-checker"`):

> You are a design reviewer. Read `loop-workspace/stages.md`. Check for: (1) Kitchen Sink — any stage whose intent has conjunctions, whose complexity notes exceed 3 sentences, or that requires multiple distinct cognitive operations. (2) Ordering — stages follow narrow-before-wide, fail-fast, cheap-before-expensive, emit-last principles. (3) Gap coverage — every difficulty in `loop-workspace/transformation.md`'s gap analysis maps to at least one stage. Report violations with specific stage names and reasons.

**On gate failure** (Loop 2: Decomposition Correction):
- Route to: Phase 2
- Carry: specific violations (which stages, which checks failed)
- Max retries: 3 (including semantic retry)
- Degradation: track violation count; if it does not decrease across consecutive iterations, stop and use best iteration
- Escalation: present decomposition with warnings and proceed

---

### Phase 3: Specify Artifacts

**If inline** (phase 3 is in `inline_phases`):

Read the stage file at `loop/stages/specify-artifacts.md`, the input contract at `loop/contracts/stage-decomposition.md`, and the output contract at `loop/contracts/artifact-specifications.md`. Read the input artifact from `loop-workspace/stages.md`. Work through artifact specifications collaboratively:
- Propose the artifact chain: what data flows between stages, in what structure
- Ask the user about domain-specific data: what fields matter, what can be omitted, what identity fields enable deduplication
- Discuss validation rules and reasoning trace requirements
- Write the agreed result to `loop-workspace/artifacts.md`

**If delegated** (phase 3 is not in `inline_phases`):

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/specify-artifacts.md`. Read the input contract at `loop/contracts/stage-decomposition.md` and the output contract at `loop/contracts/artifact-specifications.md`. Read the input artifact from `loop-workspace/stages.md`. Write the output artifact to `loop-workspace/artifacts.md`.

After the subagent completes, read `loop-workspace/artifacts.md` to verify it exists and is non-empty. Present the artifact to the user and wait for approval before proceeding.

**Gate 3: Contract Integrity**

Schema checks (run inline):
- [ ] Every stage boundary has an artifact
- [ ] Every artifact has all required fields: name, boundary, content, structure, identity_fields, omitted, validation, reasoning_trace
- [ ] No orphan artifacts (every artifact is produced by one stage and consumed by at least one)
- [ ] Any artifact consumed by an Emit stage includes idempotency markers

Identity checks (run inline):
- [ ] Every stage name in artifact boundaries matches a stage in `loop-workspace/stages.md`
- [ ] Every artifact name is unique

**On gate failure** (Loop 3: Contract Correction):
- Route to: Phase 3
- Carry: specific integrity violations
- Max retries: 2
- Degradation: track violation count
- Escalation: abort pipeline (broken contracts make downstream phases unreliable)

**Gate 4: Re-grounding** (runs only after Gate 3 passes)

Semantic check (delegate to the `loop-gate-checker` subagent — Agent tool, `subagent_type: "loop-gate-checker"`):

> You are a re-grounding reviewer. Read `loop-workspace/transformation.md` and `loop-workspace/artifacts.md`. Check whether the artifact chain faithfully represents the transformation definition. Look for structural drift (stages don't match the transformation's intent) and contractual drift (artifact contracts don't capture what the transformation requires). Report whether drift is structural or contractual with specific evidence.

**On gate failure** (Loop 4: Re-grounding Correction):
- Route to: Phase 2 if structural drift, Phase 3 if contractual drift
- Carry: drift evidence from the re-grounding evaluator
- Max retries: 1 (re-grounding fires at most once)
- After re-routing to Phase 2 or 3, re-run all subsequent phases through Gate 4
- Escalation: present drift findings to user and proceed

Track that re-grounding has fired. Do not run Gate 4 again after its correction loop completes — proceed regardless of the re-run outcome.

---

### Phase 4 and Phase 5 (parallel)

Run these two phases in parallel. They share the same inputs (`loop-workspace/stages.md` + `loop-workspace/artifacts.md`) and have no dependency between them.

#### Phase 4: Budget Context

**If inline** (phase 4 is in `inline_phases`):

Read the stage file at `loop/stages/budget-context.md`, the input contracts at `loop/contracts/stage-decomposition.md` and `loop/contracts/artifact-specifications.md`, and the output contract at `loop/contracts/context-specifications.md`. Read the input artifacts from `loop-workspace/stages.md` and `loop-workspace/artifacts.md`. Work through context budgets collaboratively:
- Present proposed context windows and token budgets per stage
- Discuss trade-offs: what information each stage truly needs vs. what can be summarized or omitted
- Write the agreed result to `loop-workspace/context-specs.md`

**If delegated** (phase 4 is not in `inline_phases`):

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/budget-context.md`. Read the input contracts at `loop/contracts/stage-decomposition.md` and `loop/contracts/artifact-specifications.md`. Read the output contract at `loop/contracts/context-specifications.md`. Read the input artifacts from `loop-workspace/stages.md` and `loop-workspace/artifacts.md`. Write the output artifact to `loop-workspace/context-specs.md`.

After the subagent completes, read `loop-workspace/context-specs.md` to verify it exists and is non-empty. Present the artifact to the user.

**No gate.** Context specs don't cascade — errors are caught by the final review.

#### Phase 5: Place Gates

**If inline** (phase 5 is in `inline_phases`):

Read the stage file at `loop/stages/place-gates.md`, the input contracts at `loop/contracts/stage-decomposition.md` and `loop/contracts/artifact-specifications.md`, and the output contract at `loop/contracts/gate-specifications.md`. Read the input artifacts from `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, and `loop-workspace/transformation.md`. The pipeline interaction level is: [pipeline-interaction-level]. Work through gate placement collaboratively:
- Propose gate positions and types for each stage boundary
- Discuss which boundaries need gates vs. which can be ungated (with rationale)
- Surface domain guidelines from `transformation.md` at each boundary — reframe them as validation criteria and encode them in gate specs
- Write the agreed result to `loop-workspace/workflows/<workflow-name>/gates.md`

**If delegated** (phase 5 is not in `inline_phases`):

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/place-gates.md`. Read the input contracts at `loop/contracts/stage-decomposition.md` and `loop/contracts/artifact-specifications.md`. Read the output contract at `loop/contracts/gate-specifications.md`. Read the input artifacts from `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, and `loop-workspace/transformation.md`. The pipeline interaction level is: [pipeline-interaction-level]. The workflow name is: [workflow-name]. Write the output artifact to `loop-workspace/workflows/<workflow-name>/gates.md`.

After the subagent completes, read `loop-workspace/workflows/<workflow-name>/gates.md` to verify it exists and is non-empty. Present the artifact to the user.

**Gate 5: Gate Referential Integrity**

Schema checks (run inline):
- [ ] Every gate has all required fields: name, position, artifact_checked, type, criteria, on_failure.routes_to, on_failure.carries, on_failure.max_retries, on_failure.escalation
- [ ] Every gate type is from the enum: Schema, Metric, Identity, Semantic, Consensus, Human
- [ ] Every `max_retries` is greater than 0
- [ ] Every `escalation` is non-empty
- [ ] Every artifact boundary has a gate or an ungated boundary with rationale

Identity checks (run inline):
- [ ] Every `artifact_checked` matches an artifact name in `loop-workspace/artifacts.md`
- [ ] Every `routes_to` matches a stage name in `loop-workspace/stages.md`

**On gate failure** (Loop 5: Gate Correction):
- Route to: Phase 5
- Carry: specific referential integrity violations
- Max retries: 2
- Degradation: track violation count
- Escalation: abort pipeline

Wait for both Phase 4 and Phase 5 (including Gate 5) to complete before proceeding.

---

### Phase 6: Design Feedback

**If inline** (phase 6 is in `inline_phases`):

Read the stage file at `loop/stages/design-feedback.md`, the input contracts at `loop/contracts/stage-decomposition.md`, `loop/contracts/artifact-specifications.md`, and `loop/contracts/gate-specifications.md`, and the output contract at `loop/contracts/loop-specifications.md`. Read the input artifacts from `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, and `loop-workspace/workflows/<workflow-name>/gates.md`. Work through feedback loop design collaboratively:
- Propose where feedback loops should exist and their type (balancing vs. reinforcing)
- Discuss loop caps and degradation detection strategies
- Write the agreed result to `loop-workspace/workflows/<workflow-name>/loops.md`

**If delegated** (phase 6 is not in `inline_phases`):

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/design-feedback.md`. Read the input contracts at `loop/contracts/stage-decomposition.md`, `loop/contracts/artifact-specifications.md`, and `loop/contracts/gate-specifications.md`. Read the output contract at `loop/contracts/loop-specifications.md`. Read the input artifacts from `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, and `loop-workspace/workflows/<workflow-name>/gates.md`. The workflow name is: [workflow-name]. Write the output artifact to `loop-workspace/workflows/<workflow-name>/loops.md`.

After the subagent completes, read `loop-workspace/workflows/<workflow-name>/loops.md` to verify it exists and is non-empty. Present the artifact to the user.

**No gate.** Design Feedback flows directly into Review, which catches loop anti-patterns.

---

### Phase 7: Review Design

**If inline** (phase 7 is in `inline_phases`):

Read the stage file at `loop/stages/review-design.md` and the output contract at `loop/contracts/review-results.md`. Read all workspace artifacts: `loop-workspace/transformation.md`, `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, `loop-workspace/context-specs.md`, `loop-workspace/workflows/<workflow-name>/gates.md`, `loop-workspace/workflows/<workflow-name>/loops.md`. Conduct the review collaboratively:
- Walk through the design with the user, presenting findings as you go
- Discuss any anti-patterns or issues found and their severity
- Collaborate on the verdict and any corrections needed
- Write the review to `loop-workspace/workflows/<workflow-name>/review.md`

**If delegated** (phase 7 is not in `inline_phases`):

Delegate to the `loop-stage-runner` subagent (Agent tool, `subagent_type: "loop-stage-runner"`):

> Read the stage file at `loop/stages/review-design.md`. Read the output contract at `loop/contracts/review-results.md`. Read all workspace artifacts: `loop-workspace/transformation.md`, `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, `loop-workspace/context-specs.md`, `loop-workspace/workflows/<workflow-name>/gates.md`, `loop-workspace/workflows/<workflow-name>/loops.md`. The workflow name is: [workflow-name]. Write the review to `loop-workspace/workflows/<workflow-name>/review.md`.

After the subagent completes, read `loop-workspace/workflows/<workflow-name>/review.md` to verify it exists. Present the review findings to the user.

**Evaluate the review verdict:**

- **PASS**: Proceed to completion.
- **PASS_WITH_WARNINGS**: Present warnings to the user at `minimal` or `per-stage`. At `none`, log warnings and proceed.
- **FAIL**: Enter Review Correction loop.

**Review Correction** (Loop 6):

Route each ERROR finding to its responsible stage based on the anti-pattern or issue type:

| Finding type | Route to |
|---|---|
| Kitchen Sink Stage | Phase 2 (Decompose) |
| Echo Chamber Loop | Phase 6 (Design Feedback) |
| History Avalanche | Phase 4 (Budget Context) |
| Phantom Feedback Loop | Phase 5 (Place Gates) or Phase 6 (Design Feedback) |
| Hardcoded Chain | Phase 2 (Decompose) |
| Ouroboros | Phase 6 (Design Feedback) |
| Telephone Game | Phase 3 (Specify Artifacts) |
| Fire-and-Forget Emit | Phase 3 (Specify Artifacts) or Phase 5 (Place Gates) |
| Referential integrity | The phase that produces the broken reference |
| Completeness gap | The phase responsible for the missing element |

For each correction:
1. Re-run the routed phase using its configured execution mode (inline or delegated), passing the review finding as feedback. For inline phases, present the finding to the user and collaborate on the fix. For delegated phases, include the finding in the subagent prompt.
2. Re-run all downstream phases and gates that depend on the corrected artifact.
3. Track inference calls against the cascade budget (max 10 per review cycle).
4. If the cascade budget is exhausted, stop corrections for this cycle and re-run review.

Max review cycles: 3. Degradation: track total ERROR count across cycles. If ERROR count does not decrease, stop and present the best review result to the user.

After the review correction loop completes (or on PASS/PASS_WITH_WARNINGS), the per-workflow review is done.

---

### Cross-Workflow Consistency (conditional)

If there are multiple workflows in `loop-workspace/workflows/`, run a cross-workflow consistency check after all per-workflow reviews pass. Delegate to the `loop-gate-checker` subagent (Agent tool, `subagent_type: "loop-gate-checker"`):

> Read the stage file at `loop/stages/review-design.md`. Read the output contract at `loop/contracts/review-results.md`. Read all workspace artifacts: `loop-workspace/transformation.md`, `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, `loop-workspace/context-specs.md`. For each workflow directory in `loop-workspace/workflows/`, read gates.md, loops.md, and review.md. Write the cross-workflow review to `loop-workspace/review.md`. Focus on: conflicting gate criteria across workflows, inconsistent loop caps, shared stages with incompatible context specs.

---

## Resumption

The execution manifest is the primary resumption mechanism. On resumption:

- Skip phases with `status: complete` in the manifest
- For `in_progress` phases: check if the output artifact exists and is valid — if yes, mark complete in the manifest and skip; if no, restart the phase
- Restore loop iteration counts from the manifest (don't reset to 0)
- Restore cascade budget from the manifest (don't reset to full)
- Don't re-ask human decisions already recorded in `decisions[]`
- Restore `re_grounding_fired` from the manifest

**Fallback** (no manifest, workspace artifacts exist): Use artifact presence to determine the resume point:

| Artifact | If present, skip to |
|---|---|
| `loop-workspace/transformation.md` | Phase 2 |
| `loop-workspace/stages.md` | Phase 3 |
| `loop-workspace/artifacts.md` | Phase 4+5 (parallel) |
| `loop-workspace/context-specs.md` AND `loop-workspace/workflows/<name>/gates.md` | Phase 6 |
| `loop-workspace/workflows/<name>/loops.md` | Phase 7 |
| `loop-workspace/workflows/<name>/review.md` | Pipeline complete |

Warn: "No execution manifest found. Resuming from artifact presence — loop iteration counts, cascade budgets, and human decisions could not be restored."

## Error Handling

**Stage failure (subagent errors out or inline execution fails)**: Read whatever partial output exists in the workspace. Present the error to the user. Offer to retry the failed phase or abort. The workspace preserves all completed artifacts.

**Human escalation**: When a gate escalates to human review, present the artifact and the specific problem clearly. Wait for the user's decision: fix and retry, accept with warning, or abort.

**Pipeline abort**: Preserve the workspace and execution manifest as-is. The manifest records exactly where execution stopped. Re-invoking `/loop:design` will read the manifest and offer precise resumption.

**Cascade budget exhaustion**: If a review correction cycle exhausts the 10-call cascade budget before all corrections are applied, stop corrections, re-run Phase 7 review on whatever was corrected, and report remaining issues. The manifest's `cascade_budgets[].used` field persists across sessions — if the pipeline is interrupted during a cascade, the budget is not reset on resumption.

## Pipeline Run Summary

After the pipeline completes, derive the summary from the execution manifest and report:

- **Artifacts produced**: List all files written to `loop-workspace/` with their paths
- **Gate results**: For each gate, pass/fail and retry count (from `gates[].attempts` in the manifest)
- **Loop iterations**: For each loop that fired, iteration count and outcome (from `loops[]` in the manifest)
- **Cascade budget**: Calls used per review cycle (from `cascade_budgets[]`)
- **Human decisions**: Decisions made during the run (from `decisions[]`)
- **Review verdict**: Final verdict and any remaining warnings
- **Total run duration**: From manifest `started_at` to final `updated_at`

## Guidance

### Inline execution
- For inline phases, read the stage file and contracts yourself, then work through the transformation in conversation with the user. The stage file defines what to do; the contracts define input/output structure. Follow them the same way a subagent would, but engage the user at decision points.
- Inline phases still produce the same artifacts to the same paths. The artifact flow is identical regardless of execution mode — only the process changes.
- When re-running an inline phase during a correction loop, present the gate failure feedback to the user and collaborate on the fix.

### Delegated execution
- For delegated phases, use the `loop-stage-runner` subagent for context isolation. The subagent sees only the stage file, relevant contracts, and input artifacts.
- After a delegated phase completes, always present the artifact to the user before proceeding.
- When re-running a delegated phase during a correction loop, include the gate failure feedback in the subagent prompt.

### General
- Run semantic gates in the `loop-gate-checker` subagent with clean context, regardless of execution mode. Do not evaluate a stage's output in the same context that produced it.
- Gates are checkpoints, not bottlenecks. Run schema and identity checks inline. Reserve `loop-gate-checker` delegation for semantic checks only.
- Track degradation across loop iterations. A loop that is not improving is wasting inference budget.
- Preserve workspace artifacts. Never delete or overwrite artifacts from completed phases unless re-running that phase as part of a correction loop.
- Report progress to the user between phases. After each phase, state what was completed, any gate results, and what comes next.
- Stages 4 and 5 are the only parallel opportunity in delegated mode. When both are inline, run them sequentially (parallel conversation is not possible). When both are delegated, run them in parallel.
