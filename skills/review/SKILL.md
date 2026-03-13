---
name: review
description: "Review a complete pipeline design for anti-patterns, missing gates, unbounded loops, and context issues. Use after completing the design workflow, or anytime on an existing pipeline spec to audit it."
---

# Loop: Review Pipeline Design

Audit a complete (or partial) pipeline design against the Loop framework's anti-pattern catalogue and design principles.

## Input

Read all files in `loop-workspace/`. This skill works with whatever exists — it doesn't require every upstream skill to have run. It checks what's there and flags what's missing.

## What You Produce

A review file containing an issues list with severity, location, and suggested fixes.

**Output location:**
- If reviewing only stage-level artifacts (no workflows exist): write `loop-workspace/review.md`
- If reviewing a specific workflow: write `loop-workspace/workflows/<name>/review.md` (includes both stage-level and workflow-level findings for that workflow)
- If reviewing multiple workflows: write a review file per workflow, since gate and loop issues are workflow-scoped

## How to Run

### Step 1: Inventory what exists

**Stage-level artifacts** in `loop-workspace/`:
- `transformation.md` — transformation definition
- `stages.md` — stage decomposition
- `artifacts.md` — artifact specifications
- `context-specs.md` — context budgets

**Workflow-level artifacts** in `loop-workspace/workflows/<name>/`:
- `gates.md` — gate specifications (per workflow)
- `loops.md` — feedback loop specifications (per workflow)

Check for multiple workflows. If workflows exist, review each. If no workflows exist, review stage-level artifacts only.

Note what's present and what's missing. Missing files are findings (severity: info) — the pipeline may be intentionally incomplete, or the designer may have skipped a step.

### Step 2: Run anti-pattern checks

Check for each anti-pattern:

**6.1 Kitchen Sink Stage**
- For each stage in `stages.md`: does the intent contain multiple verbs?
- Does the stage span multiple categories (e.g., Extract + Evaluate)?
- Is the complexity note suggesting the stage is overloaded?
- **Severity**: warning if intent has 2 verbs, error if 3+

**6.2 Echo Chamber Loop**
- For each reinforcing loop in workflow `loops.md` files: is there a novelty gate or delta check?
- Is there a degradation detector?
- **Severity**: error if reinforcing loop has no novelty check

**6.3 History Avalanche**
- In `context-specs.md`: does any stage receive full upstream history?
- Do late-pipeline stages carry early-pipeline details without justification?
- **Severity**: warning if history included without justification, error if full history in 3+ stages

**6.4 Phantom Feedback Loop**
- For each loop: are the gate criteria specific enough to actually fail?
- Are there loops where the corrective path is cosmetic (no substantive change)?
- **Severity**: warning

**6.5 Hardcoded Chain**
- In `stages.md`: does any stage's description reference a specific successor by name?
- Are stages coupled to a single workflow, or are they composable units?
- **Severity**: warning

**6.6 Ouroboros**
- Map all information flows. Are there circular dependencies spanning 3+ stages that aren't declared as intentional loops with termination conditions?
- **Severity**: error

**6.7 Telephone Game**
- Do artifacts rely on free-text interpretations rather than source references?
- Are there 5+ stages with no re-grounding checkpoint against the original input?
- Do artifacts mix observation and judgment in single fields?
- Are closed vocabularies (enums, scores) used where the domain allows, or do artifacts carry open-ended descriptions?
- **Severity**: warning if free-text fields dominate without source references; error if 5+ stages with no identity fields and no re-grounding

**6.8 Fire-and-Forget Emit**
- Are there Emit stages (stages with sink dependencies) that write to external targets?
- Do those stages have a gate *before* the write that validates the artifact thoroughly? A gate *after* a write can't undo it.
- Do Emit stages have idempotency markers (stable IDs, transaction references) to prevent duplicate writes on retry?
- If a gate failure or loop re-entry routes back through an Emit stage, can the write be safely repeated?
- Are notification sinks (Slack, email, webhooks) treated as fire-and-forget, or do they incorrectly block the pipeline on failure?
- **Severity**: error if emit stage has no upstream gate or no idempotency strategy; warning if loop routes back through emit stage without tight cap (≤3 iterations)

