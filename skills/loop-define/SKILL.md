---
name: loop-define
description: "Define the overall transformation for a Loop pipeline — captures input, desired output, the gap between them, and initial complexity signals. Use when starting a new pipeline design or redefining an existing one."
argument-hint: "[task-description]"
---

# Loop: Define Transformation

Define the overall transformation for an LLM pipeline using the Loop framework. This is the entry point — it produces the transformation definition artifact that downstream skills (`/loop-decompose`, `/loop-artifacts`, etc.) consume.

## What You Produce

A file named `loop-workspace/transformation.md` containing:

1. **Task Statement** — what the pipeline does, in one sentence
2. **Input Specification** — what the pipeline receives (format, structure, variability, volume)
3. **Output Specification** — what the pipeline produces (format, structure, quality criteria)
4. **Transformation Gap** — what must happen to get from input to output (the hard parts)
5. **Complexity Signals** — early indicators of where staging, feedback loops, or special handling may be needed

## How to Run

### Step 1: Check for existing workspace

Look for `loop-workspace/` in the current project directory.

- **If `transformation.md` exists**: show the user what's there, ask if they want to revise or start fresh
- **If no workspace**: create `loop-workspace/`

### Step 2: Gather the task description

If `$ARGUMENTS` is provided, use it as the starting point. Otherwise, ask the user to describe the pipeline's purpose.

### Step 3: Walk through the worksheet

Ask the user these questions. Challenge vague or incomplete answers — cite the framework when pushing back. Do not fill in defaults silently.

**Input Specification:**
- What does the pipeline receive? (format, structure)
- How variable is the input? (always the same shape, or wildly different?)
- What's the volume? (a paragraph, a document, a corpus?)
- What quality issues might the input have? (missing fields, inconsistencies, noise)

**Output Specification:**
- What should the pipeline produce? (format, structure)
- What are the quality criteria? (How would you judge a good output vs. a bad one?)
- Who or what consumes the output? (human reader, downstream system, another LLM, external service via API/git/notification)

**Transformation Gap:**
- What's hard about getting from input to output?
- Where would a single LLM call struggle? (This surfaces natural decomposition points — flag them for `/loop-decompose`)
- Could a single well-prompted call handle the whole task? Assess using these signals:

  **Signals that a single call is sufficient** (pipeline adds overhead without benefit):
  - The task involves one transformation type (extract, evaluate, transform — not a combination)
  - Input and desired output both fit comfortably in a single context alongside instructions
  - The task doesn't require integrating information from multiple sources
  - Quality can be verified by inspecting the output directly (no intermediate validation needed)
  - Prior attempts with a single call produce acceptable results

  **Signals that staging is warranted** (decomposition needed):
  - A single call produces inconsistent results — sometimes good, sometimes missing key aspects
  - The task requires multiple distinct cognitive operations (e.g., extract *then* evaluate *then* report)
  - The input is large enough that instructions compete with source material for attention
  - Different parts of the task need different context (e.g., domain knowledge for extraction, style guides for formatting)
  - You need to validate intermediate results before proceeding

  When staging is warranted, each stage will run in a **fresh, isolated context** — it sees only its input artifact, stage instructions, and stage-specific scaffolding. No accumulated history from prior stages. This means the output artifact at each boundary must carry everything the next stage needs.

  **Human-in-the-loop is already a pipeline.** When working interactively with an LLM tool like Claude Code, the natural workflow — model transforms, human reviews, human decides what's next — is already a staged pipeline with human gates. If every stage's output will be reviewed by a human before the next stage runs, Loop's gate and loop machinery may be unnecessary. Loop adds value when the pipeline needs some automation: automated gates, feedback loops that iterate without human steering, or composition beyond linear steps.

  Flag this honestly — not every task needs staging. When in doubt, start with a single call. If it works reliably, stop.

- What domain knowledge is required?
- Where is correctness critical vs. best-effort acceptable?

**Complexity Signals** (assess, don't ask all of these — use judgment):
- Does the task require external information not in the input? (Sources — web, APIs, databases)
- Does the pipeline need to write results to external systems? (Sinks — APIs, git, Notion, Slack, databases) If so: what systems? Are there notification needs (e.g., alerting a human when a gate needs review)?
- Does quality depend on iterative refinement?
- Are there independent sub-tasks that could run in parallel?
- Is there a risk of the LLM reinforcing its own errors?

### Step 4: Write the artifact

Write `loop-workspace/transformation.md` using this structure:

```markdown
# Transformation Definition

## Task
<!-- One sentence: what does this pipeline do? -->

## Input
<!-- Format, structure, variability, volume, quality issues -->

## Output
<!-- Format, structure, quality criteria, consumer -->

## Gap Analysis
<!-- What's hard. Where single-pass fails. Domain knowledge needed. -->
<!-- Flag critical-correctness vs. best-effort areas. -->

## Complexity Signals
<!-- Which signals are present. These inform downstream skills. -->
<!-- Mark each: parallelisation opportunity, refinement need, -->
<!-- external knowledge dependency (sources), external write targets (sinks), -->
<!-- notification needs, error reinforcement risk -->
```

### Step 5: Summarise

Present a brief summary of the transformation definition. The user or a workflow skill (`/loop-wf-design`) determines what to run next.

## Guidance

- **Ask, don't assume.** If the user says "summarise documents," push: What kind of documents? What makes a good summary? Who reads it?
- **Flag decomposition hints.** When the user describes something that sounds like multiple transformations, note it — but don't decompose yet. That's `/loop-decompose`'s job.
- **Keep it grounded.** The transformation definition should describe what exists and what's needed, not prescribe implementation. No stages, no loops, no architecture yet.
- **Reference the framework.** When challenging a decision, point to the relevant principle — e.g., "Each stage should do one thing well. This sounds like it might need decomposition, which we'll handle in `/loop-decompose`."
