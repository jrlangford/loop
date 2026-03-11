---
name: loop-implement
description: "Translate Loop design artifacts into Claude Code skills — shared resources under a prefix directory, one orchestrator skill per workflow. Use after /loop-review passes or /loop-wf-design completes."
argument-hint: "[skill-prefix]"
---

# Loop: Implement as Claude Code Skills

Translate a Loop pipeline design into a set of Claude Code skills. Stage instructions and artifact contracts live in a shared resource directory under the skill prefix. Each workflow becomes an orchestrator skill that sequences stages, enforces gates, and manages feedback loops.

## Input

Read all files in `loop-workspace/`:

**Required** (stage-level):
- `stages.md` — stage decomposition
- `artifacts.md` — artifact specifications

**Recommended** (stage-level):
- `transformation.md` — overall transformation definition (used for naming and descriptions)
- `context-specs.md` — per-stage context budgets (used for skill guidance sections)

**Required for orchestrator generation** (workflow-level):
- `workflows/<name>/gates.md` — gate specifications
- `workflows/<name>/loops.md` — feedback loop specifications

If `stages.md` or `artifacts.md` don't exist, tell the user to run `/loop-decompose` and `/loop-artifacts` first (or the full `/loop-wf-design` workflow).

If workflow artifacts are missing, generate the shared resource directory only and tell the user to run `/loop-gates` and `/loop-feedback` to enable orchestrator generation.

## What You Produce

A shared resource directory and one orchestrator skill per workflow:

```
<prefix>/                           — shared resources (not a skill — no SKILL.md)
  stages/
    <stage-name>.md                 — one per stage (transformation instructions)
  contracts/
    <artifact-name>.md              — one per artifact (schema, validation, identity fields)
<prefix>-run/SKILL.md               — orchestrator (single workflow)
<prefix>-run-<workflow>/SKILL.md    — orchestrator (multiple workflows)
```

The `<prefix>/` directory is a shared resource directory, not a skill. It has no `SKILL.md`. It contains the stage instructions and artifact contracts that orchestrator skills reference at runtime. This eliminates duplication — each contract is defined once, referenced by every stage that produces or consumes it.

Skills are written to a directory the user specifies (default: `skills/` in the current project).

## Prerequisites

This skill requires `/skill-creator` to be installed. Before proceeding, check whether `/skill-creator` is available (it should appear in the list of installed skills). If it is not installed, stop and tell the user:

> `/loop-implement` requires the `skill-creator` skill to generate well-structured Claude Code skills. Install it from the official Claude plugins marketplace (`plugin-dev` plugin), then re-run `/loop-implement`.

Do not attempt to generate skills without `/skill-creator` — the skill-creator provides the authoritative conventions for skill structure, progressive disclosure, writing style, and validation that this skill depends on.

## How to Run

### Step 1: Determine the skill prefix

