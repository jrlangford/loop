---
name: loop-gates
description: "Place validation checkpoints between pipeline stages for a named workflow — what can go wrong, what type of check catches it, where failures route, and what feedback they carry. Use after /loop-artifacts has produced artifact specifications."
argument-hint: "[workflow-name]"
---

# Loop: Place Gates

Design validation gates at artifact boundaries for a specific workflow. Gates are workflow-level — the same stages can have different gates in different workflows. Gates are the primary mechanism for preventing reinforcing loops from propagating errors downstream.

## Input

Read `loop-workspace/stages.md` and `loop-workspace/artifacts.md`. If either doesn't exist, tell the user which upstream skill to run.

`$ARGUMENTS` should provide the workflow name. If not provided, ask the user to name this workflow (e.g., "conservative", "exploratory", "production"). If only one workflow exists or is planned, "default" is acceptable.

## What You Produce

A file named `loop-workspace/workflows/<workflow-name>/gates.md` containing gate specifications for this workflow.

## How to Run

### Step 1: Identify candidate gate positions

Every artifact boundary is a candidate. But not every boundary needs a gate. Prioritise:

- **After stages where errors are costly** — if a bad artifact here corrupts everything downstream
- **After stages with high uncertainty** — extraction from unstructured input, LLM-based evaluation
- **Before stages that are expensive** — don't waste a costly synthesis on garbage input
- **At natural quality checkpoints** — where the artifact has clear pass/fail criteria

### Step 2: Walk through the gate worksheet for each position

For each gate, ask:

| Question | Why it matters |
|----------|----------------|
| What must be true for this artifact to proceed? | Defines the gate criteria |
| Does this gate check *completeness*, not just *correctness*? | Catches silent omission — valid but incomplete artifacts |
| What type of check is this? | Determines cost and reliability |
| On failure, which stage receives the feedback? | Defines the failure route |
| What information does the failure carry to that stage? | Shapes the retry prompt |
| What is the maximum number of retries before escalation? | Prevents infinite loops |

**Catching silent omission**: The most common failure that gates miss is not malformed output but *incomplete* output — an extraction stage that finds 3 of 10 entities, a summary that covers 2 of 5 key points. The artifact is structurally valid, so schema gates pass. The content looks reasonable, so semantic gates may pass too. If completeness matters at this boundary, choose one of these strategies:

- **Coverage metrics** — instruct the producing stage to include a coverage indicator (e.g., "extracted 7 entities from 12 paragraphs"), then add a metric gate checking that the ratio meets a minimum threshold.
- **Source-artifact reconciliation** — add a semantic gate that receives both the artifact *and* the original source material, so it can check what was missed. More expensive (the gate's context must include the source), but catches omissions that coverage metrics cannot.
- **Minimum cardinality checks** — for extraction stages where expected output size is roughly predictable, add a metric gate with a floor ("at least N entities" or "at least N% of input sections represented"). Catches gross omission cheaply.

### Step 3: Assign gate types

Layer checks — cheap deterministic checks first, expensive semantic checks only when needed:

| Type | When to use | Cost |
|------|-------------|------|
| **Schema** | Structural validation — required fields, valid JSON, correct types | Cheap, deterministic |
| **Metric** | Quantitative thresholds — word count, confidence score, coverage ratio | Cheap, deterministic |
| **Identity** | Verify identity fields from `artifacts.md` have not mutated — exact match or hash comparison | Cheap, deterministic |
| **Semantic** | Quality assessment requiring LLM judgment — "Does this summary capture the key points?" | Expensive, probabilistic |
| **Consensus** | Multiple independent evaluations must agree — for high-stakes artifacts | Very expensive |
| **Human** | Human review and decision — approval before irreversible action, judgment on ambiguous quality | Most reliable, least scalable |

**Identity field checks**: If the artifact spec declares identity fields, include an identity gate that verifies these fields against their expected values. Identity gates are cheap and catch drift that semantic gates might miss because it accumulates gradually.

**Human gates**: Reserve for high-stakes decisions where automated validation is insufficient — approval before irreversible actions, judgment calls on ambiguous quality. A common pattern is a mostly automated pipeline with selective human gates at critical decision points: automated schema and metric gates for routine validation, human gate before committing to an irreversible action. Layer them last: schema gates catch structural problems, metric gates catch quantitative failures, semantic gates catch quality issues, and human gates fire only when automated gates can't make the call.

**Challenge over-gating**: Not every boundary needs a gate. If the downstream stage can handle imperfect input gracefully, a gate may add cost without value. Ask: "What's the worst that happens if a bad artifact gets through here?"

**Challenge under-gating**: If the user says no gates are needed, push back at critical boundaries. Gates are the primary mechanism for preventing reinforcing loops from propagating errors downstream.

### Step 4: Ensure gate validation context

For each gate, consider where validation runs:

- **Schema, metric, and identity gates** are mechanical — they operate deterministically outside any LLM context. No drift risk.
- **Semantic gates** require an LLM to evaluate. The evaluating LLM should run in a **clean, minimal context** containing only the artifact, the validation criteria, and (where relevant) the original source material. It should **not** share context with the producing stage — doing so allows the producing stage's trajectory to bias the validation.

If a semantic gate needs to check whether an artifact faithfully represents source material, include the source material in the gate's context so it can compare directly, rather than relying on the producing stage's interpretation.

### Step 5: Design failure routes

Each gate failure must route to a stage that can fix the problem. Because LLM stages are stochastic, the failure routing should account for the difference between deterministic and probabilistic failures:

- **Schema/metric failures** are deterministic — the artifact is structurally wrong and will always fail. Route back to the producing stage with specific error details.
- **Semantic failures** are probabilistic — the artifact might pass if the gate or producing stage ran again. Before routing to a refine stage, consider whether a simple **retry** (re-run the producing stage with the same input) is worth attempting first. If the failure is marginal (quality score just below threshold), a retry may succeed without the cost of a full feedback loop. If the failure is clear-cut (major quality issues), route to refine with evaluator feedback.
- **Failure information must be actionable** — "failed validation" is useless; "missing required field: entities" is actionable

Flag any failure route that sends feedback to a stage that didn't produce the artifact — this is usually wrong unless there's a clear reason.

### Step 6: Write the artifact

Create the workflow directory if needed (`loop-workspace/workflows/<workflow-name>/`) and write `gates.md`:

```markdown
# Gate Specifications

## Gate: [Name] (after [Stage Name])
- **Position**: Between [Stage A] and [Stage B]
- **Artifact checked**: [Artifact name]
- **Type**: [Schema | Metric | Identity | Semantic | Consensus | Human]
- **Criteria**: [What must be true to pass]
- **On failure**:
  - **Routes to**: [Stage name]
  - **Carries**: [What feedback the failing stage receives]
  - **Max retries**: [N]
  - **Escalation**: [What happens after max retries — human review, skip, abort]

## Gate: [Name] (after [Stage Name])
...

## Ungated Boundaries
<!-- List boundaries where no gate is placed, with brief rationale -->
```

### Step 7: Summarise

Present the gate map. The user or a workflow skill (`/loop-wf-design`) determines what to run next.

## Guidance

- **Gates are not loops.** A gate checks an artifact; a loop is an iterative process. Gate failure may *trigger* a loop (retry), but the gate itself is a checkpoint. Loop design is `/loop-feedback`'s job.
- **Phantom Feedback Loop warning.** If a gate's criteria are so loose it never fails, it's a Phantom Feedback Loop — a loop that exists on the diagram but provides no actual corrective signal. Push for criteria that would actually catch real problems. If a gate almost never triggers its failure path, either tighten the criteria or remove the gate and its associated loop.
- **Escalation is required.** Every gate must answer "what happens after max retries?" Infinite retry is not an answer.
- **Re-grounding for long pipelines.** For pipelines with 5+ stages, consider adding a re-grounding gate — a checkpoint that reads the original pipeline input alongside the current artifact and flags divergence. This is an explicit balancing check against cumulative drift that no individual gate would detect because it accumulates gradually. Design it as a semantic gate whose context contains only the current artifact, the original pipeline input, and criteria for acceptable divergence. Place it at or after the midpoint of the pipeline. Re-grounding does not mean re-processing — it means comparing the current artifact's claims against the original input to surface where interpretation has shifted.