### Step 3: Run structural checks

Beyond anti-patterns, check design quality:

**Artifact completeness:**
- Does every stage boundary have an artifact spec?
- Does every artifact have a clear consumer?
- Are there artifact fields with no downstream consumer? (over-specification)

**Gate coverage:**
- Are there stages with high uncertainty and no downstream gate?
- Are there gates with no failure route defined?
- Are there gates with no max retries / escalation?
- For extraction or synthesis stages: do gates check *completeness* (did the stage capture everything it should have?), or only *correctness* (is what it produced valid?)? A schema gate that passes a list of 3 entities when there should be 10 is missing the omission. Flag extraction/synthesis boundaries without a coverage metric or source reconciliation check.

**Sink safety:**
- Do all stages with sink dependencies have gates *before* the write?
- Do Emit stages declare idempotency strategies for their sinks?
- Are notification sinks classified as fire-and-forget (non-blocking)?
- If a loop routes back through an Emit stage, is the iteration cap ≤3 and idempotency explicitly addressed?
- Are all sinks declared in `stages.md`? (Hidden sinks are a traceability risk — you can't test or audit what you don't know about.)

**Precondition coverage (for production workflows):**
- Do workflows with source or sink dependencies define preconditions that validate those dependencies before execution?
- Are preconditions classified as required vs. optional (degraded mode)?
- If no preconditions are defined but the pipeline has external dependencies, flag as INFO — the pipeline may fail mid-execution due to misconfigured integrations.
- If any stages are delegated to subagents (parallel workers, decompose-aggregate patterns), do the subagent prompts propagate relevant preconditions? Subagents run in isolated contexts and may lack tool access, network permissions, or MCP server connections that the main agent validated. Flag as WARNING if subagents depend on external resources but their prompts don't include re-validation instructions.

**Context isolation:**
- Does the design specify that stages run in subagents (fresh context), or does it assume the orchestrator executes stages in its own context? An orchestrator that runs stages inline accumulates every stage's working memory, defeating the purpose of staging. Flag as WARNING if the design doesn't explicitly require subagent delegation for stages.
- Do semantic gates run in dedicated subagents with clean context? A semantic gate evaluated in the same context as the producing stage is unreliable — the production trajectory biases the evaluation. Flag as WARNING if semantic gates are specified as inline evaluations.
- For balancing loops: when a stage is re-run with feedback, does the re-run happen in a fresh subagent? Re-running in the same context preserves the failed attempt's reasoning, which can anchor the retry to the same errors.

**Loop safety:**
- Does every loop have both semantic termination AND a hard cap?
- Does every loop have a degradation detector?
- Are any iteration caps unreasonably high (>10 for balancing, >5 for reinforcing, >3 for loops involving Emit stages)?
- For balancing loops (critique-refine): are the evaluator and refiner separate inference calls with separate contexts? If the same context handles both evaluation and refinement, the producing stage's trajectory biases the evaluation — this creates a reinforcing dynamic inside what should be a balancing loop.
- Does every loop with a degradation detector also specify a best-iteration selection strategy? When degradation is detected, the loop should use the best iteration's output, not the last one. If the spec says "always use last," flag it as a warning — the loop may end in a worse state than an earlier iteration.

