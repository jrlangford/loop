---
name: phase-decompose
description: "Break a transformation into pipeline stages using the one-verb heuristic. Identifies transformation boundaries and information rate limits. Use after /loop:phase-define has produced a transformation definition."
argument-hint: "[transformation-file]"
---

# Loop: Decompose into Stages

Break a transformation definition into ordered pipeline stages, each performing a single bounded transformation. Each stage should do one thing well — like a Unix pipe, it takes a defined input, transforms it, and produces a defined output.

## Input

Read `loop-workspace/transformation.md` (or the file provided as `$ARGUMENTS`). If it doesn't exist, tell the user to run `/loop:phase-define` first.

## What You Produce

A file named `loop-workspace/stages.md` containing an ordered list of stages, each with:

1. **Name** — verb-noun format (e.g., "Extract Entities", "Evaluate Coverage")
2. **Category** — one of the stage types below
3. **Transformation intent** — what this stage does, as a single verb phrase
4. **Input** — what this stage consumes (from upstream stage or pipeline input)
5. **Output** — what this stage produces (for downstream stage or pipeline output)
6. **Source dependencies** — external resources this stage reads from, if any (see below)
7. **Sink dependencies** — external targets this stage writes to, if any (see below)
8. **Complexity notes** — anything from the transformation definition that suggests this stage may need special handling

**Stage categories:**

| Category | Intent | Example |
|----------|--------|---------|
| **Extract** | Pull structure from unstructured input | Raw text → structured entities |
| **Enrich** | Add information to an existing artifact | Entities → entities with context |
| **Transform** | Convert between representations | Domain model → implementation plan |
| **Evaluate** | Assess quality against criteria | Draft → scored draft with issues |
| **Synthesise** | Combine multiple artifacts into one | Multiple analyses → unified report |
| **Refine** | Improve an artifact based on feedback | Draft + critique → improved draft |
| **Emit** | Push an artifact to an external target | Report → published report (via API, git, Slack) |

**Source dependencies** are external resources a stage reads from to bring new information into the pipeline (web, API, MCP server, database, filesystem). Sources are distinct from input artifacts: an input artifact flows through the pipeline from an upstream stage; a source enters from outside.

**Sink dependencies** are external targets a stage writes to, pushing data out of the pipeline (APIs, MCP servers, git, notification channels, databases, filesystem). Sinks are distinct from output artifacts: an output artifact flows to a downstream stage; a sink receives data from the pipeline into an external system. Key sink concerns: writes are not freely retryable (risk of duplication), gate failures after a write can't undo it (idempotency matters), and sink stages need mocks for testing.

**Notifications** are a special sink subtype for signaling pipeline state (Slack messages, emails, webhooks). Notification failures are **fire-and-forget by default** — they should be logged but should not block the pipeline. If delivery confirmation is required (e.g., a human must acknowledge), that's a human gate with a notification mechanism, not a notification sink.

**Stage classification by external dependencies:**

| Sources | Sinks | Classification | Characteristics |
|---------|-------|----------------|-----------------|
| None | None | **Pure transformation** | Freely retryable, testable with fixtures alone |
| Yes | None | **Enriched transformation** | Needs source mocks for testing, retry-safe |
| None | Yes | **Emitting transformation** | Needs sink mocks, retry requires idempotency |
| Yes | Yes | **Enriched emitting transformation** | Both source and sink mocks needed, most complex failure modes |

## How to Run

### Step 1: Read the transformation definition

Load `loop-workspace/transformation.md`. Identify the gap analysis and complexity signals — these drive decomposition.

### Step 2: Propose initial decomposition

Using the gap analysis, propose stages. Apply these heuristics:

**The one-verb heuristic**: If you need more than one verb to describe what a stage does, it's doing too much. "Extract and evaluate" is two stages. "Extract" is one.

**Natural boundaries**: Look for points where:
- The representation changes (unstructured → structured, raw → scored)
- The task type changes (extraction → evaluation → synthesis)
- A fresh context window would help (the upstream output is sufficient input; history isn't needed)

**Context isolation principle**: Each stage will execute in a fresh context window containing only the stage instructions, its input artifact, and stage-specific scaffolding. Stages do not see prior stages' reasoning, working memory, or context — only the output artifact from the preceding stage. This means each stage boundary is also an isolation boundary: the output artifact must carry everything the next stage needs, because nothing else will be available.

**Information rate check**: For each proposed stage, ask: could a single, well-prompted LLM call handle this? If the answer is "only with a very long, complex prompt," the task's information rate may exceed single-channel capacity — the stage needs further decomposition.

**Ordering principles** — when data dependencies don't fully determine the sequence:
- **Narrow before wide**: stages that filter, select, or reduce should precede stages that elaborate or enrich — process less data first, reduce noise for downstream stages.
- **Fail-fast**: stages most likely to reject input or trigger a gate failure should run early — discovering a problem after 5 stages wastes all prior work.
- **Cheap before expensive**: when otherwise unconstrained, run cheaper stages first — if a cheap stage's gate fails, you avoid paying for the expensive one.
- **Emit last**: stages that write to external sinks (APIs, git, Slack) should come after all validation — you can't undo a write. Gate the artifact thoroughly before emitting.

### Step 3: Challenge the decomposition with the user

Present the proposed stages and walk through these checks:

- **Too few stages?** — Is any stage doing multiple transformations? Apply the one-verb heuristic.
- **Too many stages?** — Are adjacent stages so tightly coupled that splitting them loses critical context? If stage B can't work without the full internal state of stage A (not just its output artifact), they may belong together.
- **Missing stages?** — Does the gap analysis mention difficulties not covered by any stage?
- **Kitchen Sink check** — Flag any stage whose description contains multiple verbs. A stage that tries to extract, evaluate, transform, and format in a single inference pushes the information rate far above single-channel capacity.

### Step 4: Validate the one-verb heuristic

Before writing, check every stage's intent. Each intent must be expressible as a single verb phrase — no conjunctions ("and", "then", "plus"), no semicolons joining actions. If an intent needs two verbs, split the stage. For example, "Assess ticket urgency and assign topic category" is two stages: "Classify urgency" and "Categorize topic."

This is the most common decomposition failure. Run this check mechanically on every intent before proceeding.

### Step 5: Write the artifact

Write `loop-workspace/stages.md`:

```markdown
# Stage Decomposition

## Pipeline Overview
<!-- One-line summary of the transformation -->
<!-- Total stage count -->

## Stages

### Stage 1: [Verb-Noun Name]
- **Category**: [Extract | Enrich | Transform | Evaluate | Synthesise | Refine | Emit]
- **Intent**: [Single verb phrase]
- **Input**: [What this stage consumes]
- **Output**: [What this stage produces]
- **Sources**: [None | List of external read dependencies with type]
- **Sinks**: [None | List of external write targets with type and idempotency notes]
- **Complexity**: [Notes from transformation definition, or "None identified"]

### Stage 2: [Verb-Noun Name]
...
```

### Step 6: Summarise

Present the stage list. The user or a workflow skill (`/loop:design`) determines what to run next.

## Guidance

- **Don't design artifacts yet.** Note inputs/outputs at a high level, but detailed artifact specs are `/loop:phase-artifacts`'s job.
- **Don't place gates yet.** If you notice a natural validation point, note it in complexity, but gate placement is `/loop:phase-gates`'s job.
- **Don't design loops yet.** If the user describes iterative refinement, note it as a complexity signal, but loop design is `/loop:phase-feedback`'s job.
- **Parallel sub-tasks are still stages.** If the transformation definition flags parallelisation opportunities, model them as stages that happen to share the same input. The design just shows they're independent.
