---
description: "Review a complete pipeline design for anti-patterns, missing gates, unbounded loops, and context issues. Use after completing the design workflow, or anytime on an existing pipeline spec to audit it."
---

# Loop: Review Pipeline Design

Audit a complete (or partial) pipeline design against anti-patterns and design quality checks.

## Input

Read all files in `loop-workspace/`. This skill works with whatever exists — it doesn't require every upstream skill to have run. It checks what's there and flags what's missing.

## What You Produce

A review file containing an issues list with severity, location, and suggested fixes.

**Output location:**
- If reviewing only stage-level artifacts (no workflows exist): write `loop-workspace/review.md`
- If reviewing a specific workflow: write `loop-workspace/workflows/<name>/review.md` (includes both stage-level and workflow-level findings)
- If reviewing multiple workflows: write a review file per workflow

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

Note what's present and what's missing. Missing files are findings (severity: info).

### Step 2: Run anti-pattern checks

Read `loop/anti-patterns.md` for the full anti-pattern catalogue (8 anti-patterns with definitions, check criteria, and severity guidelines).

Apply each anti-pattern check to the **design artifacts**. For each check, evaluate the design specifications — stage intents, artifact contracts, gate criteria, loop configurations — not implementation code. Report findings with the severity levels specified in the catalogue.

The coverage requirement applies: address all 8 anti-patterns by name in the report. For clean checks, include an INFO-level confirmation.

### Step 3: Run structural quality checks

Read `loop/quality-checks.md` for the full list of structural quality dimensions.

Apply each quality check to the **design artifacts**. Focus on:

**Artifact completeness:**
- Does every stage boundary have an artifact spec?
- Does every artifact have a clear consumer?
- Are there artifact fields with no downstream consumer? (Over-specification)

**Gate coverage:**
- Are there stages with high uncertainty and no downstream gate?
- Are there gates with no failure route or no max retries?
- For extraction or synthesis stages: do gates check *completeness* (did the stage capture everything?), or only *correctness*? Flag extraction/synthesis boundaries without a coverage metric.

**Sink safety**, **precondition coverage**, **context isolation**, **loop safety**, **stochastic validation**, **context hygiene**, **implementation structure**, **handoff drift resilience** — apply the check criteria from `loop/quality-checks.md` to the design specifications.

### Step 4: Estimate cost per workflow

For each workflow, calculate inference call counts:

- **Base**: count the stages in the workflow's sequence
- **Gates**: +1 for each semantic gate, +N for each consensus gate. Schema, metric, identity, and human gates cost zero inference.
- **Loops (best case)**: +0 if termination can trigger on first pass
- **Loops (worst case)**: stages in the loop × max iteration count
- **Sink costs**: external API calls per input, including duplicated writes from loop re-entry through Emit stages

Report as a range: `best case – worst case calls per input`. Flag workflows where worst case is more than 3× best case.

If the pipeline will process a batch, multiply by batch size and note the aggregate.

### Step 5: Write the review

Write the review file:

```markdown
# Pipeline Design Review

## Summary
- **Files reviewed**: [list]
- **Missing files**: [list, if any]
- **Issues found**: [count by severity]

## Issues

### [ERROR | WARNING | INFO]: [Issue title]
- **Location**: [File and section]
- **Anti-pattern**: [Name, if applicable]
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

- **Be direct, not diplomatic.** If the pipeline has a serious design flaw, say so clearly.
- **Don't re-design.** Flag issues and point to the right skill to fix them. The review skill identifies problems; the other skills solve them.
- **Clean pipelines exist.** Not every review must find issues. A well-designed 3-stage linear pipeline with appropriate gates may genuinely have no problems.
- **Partial reviews are fine.** If only `stages.md` and `artifacts.md` exist, review what's there. Note what's missing but don't block on it.
