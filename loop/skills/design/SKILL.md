---
description: "Workflow: full Loop design pipeline — takes a task description and produces a complete pipeline design with stages, artifacts, context budgets, gates, loops, and review."
interaction: plan
---

# Loop: Design Pipeline

Orchestrate the complete design pipeline. Take a task description and produce a full Loop pipeline design by sequencing stages 1-7, enforcing gates, managing feedback loops, and handling failures. Each stage runs in an isolated subagent. The orchestrator's job is sequencing, gate checking, loop management, and progress reporting.

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
- **Interaction level**: `minimal` (default), `per-stage`, or `none`.
  - `minimal`: Human review only when gates flag uncertainty or ambiguity.
  - `per-stage`: Present every stage's output to the user before proceeding.
  - `none`: Fully automated, no human checkpoints.
- **Workflow name**: Name for this workflow (used for workflow-scoped artifacts under `loop-workspace/workflows/<name>/`). Default: `design`.

## Preconditions

Check whether `loop-workspace/` already contains artifacts. If artifacts exist, present the resumption table (see Resumption Table below) and ask the user whether to resume from the next incomplete phase or start fresh. If starting fresh, confirm before deleting existing artifacts.

No external dependencies are required.

## Execution

### Shared Paths

- **Stage files**: `loop/stages/`
- **Contract files**: `loop/contracts/`
- **Workspace**: `loop-workspace/`
- **Workflow directory**: `loop-workspace/workflows/<workflow-name>/`

Create `loop-workspace/` and `loop-workspace/workflows/<workflow-name>/` if they do not exist.

### State Tracking

Maintain these counters across the pipeline run:

- Per-gate: pass/fail counts, retry counts
- Per-loop: iteration counts, degradation signals per iteration
- Cascade budget for review correction: inference calls remaining (resets to 10 each review cycle)
- Re-grounding fired: boolean (Gate 4 can only fire once)

---

### Phase 1: Define Transformation

Delegate to a subagent with this prompt:

> Read the stage file at `loop/stages/define-transformation.md`. Read the output contract at `loop/contracts/transformation-definition.md`. The task description is: [task description]. The interaction level is: [level]. Write the output artifact to `loop-workspace/transformation.md`.

After the subagent completes, read `loop-workspace/transformation.md` to verify it exists and is non-empty.

At `per-stage` interaction: present the transformation definition to the user and wait for approval before proceeding.

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

Delegate to a subagent:

> Read the stage file at `loop/stages/decompose-stages.md`. Read the input contract at `loop/contracts/transformation-definition.md` and the output contract at `loop/contracts/stage-decomposition.md`. Read the input artifact from `loop-workspace/transformation.md`. Write the output artifact to `loop-workspace/stages.md`.

After the subagent completes, read `loop-workspace/stages.md` to verify it exists and is non-empty.

At `per-stage` interaction: present the stage decomposition to the user before proceeding.

**Gate 2: Decomposition Validity**

Schema checks (run inline):
- [ ] All required fields present on every stage
- [ ] Every `category` is from the enum: Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit
- [ ] Every stage name is unique
- [ ] Stage count matches the overview

Metric checks (run inline):
- [ ] Stage count is between 2 and 15
- [ ] Every stage intent is a single verb phrase (no conjunctions — no "and", "then", semicolons)

Semantic check (delegate to a dedicated subagent with clean context):

> You are a design reviewer. Read `loop-workspace/stages.md`. Check for: (1) Kitchen Sink — any stage whose intent has conjunctions, whose complexity notes exceed 3 sentences, or that requires multiple distinct cognitive operations. (2) Ordering — stages follow narrow-before-wide, fail-fast, cheap-before-expensive, emit-last principles. (3) Gap coverage — every difficulty in `loop-workspace/transformation.md`'s gap analysis maps to at least one stage. Report violations with specific stage names and reasons.

