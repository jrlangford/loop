---
description: "Budget channel capacity per pipeline stage — what goes in each stage's context window, what stays out, and why. Use after /loop:phase-artifacts or when a pipeline is underperforming due to context issues."
---

# Loop: Budget Context

Design the context specification for each stage — what the LLM sees when executing that stage. Each stage's context window is a finite-capacity channel: signal (task-relevant tokens) must fit within effective capacity, noise (irrelevant tokens) wastes bandwidth, and interference (contradictory tokens) is actively destructive.

## Input

Read all files in `loop-workspace/` — this skill needs the full pipeline spec. At minimum: `stages.md` and `artifacts.md`. If `gates.md` and `loops.md` exist, incorporate them. If files are missing, tell the user which upstream skills to run, but note that `/loop:phase-context` can also be used standalone on an existing pipeline.

## What You Produce

A file named `loop-workspace/context-specs.md` containing per-stage context budgets.

## How to Run

### Step 1: Walk through the context worksheet for each stage

For each stage, work through these questions:

**Signal (what the channel should carry):**
- What is the primary input artifact?
- What stage-specific instructions or examples does the LLM need?
- What domain knowledge is required for *this* stage specifically?

**Noise (what wastes channel bandwidth):**
- What artifact fields are *not* needed by this stage?
- How much upstream reasoning trace should be included? (default: none)
- What conversation or pipeline history is needed? (default: none)
- Does any included context contradict other context? (interference is far more destructive than noise)

**Information rate (is this too much for one channel?):**
- Is this stage's task too complex for a single inference?
- If yes, how should it decompose further? (This may trigger revisiting `/loop:phase-decompose`)

### Step 2: Apply the history default

The framework defaults to **no history** — each stage gets only its input artifact and stage-specific scaffolding. Challenge any deviation:

- "This stage needs the full conversation history" → Why? What specific information from history isn't in the input artifact? Can it be added to the artifact instead?
- "This stage needs to see upstream stage outputs" → Which specific fields? Can those be included in the artifact rather than carrying raw upstream output?

This is the **History Avalanche** anti-pattern: an agentic pipeline where each stage receives the full accumulated context of all previous stages. Channel noise grows monotonically; by the late stages, the model is drowning in irrelevant upstream details.

### Step 3: Design stage-specific scaffolding

For each stage, specify what germane scaffolding it needs beyond the input artifact:

- **System prompt guidance** — what role/persona/constraints the LLM needs for this stage
- **Examples** — few-shot examples if the transformation is non-obvious
- **Domain reference** — specific domain knowledge (glossaries, rules, schemas) relevant to this stage
- **Output format** — expected structure of the output artifact

### Step 4: Check for load conflicts

Review the full set of context specs for issues:

- **Any stage receiving more than its input artifact + scaffolding?** Justify it.
- **Late-pipeline stages receiving early-pipeline details?** This is usually a History Avalanche.
- **Stages with very large scaffolding?** If the instructions are longer than the input, the stage may be too complex — revisit decomposition.
- **Semantic gates sharing context with their producing stage?** Gates that use LLM evaluation should run in a separate, minimal context containing only the artifact and validation criteria. If the gate evaluator sees the producing stage's full context, the producer's trajectory biases the validation.
- **Emit stages with bloated context?** Stages that write to external sinks should have clean, minimal context focused on what the sink needs. If the stage is formatting data for an external API, it should see only the artifact being written and the sink's format requirements — not upstream history or unrelated scaffolding. Extra context wastes bandwidth and may cause formatting errors in the external write.
- **Long pipelines (5+ stages) with no re-grounding?** Consider whether a checkpoint stage should compare the current artifact against the original pipeline input to detect cumulative drift.

### Step 5: Write the artifact

Write `loop-workspace/context-specs.md`:

```markdown
# Context Specifications

## Stage: [Stage Name]

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | [Artifact name from artifacts.md] |
| System prompt | Yes | [Brief description of role/constraints] |
| Examples | [Yes/No] | [What examples, if any] |
| Domain reference | [Yes/No] | [What reference material, if any] |
| Upstream history | [No / Partial / Full] | [What and why, if not "No"] |
| Reasoning trace | [No / Summary] | [From artifact spec] |

### Channel Assessment
- **Signal**: [What task-relevant information this context carries]
- **Noise**: [What was deliberately excluded and why]
- **Information rate**: [Assessment — within single-inference channel capacity?]

## Stage: [Stage Name]
...
```

### Step 6: Summarise

Present a summary of context decisions. Highlight any stages with non-default history inclusion. The user or a workflow skill (`/loop:design`) determines what to run next.

## Guidance

- **Less is more.** The best context spec is the smallest one that lets the stage do its job. Every additional token consumes channel bandwidth — and if it's not signal, it's noise.
- **Position matters in large contexts.** In very long contexts (100k+ tokens), attention follows a U-shaped curve where mid-context information can be under-weighted relative to the beginning and end ("lost in the middle"). Modern models have significantly reduced this bias, and the effect is negligible in short-to-medium contexts. But when a stage operates near context capacity limits, place the highest-signal content (task instructions, critical constraints) at the start and end; avoid burying key information in the middle of large payloads.
- **Long generation narrows effective context.** During extended generation, attention sinks (disproportionate weight on initial tokens) combine with autoregressive trajectory commitment to progressively narrow the information the model actually draws from. This reinforces the information rate check: if a stage requires a long generation pass, it may need decomposition — not because the input is too large, but because the output generation itself degrades context utilization.
- **The artifact is the interface.** If a stage needs information from upstream, it should be in the artifact, not carried as raw history. If it's not in the artifact, ask why — maybe the artifact spec needs updating (revisit `/loop:phase-artifacts`).
- **Scaffolding is not a crutch.** If a stage needs extensive instructions to work, the stage may be poorly defined. Simple, well-scoped stages need minimal scaffolding.
