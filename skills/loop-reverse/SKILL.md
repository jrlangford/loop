---
name: loop-reverse
description: "Reverse-engineer an existing implementation into Loop design artifacts. Reads implementation files (skills, agents, scripts) and produces loop-workspace artifacts (stages.md, artifacts.md, etc.) as if the design skills had been run. Use on any multi-stage pipeline to get it into Loop vocabulary."
argument-hint: "[path-or-description]"
---

# Loop: Reverse-Engineer Implementation

Read an existing multi-stage pipeline implementation and produce Loop design artifacts — the same files that `/loop-define` through `/loop-context` would produce, but derived from code rather than interactive design.

## Loop Vocabulary

The following definitions guide what to look for when reverse-engineering an implementation.

**Stages** are isolated transformation units. Each stage transforms an input artifact into an output artifact. A well-designed stage does one thing (the one-verb heuristic). Stage categories:

| Category | Intent | Example |
|----------|--------|---------|
| **Extract** | Pull structure from unstructured input | Raw text → structured entities |
| **Enrich** | Add information to an existing artifact | Entities → entities with context |
| **Transform** | Convert between representations | Domain model → implementation plan |
| **Evaluate** | Assess quality against criteria | Draft → scored draft with issues |
| **Synthesise** | Combine multiple artifacts into one | Multiple analyses → unified report |
| **Refine** | Improve an artifact based on feedback | Draft + critique → improved draft |

**Artifacts** are typed, structured intermediate representations passed between stages. They should be self-describing, validatable, serialisable, and minimal. Key design properties:
- *Enumerate, don't describe* — prefer closed vocabularies (enums, scores) over free text to reduce interpretation drift
- *Reference, don't paraphrase* — carry source locations rather than the producing stage's interpretation
- *Separate observation from judgment* — distinct fields for evidence vs. assessment
- *Identity fields* — a stable subset of fields that should pass through stages unchanged (source refs, IDs, verbatim quotes)