**Stochastic validation:**
- LLM stages are stochastic — the same input can produce different outputs across runs. A pipeline has a *success rate*, not a pass/fail result. If the design assumes single-run validation is sufficient (or doesn't address validation at all), flag as INFO: the designer should plan for multi-run testing to characterize gate pass rates, loop iteration distributions, and output quality variance. A single test run cannot capture pipeline reliability.

**Context hygiene:**
- Is the default history policy "none" honored?
- Are context specs present for all stages?
- Are any stages carrying scaffolding that belongs to a different stage?

**Implementation structure:**
- Does the design assume or describe stages as independently invocable skills (each with its own slash command)? If so, flag as INFO: stages should be implemented as reference documents in a shared resource directory, not as standalone skills. `/loop:implement` produces a shared `<prefix>/` directory with `stages/` and `contracts/` subdirectories — stages are read by orchestrators at runtime, not invoked directly.
- Are there artifact schemas that would need to be duplicated across multiple stages? If so, note that `/loop:implement` addresses this via a shared `contracts/` directory — each schema defined once, referenced by all producers and consumers.

**Handoff drift resilience:**
- Do artifact specs use enums and closed vocabularies where the domain allows, or do they rely on free-text fields that invite reinterpretation?
- Do artifacts carry source references alongside any summary or interpretation fields, so downstream stages can verify?
- Are observation and judgment separated into distinct fields, or mixed in single fields?
- Do artifacts declare identity fields where appropriate? Are identity gates placed to verify them?
- For pipelines with 5+ stages: is there a re-grounding checkpoint that compares the current artifact against the original pipeline input?
- Do semantic gates run in a clean context separate from the producing stage?

### Step 4: Estimate cost per workflow

For each workflow, calculate inference call counts:

- **Base**: count the stages in the workflow's sequence
- **Gates**: +1 for each semantic gate, +N for each consensus gate (N = evaluator count). Schema, metric, identity, and human gates cost zero inference calls (human gates cost time, not inference).
- **Loops (best case)**: +0 if termination can trigger on first pass
- **Loops (worst case)**: for each loop, multiply the stages in the loop by the max iteration count
- **Sink costs**: external API calls, notification sends, and other write operations per input — including duplicated writes from loop re-entry if Emit stages are inside loops

Report as a range: `best case – worst case calls per input`. Flag workflows where the worst case is more than 3× the best case — this suggests the loop bounds may be too loose or the pipeline would benefit from tighter gates to reduce loop frequency.

If the pipeline will process a batch, multiply by batch size and note the aggregate. A workflow that costs 15 calls per input at $0.05/call processes 1000 inputs for $750 — the designer should know this before committing to the design.

### Step 5: Write the review


Write `loop-workspace/review.md`:

```markdown
# Pipeline Design Review

## Summary
- **Files reviewed**: [list]
- **Missing files**: [list, if any]
- **Issues found**: [count by severity]

## Issues

### [ERROR | WARNING | INFO]: [Issue title]
- **Location**: [File and section]
- **Anti-pattern**: [Name, if applicable — e.g., Kitchen Sink Stage, Echo Chamber Loop]
- **Finding**: [What's wrong]
- **Suggested fix**: [How to address it]
- **Skill to re-run**: [Which /loop:* skill addresses this, if any]

### [Next issue]
...

## Cost Estimate
<!-- Per workflow: best-case and worst-case inference calls per input. -->
<!-- Flag if worst case is >3× best case. -->

## Pipeline Health
<!-- Overall assessment: is this pipeline ready to implement, -->
<!-- or does it need another pass through specific skills? -->
<!-- Be direct — if there are errors, say so. -->
```

### Step 6: Present findings

Walk the user through the issues, starting with errors. For each, explain why it matters and what to do. If the pipeline is clean, say so — don't invent issues.

## Guidance

- **Be direct, not diplomatic.** If the pipeline has a serious design flaw, say so clearly. The point of review is to catch problems before implementation.
- **Don't re-design.** Flag issues and point to the right skill to fix them. The review skill identifies problems; the other skills solve them.
- **Clean pipelines exist.** Not every review must find issues. A well-designed 3-stage linear pipeline with appropriate gates may genuinely have no problems. Don't add complexity for its own sake.
- **Partial reviews are fine.** If only `stages.md` and `artifacts.md` exist, review what's there. Note what's missing but don't block on it.
