---
name: phase-feedback
description: "Design explicit feedback loops for a named workflow — classify each as reinforcing or balancing, set termination conditions, and add degradation detectors. Use after /loop:phase-gates has placed validation checkpoints for this workflow."
argument-hint: "[workflow-name]"
---

# Loop: Design Feedback Loops

Design the explicit feedback connections for a specific workflow. Loops are workflow-level — the same stages can participate in a 10-iteration reinforcing loop in one workflow and a 2-iteration balancing loop in another. Every loop gets a declared type, termination condition, and degradation detector.

## Input

Read `loop-workspace/stages.md`, `loop-workspace/artifacts.md`, and the workflow's gate specs from `loop-workspace/workflows/<workflow-name>/gates.md`. If any are missing, tell the user which upstream skill to run.

`$ARGUMENTS` should provide the workflow name. If not provided, check `loop-workspace/workflows/` for existing workflows. If exactly one exists, use it. If multiple exist, ask the user which one. If none exist, tell the user to run `/loop:phase-gates <workflow-name>` first.

## What You Produce

A file named `loop-workspace/workflows/<workflow-name>/loops.md` containing loop specifications for this workflow.

## How to Run

### Step 1: Identify feedback connections

Look for backward edges — places where information flows from a later stage back to an earlier one. Sources:

- **Gate failure routes** from `gates.md` — each retry path is a potential balancing loop
- **Iterative refinement** flagged in `stages.md` complexity notes — critique-refine patterns
- **Progressive elaboration** — stages that might re-run with enriched context
- **Coverage gaps** — evaluate stages that route back to earlier stages for more work

### Step 2: Classify each loop

For each feedback connection, determine its type:

**Reinforcing (R)** — designed to amplify, deepen, or elaborate:
- Each iteration adds new information or enriches existing content
- Risk: unbounded elaboration, diminishing returns, echo chamber
- Requires: novelty gate, iteration bound

**Balancing (B)** — designed to correct, constrain, or converge:
- Each iteration reduces distance between artifact and desired state
- Risk: oscillation, phantom feedback, cosmetic-only fixes
- Requires: convergence criteria, degradation detector

Ask the user to declare intent for each loop. If they say "refinement" but describe elaboration, challenge it — the classification determines what safeguards are needed.

### Step 3: Design termination conditions

Every loop MUST have both:

1. **Semantic termination** — a condition that means "we're done" (all criteria pass, no new information added, convergence achieved)
2. **Hard iteration cap** — a maximum number of iterations, period. This fires even if the semantic condition has bugs.

Challenge missing or weak termination:
- "Until it's good enough" → what specifically makes it good enough? What metric or criteria?
- No iteration cap → every loop needs a maximum iteration count as a hard backstop, even if the semantic termination condition has bugs
- Cap too high → what's the cost of N iterations? Is that acceptable?

### Step 4: Design degradation detectors

Each loop needs a mechanism to detect when further iterations are making things worse. Because LLM stages are stochastic, a single iteration's decline may be normal variance rather than true degradation. Design detectors accordingly:

- **For balancing loops**: track quality scores across iterations. Don't trigger on a single decline — use consecutive regressions (score drops two or more iterations in a row) or a moving average. If the trend is downward, the refine step is introducing errors faster than fixing them. Also watch for oscillation (alternating good-bad-good-bad), which suggests the refine step is undoing previous improvements rather than building on them.
- **For reinforcing loops**: measure novelty between iterations. If the delta drops below threshold, stop — the loop is rephrasing, not enriching.

**Best-iteration selection**: When a degradation detector fires, the loop should use the *best* iteration's output, not necessarily the *last* one. If the loop tracks quality scores, it can select the iteration with the highest score. If it can't detect and select the best iteration's output, keep iteration bounds tight — more iterations mean more opportunities for the loop to end in a worse state than an earlier iteration. Ask the user: does this loop keep track of the best artifact across iterations, or does it always use the last one?

### Step 5: Check for Emit stage loop safety

If any loop involves an Emit stage (a stage with sink dependencies that writes to external systems), apply additional scrutiny:

- **Tight iteration caps**: Loops through Emit stages should have caps ≤3. Each iteration may write to the external system, so more iterations mean more risk of duplicate or conflicting writes.
- **Idempotency required**: The Emit stage must have an idempotency strategy (stable IDs, transaction references, overwrite semantics) so repeated writes don't create duplicates.
- **Pre-emit gating**: Ensure a gate validates the artifact *before* the Emit stage, not after. A gate failure after a write can't undo it.
- **Notification sinks are different**: If the sink is a notification (Slack, email, webhook), duplicate sends are annoying but not data-corrupting. Keep caps tight, but notification loops are lower risk than API/database writes.

### Step 6: Check for loop anti-patterns

Flag these if detected:

| Anti-pattern | Signal | Fix |
|-------------|--------|-----|
| **Echo Chamber** | Reinforcing loop without novelty gate — model elaborates endlessly, each iteration reinforcing previous patterns without adding value | Add novelty comparison between iterations; terminate when delta drops below threshold |
| **Phantom Feedback** | Loop that never triggers correction — gate criteria too loose, or refine step makes only cosmetic changes | Tighten criteria or remove the loop; monitor whether the corrective path actually fires |
| **Ouroboros** | Unintentional circular dependency across 3+ stages — emergent reinforcing dynamics no individual stage was designed to produce | Make the cycle explicit with termination, or break it |

### Step 7: Map to established patterns

For each loop, note which established pattern it implements. This grounds the design in known patterns and helps with implementation.

| Loop Pattern | Established Pattern | What Loop Adds |
|-------------|-------------------|----------------|
| Critique-refine | Evaluator-optimizer | Classification as balancing loop; degradation detection; structured failure routing |
| Progressive enrichment | Prompt chaining with feedback | Novelty gating; iteration bounds; echo chamber prevention |
| Consensus | Parallelisation with comparison | Framing as balancing dynamic; dispute resolution design |
| Decompose-aggregate | Orchestrator-workers | Framing as information rate management |

**Consensus loop design**: If the user's pipeline requires a consensus loop (multiple independent evaluations compared), walk through these considerations:
- Evaluators should have **different system prompts or perspectives** to avoid correlated errors. If all evaluators use the same prompt, they'll make the same mistakes.
- The comparison step should be **deterministic where possible** (majority vote, score averaging) rather than another LLM call. If a meta-evaluation LLM is needed, it should see only the evaluations, not the original artifact.
- Consensus loops are **expensive** — each iteration costs N evaluator calls plus comparison. Reserve for high-stakes artifacts where a single evaluation is insufficient.
- Dispute resolution: when evaluators disagree, the design must specify what happens — synthesise a reconciled view, escalate to a human, or accept the majority position.

**Decompose-aggregate design**: If the pipeline handles tasks whose information rate exceeds single-stage channel capacity, a decompose-aggregate structure may be needed. This is not a feedback loop per se, but a structural pattern that keeps individual stages within their effective capacity. Walk through:
- The decompose step must produce **independent or weakly-dependent** sub-tasks. If sub-tasks are tightly coupled (results of one affect interpretation of another), processing them independently loses critical interactions.
- The aggregate step must handle **contradictions** between independently processed sub-artifacts — they were produced without seeing each other's context, so conflicts are expected.
- This pattern **parallelises naturally** — sub-tasks can run concurrently since they share the same input and produce independent outputs.
- Model the decompose and aggregate steps as stages in `stages.md`. The parallel processing stages share the same input artifact. The aggregate stage takes all sub-artifacts as input.

### Step 8: Write the artifact

Write `loop-workspace/workflows/<workflow-name>/loops.md`:

```markdown
# Feedback Loop Specifications

## Loop: [Name]
- **Type**: [Reinforcing | Balancing]
- **Stages involved**: [Stage A] → [Stage B] → [Stage A]
- **Purpose**: [What this loop achieves]
- **Established pattern**: [Evaluator-optimizer | Prompt chaining | Parallelisation | Orchestrator-workers]
- **Termination**:
  - **Semantic**: [Condition that means "done"]
  - **Hard cap**: [Maximum iterations]
- **Degradation detector**: [How to detect things getting worse]
- **Best-iteration selection**: [How to select the best output if degradation is detected — e.g., track scores and use highest-scoring iteration, or always use last]
- **Anti-pattern risks**: [Which anti-patterns to watch for, if any]

## Loop: [Name]
...

## No-Loop Justification
<!-- If the pipeline has no loops, explain why. -->
<!-- Linear pipelines are valid when each stage reliably produces -->
<!-- good-enough output for the next. But confirm this is deliberate, -->
<!-- not an oversight. -->
```

### Step 9: Summarise

Present the loop map. The user or a workflow skill (`/loop:design`) determines what to run next.

## Guidance

- **Not every pipeline needs loops.** A linear pipeline where each stage reliably produces good output is simpler and cheaper. Don't add loops for their own sake. But if the user says "no loops needed," challenge: are there stages where quality is uncertain? Where iterative refinement would help?
- **Gate retries are loops.** If a gate failure routes back to a stage for retry, that's a balancing loop. It needs the same treatment: termination condition, iteration cap, degradation detection.
- **Separate evaluator and producer.** For balancing loops, the stage that evaluates and the stage that refines should be separate inference calls, ideally with separate system prompts. Using the same context for both creates a reinforcing dynamic — the producing stage's trajectory biases the evaluation. The evaluator should run in a clean context with only the artifact and evaluation criteria.