**On gate failure** (Loop 2: Decomposition Correction):
- Route to: Phase 2
- Carry: specific violations (which stages, which checks failed)
- Max retries: 3 (including semantic retry)
- Degradation: track violation count; if it does not decrease across consecutive iterations, stop and use best iteration
- Escalation: present decomposition with warnings and proceed

---

### Phase 3: Specify Artifacts

Delegate to a subagent:

> Read the stage file at `loop/stages/specify-artifacts.md`. Read the input contract at `loop/contracts/stage-decomposition.md` and the output contract at `loop/contracts/artifact-specifications.md`. Read the input artifact from `loop-workspace/stages.md`. Write the output artifact to `loop-workspace/artifacts.md`.

After the subagent completes, read `loop-workspace/artifacts.md` to verify it exists and is non-empty.

At `per-stage` interaction: present the artifact specifications to the user before proceeding.

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

Semantic check (delegate to a dedicated subagent with clean context):

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

Delegate to a subagent:

> Read the stage file at `loop/stages/budget-context.md`. Read the input contracts at `loop/contracts/stage-decomposition.md` and `loop/contracts/artifact-specifications.md`. Read the output contract at `loop/contracts/context-specifications.md`. Read the input artifacts from `loop-workspace/stages.md` and `loop-workspace/artifacts.md`. Write the output artifact to `loop-workspace/context-specs.md`.

After the subagent completes, read `loop-workspace/context-specs.md` to verify it exists and is non-empty.

At `per-stage` interaction: present context specifications to the user.

**No gate.** Context specs don't cascade — errors are caught by the final review.

#### Phase 5: Place Gates

Delegate to a subagent:

> Read the stage file at `loop/stages/place-gates.md`. Read the input contracts at `loop/contracts/stage-decomposition.md` and `loop/contracts/artifact-specifications.md`. Read the output contract at `loop/contracts/gate-specifications.md`. Read the input artifacts from `loop-workspace/stages.md` and `loop-workspace/artifacts.md`. The interaction level is: [level]. The workflow name is: [workflow-name]. Write the output artifact to `loop-workspace/workflows/<workflow-name>/gates.md`.

After the subagent completes, read `loop-workspace/workflows/<workflow-name>/gates.md` to verify it exists and is non-empty.

At `per-stage` interaction: present gate specifications to the user.

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

Delegate to a subagent:

> Read the stage file at `loop/stages/design-feedback.md`. Read the input contracts at `loop/contracts/stage-decomposition.md`, `loop/contracts/artifact-specifications.md`, and `loop/contracts/gate-specifications.md`. Read the output contract at `loop/contracts/loop-specifications.md`. Read the input artifacts from `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, and `loop-workspace/workflows/<workflow-name>/gates.md`. The workflow name is: [workflow-name]. Write the output artifact to `loop-workspace/workflows/<workflow-name>/loops.md`.

After the subagent completes, read `loop-workspace/workflows/<workflow-name>/loops.md` to verify it exists and is non-empty.

At `per-stage` interaction: present loop specifications to the user.

**No gate.** Design Feedback flows directly into Review, which catches loop anti-patterns.

---

### Phase 7: Review Design

Delegate to a subagent:

> Read the stage file at `loop/stages/review-design.md`. Read the output contract at `loop/contracts/review-results.md`. Read all workspace artifacts: `loop-workspace/transformation.md`, `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, `loop-workspace/context-specs.md`, `loop-workspace/workflows/<workflow-name>/gates.md`, `loop-workspace/workflows/<workflow-name>/loops.md`. The workflow name is: [workflow-name]. Write the review to `loop-workspace/workflows/<workflow-name>/review.md`.

After the subagent completes, read `loop-workspace/workflows/<workflow-name>/review.md` to verify it exists.