Use `$ARGUMENTS` if provided. Otherwise, derive from `transformation.md` (the pipeline's subject) or ask the user. The prefix should be short, lowercase, hyphenated (e.g., `debt`, `review`, `onboard`).

The prefix determines:
- Shared resource directory: `<prefix>/`
- Orchestrator skill directories: `<prefix>-run/` or `<prefix>-run-<workflow>/`
- Workspace directory name: `<prefix>-workspace/`

### Step 2: Determine output location

Ask the user where to write skills. Default: `skills/` in the current project directory. If the directory exists, check for conflicts and ask before overwriting.

### Step 3: Read and cross-reference design artifacts

Load all `loop-workspace/` artifacts. Build a cross-reference:

For each stage, collect:
- **From `stages.md`**: name, category, intent, input, output, sources, sinks, complexity
- **From `artifacts.md`**: the artifact spec for this stage's output (structure, omitted fields, validation rules, reasoning trace policy)
- **From `context-specs.md`** (if present): what goes in context, what's excluded, load assessment, history policy

For each workflow, collect:
- **From `gates.md`**: gate positions, types, criteria, failure routes, max retries
- **From `loops.md`**: loop types, termination conditions, degradation detectors, iteration caps

### Step 4: Generate contract files

For each artifact in `artifacts.md`, create a file in `<prefix>/contracts/`:

**File name**: Kebab-cased artifact name (e.g., "Classification Result" → `classification-result.md`, "KB Match Set" → `kb-match-set.md`).

**Contents**: The complete artifact specification — structure, fields, validation rules, identity fields, omitted fields, and reasoning trace policy. This is the single source of truth for the artifact's schema. Include:

- Full field list with types and constraints
- Validation rules (required fields, enum values, ranges)
- Identity fields (must pass through unchanged)
- Omitted fields (explicitly excluded from this artifact)
- Reasoning trace policy (none, summary, or full — and why)

Also create `<prefix>/contracts/_pipeline.md` containing:
- Pipeline-wide constants (enums, taxonomies, shared vocabularies)
- Workspace path conventions (`<prefix>-workspace/` layout)
- Artifact file naming rules

### Step 5: Generate stage files

For each stage in `stages.md`, create a file in `<prefix>/stages/`:

**File name**: Kebab-cased stage name (e.g., "Classify Ticket" → `classify-ticket.md`, "Retrieve Knowledge" → `retrieve-knowledge.md`).

**Contents**: The stage's transformation instructions. Each stage file is a self-contained instruction document that an orchestrator loads when it's time to execute that stage. Include:

1. **Intent**: The stage's purpose (one verb phrase from `stages.md`)
2. **Category and posture**: The stage category and its analytical posture (see posture table below)
3. **Input**: Which contract(s) to read from `<prefix>-workspace/`, with path(s). Reference contract files by name: "Read `<prefix>/contracts/<name>.md` for the input schema."
4. **Output**: Which contract to produce, with workspace path. Reference contract file: "Read `<prefix>/contracts/<name>.md` for the output schema."
5. **Steps**: Stage-specific transformation steps derived from intent, category, and complexity notes
6. **Sources**: External resources this stage reads from (if any — web, APIs, filesystem). Stages without sources work entirely from input artifacts.
7. **Sinks**: External targets this stage writes to (if any — APIs, git, notification channels, databases). For each sink, include: target description, format/API requirements, idempotency strategy (how to prevent duplicate writes on retry).
8. **Guidance**: Do/don't rules derived from stage category, context specs, and complexity notes

#### Stage Category → Posture

| Category | Posture |
|----------|---------|
| **Extract** | Index, don't analyse. Resist adding interpretation — that's downstream. |
| **Enrich** | Add information, don't transform structure. New fields supplement, not replace. |
| **Transform** | Convert representations. Input and output are structurally different. |
| **Evaluate** | Assess against criteria. Separate observation from judgment. Evidence required. |
| **Synthesise** | Combine inputs into a new whole. Reference sources, don't paraphrase. |
| **Refine** | Improve based on specific feedback. Change only what the feedback addresses. |
| **Emit** | Push to external target. Validate completeness before writing. Ensure idempotency markers are present. |

#### Context Spec → Stage Guidance

If `context-specs.md` exists, distill its guidance into each stage file:
- `Germane` load items → what to focus on
- `Extraneous` items → "Do not" guidance
- `Intrinsic` assessment → chunking strategy if needed (e.g., "work module-by-module")
- History policy (almost always "none") → don't reference upstream stage internals, only their output artifacts

#### Complexity Notes → Stage Guidance

Complexity signals from `stages.md` become specific warnings or strategies:
- "Arbitrary repo size" → "For large repos, work directory-by-directory."
- "Error reinforcement risk" → "Verify against source material, don't amplify previous assessments."

### Step 6: Generate orchestrator skills

For each workflow in `loop-workspace/workflows/`, use `/skill-creator` to generate an orchestrator skill. Provide the following content requirements — `/skill-creator` decides the structure and style, but the generated orchestrator must include all of these elements:

1. **Skill name**: `<prefix>-run` (single workflow) or `<prefix>-run-<workflow>` (multiple)
2. **Purpose**: orchestrate the full pipeline — sequence stages, enforce gates, manage feedback loops
3. **Precondition checks**: If stages have source or sink dependencies, generate a precondition section that runs before the first stage. For each external dependency, check reachability/configuration (API tokens valid, MCP servers connected, git branches writable, notification channels configured). Classify each as required (abort if missing) or optional (warn and continue in degraded mode). If the pipeline has no external dependencies, omit this section.
4. **Pipeline overview**: a visual diagram showing stage flow, gates, and loops (derived from `stages.md` + `gates.md` + `loops.md`)
5. **Phase-by-phase instructions**: for each stage:
   - **Delegate the stage to a subagent** via the Agent tool. The subagent's prompt must include: (a) the stage file contents ("Read `<prefix>/stages/<stage-name>.md`"), (b) the relevant contract files for input and output schemas, (c) the input artifact path in `<prefix>-workspace/`, (d) the output artifact path to write. The orchestrator does **not** execute stage transformations in its own context — this would accumulate every stage's working memory, violating context isolation.
   - After the subagent completes, the orchestrator reads the output artifact from `<prefix>-workspace/` (not the subagent's reasoning trace) to verify it exists and proceed.
   - Run gate checks after each stage. Schema and metric gates can run inline. **Semantic gates must run in a dedicated subagent** with clean context containing only the artifact, validation criteria, and (where relevant) the original source material. The orchestrator must not evaluate semantic quality inline — its context contains orchestration history that biases evaluation.
   - Handle loop feedback: on gate failure, re-run the stage subagent with the gate feedback appended to its prompt.
6. **Error handling**: stage failure, human escalation, pipeline abort. For Emit stages, include sink failure handling (retry policy, idempotency checks, partial write recovery).
7. **Resumption table**: maps output artifacts to phases — if an artifact already exists in `<prefix>-workspace/`, the corresponding phase can be skipped, enabling re-entry after failures. For Emit stages, note whether the external write was completed (to avoid duplicate writes on resume).
8. **Guidance**: orchestrator-specific rules (delegate each stage to a subagent for context isolation, run semantic gates in dedicated subagents, gates are checkpoints not bottlenecks, track degradation, preserve workspace, report progress)

#### Orchestrator Mapping Rules

**Gates → checklists**: Each gate becomes a checklist section after its stage's phase. Gate criteria map to checkbox items. Include the gate type so the orchestrator knows how to evaluate:

| Gate type | Orchestrator action |
|-----------|-------------------|
| **Schema** | Check structural presence of required fields/sections |
| **Metric** | Check quantitative thresholds (counts, percentages) |
| **Identity** | Verify specific fields haven't changed from upstream |
| **Semantic** | Run a separate LLM evaluation in clean context |
| **Consensus** | Run multiple independent evaluations, compare results |
| **Human** | Pause and present the artifact to the user for review and decision |

**Loops → feedback sections**: Each loop becomes a feedback subsection after its gate. Include:
- Trigger condition (what gate failure or signal starts the loop)
- What gets fed back to which stage (re-read that stage's file from `<prefix>/stages/`)
- Termination conditions (semantic + hard cap)
- Degradation detection (what to monitor between iterations)

**Parallel stages**: If `stages.md` shows independent stages sharing the same input (no dependency between them), the orchestrator should note they can run in parallel.

**Subagent precondition propagation**: When parallel stages or decompose-aggregate patterns delegate work to subagents (via the Agent tool), the orchestrator must propagate each subagent's relevant preconditions into its prompt. Preconditions validated in the main agent do not carry over — subagents may run in isolated contexts without the same tool access, network permissions, or MCP server connections. For each subagent, the orchestrator should: (1) explicitly instruct the subagent to use the required tools/resources (e.g., "use web search to verify claims"), and (2) include a lightweight re-validation step in the subagent prompt (e.g., "perform a test web search before beginning work — if it fails, report the failure and stop"). This prevents silent failures where subagents silently skip external lookups they cannot perform.

**Resumption table**: Build from the artifact list — one row per stage, mapping its output artifact to a "skip this phase" decision.

### Step 7: Validate generated output

After generating all files, perform both `/skill-creator`'s validation checklist (for orchestrator skills) and the Loop-specific checks below:

**Pipeline completeness**:
- [ ] Every stage in `stages.md` has a corresponding file in `<prefix>/stages/`
- [ ] Every artifact in `artifacts.md` has a corresponding file in `<prefix>/contracts/`
- [ ] Every workflow has an orchestrator skill
- [ ] Every artifact is produced by exactly one stage
- [ ] Every artifact is consumed by at least one stage (no dead outputs)
- [ ] Every gate in `gates.md` appears in an orchestrator
- [ ] Every loop in `loops.md` appears in an orchestrator

**Reference integrity**:
- [ ] Every stage file references contract files that exist in `<prefix>/contracts/`
- [ ] Every orchestrator references stage files that exist in `<prefix>/stages/`
- [ ] Workspace file paths are consistent across all stage files and orchestrators
- [ ] Orchestrator gate criteria match contract validation rules

**Sink safety:**
- [ ] Every Emit stage file includes idempotency strategy and sink format requirements
- [ ] Every gate before an Emit stage validates the artifact is complete and write-ready
- [ ] No loops route back through Emit stages with iteration caps >3
- [ ] Notification sinks are configured as fire-and-forget (non-blocking on failure)
- [ ] Orchestrator precondition checks cover all declared sources and sinks
- [ ] Stages delegated to subagents propagate relevant preconditions (tool access, network, MCP servers) into the subagent prompt, including a re-validation step

**Context isolation**:
- [ ] Every stage is delegated to a subagent — the orchestrator does not execute stage transformations in its own context
- [ ] Semantic gates run in dedicated subagents, not inline in the orchestrator or in the producing stage's subagent
- [ ] The orchestrator's own context contains only orchestration state (stage completion, gate results, loop counters), not stage working memory
- [ ] Each subagent prompt includes only the stage file, relevant contracts, and input artifact path — no prior stages' context

**Self-containment** (at the pipeline level):
- [ ] No file references `loop-workspace/` design artifacts or framework docs
- [ ] Each stage file's guidance is actionable without external context
- [ ] The `<prefix>/` directory + orchestrator skill(s) form a complete, portable unit

### Step 8: Present results

Summarise what was generated:
- File count (contracts + stages + orchestrator skills)
- Shared resource directory name
- Any design elements that couldn't be cleanly mapped (with explanation)
- Installation instructions: symlink `<prefix>/` and each `<prefix>-run*/` directory to `~/.claude/skills/`

## Guidance

### Delegation to `/skill-creator`

`/skill-creator` owns skill structure, writing style (imperative form, third-person descriptions), progressive disclosure, and validation. This skill owns the pipeline-specific content.

`/skill-creator` is used only for **orchestrator skills** (which have `SKILL.md` frontmatter and are invocable via slash commands). Stage files and contract files are plain reference documents, not skills — they don't need `/skill-creator`.

### The Shared Resource Directory

The `<prefix>/` directory is the key architectural element. It contains all stage instructions and artifact contracts, shared across workflows.

**Why not one skill per stage?** Stage skills installed independently would each need to inline their input and output artifact schemas — duplicating contracts across every producer and consumer. The shared resource directory eliminates this duplication. Contracts are defined once in `<prefix>/contracts/`, referenced by any stage that needs them.

**Why not put contracts in the workspace?** The workspace (`<prefix>-workspace/`) is for runtime artifacts — the actual data produced by pipeline execution. The shared resource directory is for design-time definitions — schemas, instructions, and validation rules that don't change between runs. Keeping them separate prevents confusion between "what the pipeline produces" and "how the pipeline is defined."

**Installation**: The `<prefix>/` directory must be symlinked to `~/.claude/skills/` alongside the orchestrator skills, so orchestrators can reference stage and contract files via relative paths like `<prefix>/stages/<name>.md`.

### Stages Are Reference Documents, Not Skills

Stage files in `<prefix>/stages/` are instruction documents that orchestrators read at the appropriate time. They are not independently invocable skills (no SKILL.md, no frontmatter, no slash command). This is intentional:

- **Context isolation**: Each stage runs in a subagent with fresh context — the subagent sees only the stage file, its contracts, and the input artifact. The orchestrator never loads stage files into its own context, which would accumulate working memory across stages and defeat the purpose of staging.
- **Sequencing control**: The orchestrator controls when each stage runs, what gate checks follow, and what feedback loops apply. Stages don't need to know about this.
- **Simplicity**: Users run one command (`/<prefix>-run`) instead of invoking N stage skills in sequence.

If a user needs to rerun a single stage, the orchestrator's resumption table handles this — existing artifacts are skipped, and execution resumes at the specified phase.

### Orchestrator Skills Are the Entry Points

Each orchestrator skill is the only user-facing skill for its workflow. It:
1. Delegates each stage to a subagent (via the Agent tool), providing the stage file, relevant contracts, and input artifact path
2. Reads output artifacts from `<prefix>-workspace/` after each subagent completes
3. Runs gate checks between stages (schema/metric inline; semantic gates in dedicated subagents)
4. Manages feedback loops (re-running stage subagents with gate feedback when loops trigger)
5. Tracks orchestration state: stage completion, gate results, loop counters, degradation signals

### Naming Conventions

- **Skill prefix**: Short, lowercase, hyphenated. Describes the pipeline's domain (e.g., `debt`, `review`, `onboard`).
- **Stage file names**: Kebab-cased verb or verb-noun from stage name (e.g., `classify-ticket.md`, `retrieve-knowledge.md`).
- **Contract file names**: Kebab-cased artifact name (e.g., `classification-result.md`, `kb-match-set.md`).
- **Orchestrator names**: `<prefix>-run` for single-workflow pipelines. `<prefix>-run-<workflow>` for multi-workflow.
- **Workspace directory**: `<prefix>-workspace/`. All stages read from and write to this directory.

### Observability

LLM stages are stochastic — a pipeline has a *success rate*, not a pass/fail result. Orchestrator skills should track and report:

- **Gate pass/fail rates** — a gate that never fails may be a Phantom Feedback Loop; a gate that fails frequently signals an unreliable upstream stage
- **Loop iteration counts** — how many iterations each loop actually uses. If loops consistently hit their hard cap, the termination condition may be too tight or the task needs restructuring
- **Artifact snapshots** — what each stage produced, enabling post-hoc diagnosis of pipeline failures
- **Gate decisions** — what criteria passed/failed and what feedback was routed, so failure patterns can be analyzed
- **Sink writes** — for Emit stages: what was written, to which target, whether it succeeded, idempotency ID used (if any). Log these alongside gate decisions so external write failures can be correlated with pipeline execution

Include a "Pipeline Run Summary" section at the end of each orchestrator run that reports these metrics.

### What Not to Generate

- **Don't generate runtime code.** Skills are prompt documents, not programs. They instruct Claude Code what to do — they don't execute logic themselves.
- **Don't generate tests.** Skills are validated by `/loop-audit`, not by test suites.
- **Don't generate documentation beyond the skills.** The orchestrator skill describes the pipeline. A README is unnecessary.
- **Don't add framework concepts.** Only include framework concepts that are directly needed for the stage or orchestrator to function.

### Handling Design Gaps

If the design artifacts are incomplete or ambiguous:

- **Missing context specs**: Generate stage files without detailed context guidance. Note which stages would benefit from running `/loop-context`.
- **Missing gates/loops**: Generate the shared resource directory only. Tell the user the orchestrator needs `/loop-gates` and `/loop-feedback`.
- **Ambiguous artifact formats**: Ask the user to clarify. Don't guess at field structures — a wrong contract creates mismatches across the entire pipeline.
- **Stages that don't map cleanly**: Some stages may be infrastructure (setup, cleanup) rather than transformations. Generate them as stage files but note in guidance that they're mechanical, not analytical.