**Gates** (workflow-level) are validation checkpoints between stages. Types: Schema (structural, deterministic), Metric (quantitative threshold, deterministic), Identity (verify immutable fields haven't mutated, deterministic), Semantic (LLM-based quality assessment, probabilistic), Consensus (multi-evaluator agreement, expensive). Each gate specifies: pass criteria, failure route, feedback carried, max retries, escalation.

**Loops** (workflow-level) are explicit feedback connections between stages:
- *Reinforcing (R)* — amplify, deepen, elaborate. Risk: echo chamber (unbounded elaboration without novelty). Requires novelty gate + iteration cap.
- *Balancing (B)* — correct, constrain, converge. Risk: phantom feedback (loop that never triggers correction). Requires convergence criteria + degradation detector.
- Every loop must have: declared type (R or B), semantic termination condition, hard iteration cap, degradation detector.

**Sources** (stage-level) are external resources a stage accesses to bring new information into the pipeline: web, API, MCP server, database, filesystem. Sources are distinct from input artifacts — an input artifact flows through the pipeline from an upstream stage; a source enters from outside. Stages without sources are pure transformations; stages with sources are enriched transformations. The distinction affects testing, failure handling, and cost.

**Workflows** compose stages into specific pipelines — which stages, in what order, with which gates and loops. Same stages can participate in multiple workflows with different wiring. Workflows are lightweight orchestration, not transformation logic.

## Input

`$ARGUMENTS` should identify the implementation. Accepts:
- A directory path (e.g., `skills/` or `src/pipeline/`)
- A description of what to reverse-engineer (e.g., "the DDD skills in this project")
- Nothing — ask the user what to analyze

## What You Produce

Design artifacts in `loop-workspace/`, identical in format to what the design skills produce:

**Stage-level** (root of `loop-workspace/`):
- `transformation.md` — overall transformation definition
- `stages.md` — stage decomposition (with source dependencies)
- `artifacts.md` — artifact specifications
- `context-specs.md` — per-stage context budgets

**Workflow-level** (under `loop-workspace/workflows/<name>/`):
- `gates.md` — gate specifications
- `loops.md` — feedback loop specifications

These artifacts can then be used with any `/loop-*` skill — reviewed with `/loop-review`, audited with `/loop-audit`, or refined with individual design skills.

## How to Run

### Step 1: Check for existing workspace

If `loop-workspace/` already contains design artifacts, ask the user how to proceed:
- **Overwrite** — replace existing artifacts with implementation-derived ones
- **Cancel** — stop and let the user manage the workspace first

Do not silently overwrite. Existing artifacts may represent intentional design that differs from the implementation.

### Step 2: Discover the pipeline

Read implementation files to understand the pipeline structure. Look for:
- **Stage boundaries** — where one unit of work ends and another begins
- **Artifacts** — what data passes between stages (files, messages, structured objects)
- **Control flow** — what triggers each stage, what order they run
- **Validation** — any checks, gates, or quality assurance between stages
- **Feedback paths** — retries, revision loops, re-runs
- **Context management** — what each stage reads, what it ignores

Adapt discovery to the implementation type:
- **Claude Code skills (shared resource structure)**: Look for a `<prefix>/` directory containing `stages/` (stage reference documents) and `contracts/` (artifact schemas). Orchestrator skills (`<prefix>-run/SKILL.md`) sequence stages and manage gates/loops. Stage boundaries are the files in `stages/`. Artifacts are defined by the files in `contracts/`. This is the structure `/loop-implement` produces.
- **Claude Code skills (one skill per stage)**: Each stage is an independent skill with its own `SKILL.md` and slash command. Stage boundaries are skill invocations. Artifacts are the files skills produce. Note: this structure duplicates artifact schemas across skills — flag this in the synthesis notes.
- **Scripts/code**: Read orchestration logic, function signatures, data flow.
- **Mixed**: Some implementations combine skill definitions with code. Read both.

Use subagents for parallel discovery when the implementation has many files.

### Step 3: Write artifacts

Create `loop-workspace/` and write artifacts in this order:

**`transformation.md`** — Derive from the implementation's overall purpose:
- Input: what the pipeline receives (first stage's input)
- Output: what the pipeline produces (last stage's output)
- Gap: what transformations bridge input to output
- Complexity signals: what the implementation reveals about difficulty

**`stages.md`** — One stage per meaningful unit of work:
- Map each implementation unit (skill, agent node, script phase) to a stage
- Apply the one-verb heuristic: flag stages whose implementation does multiple things
- Note the stage category (Extract, Enrich, Transform, Evaluate, Synthesise, Refine)
- Identify source dependencies: does this stage fetch from the web, call APIs, use MCP servers, query databases, or read external files? Mark stages with no external access as pure transformations.
- If an implementation unit contains sub-phases, note them but model the unit as one stage unless the sub-phases are independently invocable

**`artifacts.md`** — One artifact per stage boundary:
- Document what actually passes between stages (file formats, schemas, key fields)
- Note which fields are consumed downstream versus carried but unused
- Flag artifacts that are ephemeral (not persisted)
- Identify fields that use enums/closed vocabularies versus free text
- Note where artifacts carry source references versus paraphrased interpretations
- Flag fields that mix observation and judgment in a single value
- Identify candidate identity fields — fields that appear unchanged across multiple stages

**`context-specs.md`** — One spec per stage:
- Document what each stage actually loads into context (files read, history included)
- Note the history policy (explicit or implied)
- Flag stages that load more than they need

Then write workflow-level artifacts under `workflows/<name>/` (use "default" if the implementation has a single workflow, or derive names from distinct execution paths):

**`workflows/<name>/gates.md`** — One gate per validation checkpoint found:
- Include automated checks (schema validation, build verification, tests)
- Include human review points
- Note gate type (Schema, Metric, Semantic, Consensus)
- Flag missing elements: no failure route, no max retries, no escalation

**`workflows/<name>/loops.md`** — One loop per feedback path:
- Include explicit loops (retry logic, revision cycles)
- Include implicit loops (human edits until satisfied, re-run until passing)
- Classify each as Reinforcing or Balancing
- Flag missing safety: no hard cap, no degradation detector, no semantic termination

If the implementation has multiple distinct execution paths over the same stages (e.g., a quick mode and a thorough mode), model each as a separate workflow.

For each artifact, note where the mapping from implementation to Loop vocabulary is clean versus where you're inferring or interpreting. Add a `<!-- Synthesis note: ... -->` comment where interpretation was needed.

### Step 4: Summarise

Present what was reverse-engineered: stage count, artifact count, loops found, any flags raised during synthesis. The user or a workflow skill (`/loop-wf-analyze`) determines what to run next.

## Guidance

- **Describe what is, not what should be.** The goal is an accurate model of the implementation in Loop vocabulary. Don't fix problems — document them. Fixing is for the design skills.
- **Flag the synthesis gap.** When the implementation doesn't map cleanly to Loop concepts, say so. "This stage doesn't fit the one-verb heuristic, but it's checkpointed internally" is a useful observation, not a failure.
- **Don't force the fit.** Not every implementation unit maps 1:1 to a Loop stage. Some are infrastructure, some are utilities, some span multiple stages. Model what makes sense and note the rest.
- **Implementation units are not always stages.** A helper function called by three stages isn't a stage — it's shared infrastructure. A config file read by every stage isn't an artifact — it's scaffolding. Use judgment.