At `per-stage` or `minimal` interaction: present the review findings to the user.

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
1. Re-run the routed phase, passing the review finding as feedback to the subagent prompt.
2. Re-run all downstream phases and gates that depend on the corrected artifact.
3. Track inference calls against the cascade budget (max 10 per review cycle).
4. If the cascade budget is exhausted, stop corrections for this cycle and re-run review.

Max review cycles: 3. Degradation: track total ERROR count across cycles. If ERROR count does not decrease, stop and present the best review result to the user.

After the review correction loop completes (or on PASS/PASS_WITH_WARNINGS), the per-workflow review is done.

---

### Cross-Workflow Consistency (conditional)

If there are multiple workflows in `loop-workspace/workflows/`, run a cross-workflow consistency check after all per-workflow reviews pass. Delegate to a subagent:

> Read the stage file at `loop/stages/review-design.md`. Read the output contract at `loop/contracts/review-results.md`. Read all workspace artifacts: `loop-workspace/transformation.md`, `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, `loop-workspace/context-specs.md`. For each workflow directory in `loop-workspace/workflows/`, read gates.md, loops.md, and review.md. Write the cross-workflow review to `loop-workspace/review.md`. Focus on: conflicting gate criteria across workflows, inconsistent loop caps, shared stages with incompatible context specs.

---

## Resumption Table

When invoked, check `loop-workspace/` for existing artifacts:

| Artifact | If present, skip to |
|---|---|
| `loop-workspace/transformation.md` | Phase 2 |
| `loop-workspace/stages.md` | Phase 3 |
| `loop-workspace/artifacts.md` | Phase 4+5 (parallel) |
| `loop-workspace/context-specs.md` AND `loop-workspace/workflows/<name>/gates.md` | Phase 6 |
| `loop-workspace/workflows/<name>/loops.md` | Phase 7 |
| `loop-workspace/workflows/<name>/review.md` | Pipeline complete |

Use the latest present artifact to determine the resumption point. Present the current state and ask: "Resume from [next phase], or start fresh?"

## Error Handling

**Stage failure (subagent errors out)**: Read whatever partial output exists in the workspace. Present the error to the user. Offer to retry the failed phase or abort. The workspace preserves all completed artifacts.

**Human escalation**: When a gate escalates to human review, present the artifact and the specific problem clearly. Wait for the user's decision: fix and retry, accept with warning, or abort.

**Pipeline abort**: Preserve the workspace as-is. Re-invoking `/loop:design` will detect existing artifacts and offer resumption.

**Cascade budget exhaustion**: If a review correction cycle exhausts the 10-call cascade budget before all corrections are applied, stop corrections, re-run Phase 7 review on whatever was corrected, and report remaining issues.

## Pipeline Run Summary

After the pipeline completes, report:

- **Artifacts produced**: List all files written to `loop-workspace/` with their paths
- **Gate results**: For each gate, pass/fail and retry count
- **Loop iterations**: For each loop that fired, iteration count and outcome (converged, degraded, hit cap)
- **Review verdict**: Final verdict and any remaining warnings
- **Total inference calls**: Approximate count of subagent delegations

## Guidance

- Delegate each stage to a subagent for context isolation. The subagent sees only the stage file, relevant contracts, and input artifacts — not the orchestrator's reasoning or prior stages' reasoning.
- Run semantic gates in dedicated subagents with clean context. Do not evaluate a stage's output in the same context that produced it.
- Gates are checkpoints, not bottlenecks. Run schema and identity checks inline. Reserve subagent delegation for semantic checks only.
- Track degradation across loop iterations. A loop that is not improving is wasting inference budget.
- Preserve workspace artifacts. Never delete or overwrite artifacts from completed phases unless re-running that phase as part of a correction loop.
- Report progress to the user between phases. Long pipelines need visibility. After each phase, state what was completed, any gate results, and what comes next.
- When re-running a phase during a correction loop, include the gate failure feedback in the subagent prompt so the stage knows what to fix.
- Stages 4 and 5 are the only parallel opportunity. All other stages must run sequentially due to data dependencies.
