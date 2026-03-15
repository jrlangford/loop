---
description: "Translate Loop design artifacts into a Claude Code plugin — shared resources, orchestrator skills, and plugin manifest. Use after /loop:audit-design passes or /loop:design completes."
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

If `stages.md` or `artifacts.md` don't exist, tell the user to run `/loop:phase-decompose` and `/loop:phase-artifacts` first (or the full `/loop:design` workflow).

If workflow artifacts are missing, generate the shared resource directory only and tell the user to run `/loop:phase-gates` and `/loop:phase-feedback` to enable orchestrator generation.

## What You Produce

A Claude Code plugin containing a shared resource directory and one orchestrator skill per workflow:

```
<output-dir>/                       — plugin root (default: project root)
  .claude-plugin/
    plugin.json                     — plugin manifest (name, description, version, keywords)
  skills/
    <prefix>/                       — shared resources (not a skill — no SKILL.md)
      stages/
        <stage-name>.md             — one per stage (transformation instructions)
      contracts/
        <artifact-name>.md          — one per artifact (schema, validation, identity fields)
    run/SKILL.md                    — orchestrator (single workflow)
    run-<workflow>/SKILL.md         — orchestrator (multiple workflows)
```

The plugin manifest (`.claude-plugin/plugin.json`) packages everything as a distributable Claude Code plugin. The plugin `name` field is the `<prefix>`, so skills are invoked as `/<prefix>:run` (or `/<prefix>:run-<workflow>`). The shared resource directory lives under `skills/<prefix>/` alongside the orchestrator skills — no `SKILL.md`, so it's not invocable but is accessible to orchestrators via relative paths.

Output is written to the project root by default. The user can specify a subdirectory for multi-plugin repos (e.g., `./my-pipeline/`).

## Prerequisites

This skill requires `/skill-creator` to be installed. Before proceeding, check whether `/skill-creator` is available (it should appear in the list of installed skills). If it is not installed, stop and tell the user:

> `/loop:implement` requires the `skill-creator` skill to generate well-structured Claude Code skills. Install it from the official Claude plugins marketplace (`plugin-dev` plugin), then re-run `/loop:implement`.

Do not attempt to generate skills without `/skill-creator` — the skill-creator provides the authoritative conventions for skill structure, progressive disclosure, writing style, and validation that this skill depends on.

## How to Run

### Step 1: Determine the skill prefix

Use `$ARGUMENTS` if provided. Otherwise, derive from `transformation.md` (the pipeline's subject) or ask the user. The prefix should be short, lowercase, hyphenated (e.g., `debt`, `review`, `onboard`).

The prefix determines:
- Plugin name in `.claude-plugin/plugin.json`
- Shared resource directory: `skills/<prefix>/`
- Orchestrator skill directories: `skills/run/` or `skills/run-<workflow>/`
- Workspace directory name: `<prefix>-workspace/` (runtime, in the project using the plugin)

### Step 2: Determine output location

Ask the user where to write the plugin. Default: project root (`.`). For multi-plugin repos, the user can specify a subdirectory (e.g., `./my-pipeline/`). If `.claude-plugin/plugin.json` or `skills/` already exist at the output location, check for conflicts and ask before overwriting.

### Step 3: Read and cross-reference design artifacts

Load all `loop-workspace/` artifacts. Build a cross-reference:

For each stage, collect:
- **From `stages.md`**: name, category, intent, input, output, sources, sinks, complexity
- **From `artifacts.md`**: the artifact spec for this stage's output (structure, validation rules, identity fields, omitted fields, reasoning trace policy)
- **From `context-specs.md`** (if present): what goes in context, what's excluded, load assessment, history policy

For each workflow, collect:
- **From `gates.md`**: gate positions, types, criteria, failure routes, max retries
- **From `loops.md`**: loop types, termination conditions, degradation detectors, iteration caps

### Step 4: Generate plugin manifest

Create `.claude-plugin/plugin.json` at the output root:

```json
{
  "name": "<prefix>",
  "description": "<derived from transformation.md — the pipeline's purpose in one sentence>",
  "version": "1.0.0",
  "keywords": ["loop-pipeline"]
}
```

- **`name`**: the skill prefix (kebab-case). This becomes the plugin namespace — skills are invoked as `/<prefix>:run`.
- **`description`**: derived from `transformation.md` if available. Describe what the pipeline does, not how.
- **`keywords`**: always include `"loop-pipeline"` to identify Loop-generated plugins. Add domain-specific keywords as appropriate.

### Step 5: Generate contract files

For each artifact in `artifacts.md`, create a file in `skills/<prefix>/contracts/`:

**File name**: Kebab-cased artifact name (e.g., "Classification Result" → `classification-result.md`).

**Contents**: The complete artifact specification — structure, fields, validation rules, identity fields, omitted fields, and reasoning trace policy. This is the single source of truth for the artifact's schema. Include:

- Full field list with types and constraints
- Validation rules (required fields, enum values, ranges)
- Identity fields (must pass through unchanged)
- Omitted fields (explicitly excluded from this artifact)
- Reasoning trace policy (none, summary, or full — and why)

Also create `skills/<prefix>/contracts/_pipeline.md` containing:
- Pipeline-wide constants (enums, taxonomies, shared vocabularies)
- Workspace path conventions (`<prefix>-workspace/` layout)
- Artifact file naming rules

### Step 6: Generate stage files

For each stage in `stages.md`, create a file in `skills/<prefix>/stages/`:

**File name**: Kebab-cased stage name (e.g., "Classify Ticket" → `classify-ticket.md`).

**Contents**: A self-contained instruction document that an orchestrator loads when executing the stage. Include:

1. **Intent**: The stage's purpose (one verb phrase from `stages.md`)
2. **Category and posture**: The stage category and its analytical posture (see posture table below)
3. **Input**: Which contract(s) to read from `<prefix>-workspace/`, with path(s). Reference contract files by name: "Read `<prefix>/contracts/<name>.md` for the input schema."
4. **Output**: Which contract to produce, with workspace path. Reference contract file: "Read `<prefix>/contracts/<name>.md` for the output schema."
5. **Steps**: Stage-specific transformation steps derived from intent, category, and complexity notes
6. **Sources**: External resources this stage reads from (if any). Stages without sources work entirely from input artifacts.
7. **Sinks**: External targets this stage writes to (if any). For each sink: target description, format/API requirements, idempotency strategy.
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
- `Intrinsic` assessment → chunking strategy if needed
- History policy (almost always "none") → don't reference upstream stage internals, only their output artifacts

#### Complexity Notes → Stage Guidance

Complexity signals from `stages.md` become specific warnings or strategies:
- "Arbitrary repo size" → "For large repos, work directory-by-directory."
- "Error reinforcement risk" → "Verify against source material, don't amplify previous assessments."

### Step 7: Generate orchestrator skills

For each workflow in `loop-workspace/workflows/`, use `/skill-creator` to generate an orchestrator skill. Provide the following content requirements — `/skill-creator` decides the structure and style, but the generated orchestrator must include all of these elements:

1. **Skill name**: `run` (single workflow) or `run-<workflow>` (multiple) — the plugin namespace provides the `<prefix>:` prefix automatically
2. **Purpose**: orchestrate the full pipeline — sequence stages, enforce gates, manage feedback loops
3. **Precondition checks**: If stages have source or sink dependencies, generate a precondition section that runs before the first stage. For each external dependency, check reachability/configuration. Classify each as required (abort if missing) or optional (warn and continue in degraded mode). If the pipeline has no external dependencies, omit this section.
4. **Pipeline overview**: a visual diagram showing stage flow, gates, and loops
5. **Phase-by-phase instructions**: for each stage:
   - **Delegate the stage to a subagent** via the Agent tool. The subagent's prompt must include: (a) the stage file contents, (b) the relevant contract files for input and output schemas, (c) the input artifact path in `<prefix>-workspace/`, (d) the output artifact path to write. The orchestrator does **not** execute stage transformations in its own context.
   - After the subagent completes, the orchestrator reads the output artifact from `<prefix>-workspace/` to verify it exists and proceed.
   - Run gate checks after each stage. Schema and metric gates run inline. **Semantic gates must run in a dedicated subagent** with clean context containing only the artifact, validation criteria, and (where relevant) the original source material.
   - Handle loop feedback: on gate failure, re-run the stage subagent with the gate feedback appended to its prompt.
6. **Error handling**: stage failure, human escalation, pipeline abort. For Emit stages, include sink failure handling.
7. **Resumption table**: maps output artifacts to phases — if an artifact already exists in `<prefix>-workspace/`, the corresponding phase can be skipped.
8. **Guidance**: orchestrator-specific rules (delegate each stage to a subagent for context isolation, run semantic gates in dedicated subagents, gates are checkpoints not bottlenecks, track degradation, preserve workspace, report progress)

#### Orchestrator Mapping Rules

**Gates → checklists**: Each gate becomes a checklist section after its stage's phase. Include the gate type so the orchestrator knows how to evaluate:

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
- What gets fed back to which stage
- Termination conditions (semantic + hard cap)
- Degradation detection

**Parallel stages**: If `stages.md` shows independent stages sharing the same input (no dependency between them), the orchestrator should note they can run in parallel.

**Subagent precondition propagation**: When parallel stages or decompose-aggregate patterns delegate work to subagents, the orchestrator must propagate each subagent's relevant preconditions into its prompt. Preconditions validated in the main agent do not carry over. For each subagent: (1) explicitly instruct the subagent to use the required tools/resources, and (2) include a lightweight re-validation step in the subagent prompt.

**Resumption table**: Build from the artifact list — one row per stage, mapping its output artifact to a "skip this phase" decision.

### Step 8: Validate generated output

After generating all files, perform both `/skill-creator`'s validation checklist (for orchestrator skills) and the Loop-specific checks below:

**Plugin structure**:
- [ ] `.claude-plugin/plugin.json` exists with valid `name`, `description`, and `keywords` (includes `"loop-pipeline"`)
- [ ] Plugin `name` matches the skill prefix
- [ ] All skills are under `skills/` directory

**Pipeline completeness**:
- [ ] Every stage in `stages.md` has a corresponding file in `skills/<prefix>/stages/`
- [ ] Every artifact in `artifacts.md` has a corresponding file in `skills/<prefix>/contracts/`
- [ ] Every workflow has an orchestrator skill
- [ ] Every artifact is produced by exactly one stage
- [ ] Every artifact is consumed by at least one stage (no dead outputs)
- [ ] Every gate in `gates.md` appears in an orchestrator
- [ ] Every loop in `loops.md` appears in an orchestrator

**Reference integrity**:
- [ ] Every stage file references contract files that exist in `skills/<prefix>/contracts/`
- [ ] Every orchestrator references stage files that exist in `skills/<prefix>/stages/`
- [ ] Workspace file paths are consistent across all stage files and orchestrators
- [ ] Orchestrator gate criteria match contract validation rules

**Sink safety:**
- [ ] Every Emit stage file includes idempotency strategy and sink format requirements
- [ ] Every gate before an Emit stage validates the artifact is complete and write-ready
- [ ] No loops route back through Emit stages with iteration caps >3
- [ ] Notification sinks are configured as fire-and-forget (non-blocking on failure)
- [ ] Orchestrator precondition checks cover all declared sources and sinks
- [ ] Stages delegated to subagents propagate relevant preconditions into the subagent prompt, including a re-validation step

**Context isolation**:
- [ ] Every stage is delegated to a subagent
- [ ] Semantic gates run in dedicated subagents, not inline
- [ ] The orchestrator's own context contains only orchestration state, not stage working memory
- [ ] Each subagent prompt includes only the stage file, relevant contracts, and input artifact path

**Self-containment** (at the pipeline level):
- [ ] No file references `loop-workspace/` design artifacts or framework docs
- [ ] Each stage file's guidance is actionable without external context
- [ ] The plugin directory forms a complete, portable unit

### Step 9: Present results

Summarise what was generated:
- File count (plugin manifest + contracts + stages + orchestrator skills)
- Plugin name and invocation format (`/<prefix>:run`)
- Any design elements that couldn't be cleanly mapped (with explanation)
- Installation: `claude --plugin-dir .` for local testing (or `--plugin-dir ./<subdir>` if output was to a subdirectory), or publish to a marketplace for distribution

## Guidance

### Delegation to `/skill-creator`

`/skill-creator` owns skill structure, writing style (imperative form, third-person descriptions), progressive disclosure, and validation. This skill owns the pipeline-specific content.

`/skill-creator` is used only for **orchestrator skills** (which have `SKILL.md` frontmatter and are invocable via slash commands). Stage files and contract files are plain reference documents, not skills.

### The Shared Resource Directory

The `skills/<prefix>/` directory within the plugin contains all stage instructions and artifact contracts, shared across workflows.

**Why not one skill per stage?** Stage skills installed independently would each need to inline their input and output artifact schemas — duplicating contracts across every producer and consumer. The shared resource directory eliminates this duplication.

**Why not put contracts in the workspace?** The workspace (`<prefix>-workspace/`) is for runtime artifacts — the actual data produced by pipeline execution. The shared resource directory is for design-time definitions. Keeping them separate prevents confusion between "what the pipeline produces" and "how the pipeline is defined."

### Stages Are Reference Documents, Not Skills

Stage files are instruction documents that orchestrators read at the appropriate time. They are not independently invocable skills. This is intentional:

- **Context isolation**: Each stage runs in a subagent with fresh context.
- **Sequencing control**: The orchestrator controls when each stage runs.
- **Simplicity**: Users run one command (`/<prefix>:run`).

### Naming Conventions

- **Skill prefix**: Short, lowercase, hyphenated. Describes the pipeline's domain.
- **Stage file names**: Kebab-cased verb or verb-noun from stage name.
- **Contract file names**: Kebab-cased artifact name.
- **Orchestrator names**: `run` (single workflow) or `run-<workflow>` (multiple).
- **Workspace directory**: `<prefix>-workspace/`.

### Observability

Orchestrator skills should track and report:
- Gate pass/fail rates
- Loop iteration counts
- Artifact snapshots
- Gate decisions
- Sink writes (for Emit stages: what was written, to which target, whether it succeeded)

Include a "Pipeline Run Summary" section at the end of each orchestrator run.

### What Not to Generate

- **Don't generate runtime code.** Skills are prompt documents, not programs.
- **Don't generate tests.** Skills are validated by `/loop:audit-implementation`.
- **Don't generate documentation beyond the skills.**
- **Don't add framework concepts** not directly needed for the stage or orchestrator.

### Handling Design Gaps

- **Missing context specs**: Generate stage files without detailed context guidance. Note which stages would benefit from `/loop:phase-context`.
- **Missing gates/loops**: Generate the shared resource directory only. Tell the user the orchestrator needs `/loop:phase-gates` and `/loop:phase-feedback`.
- **Ambiguous artifact formats**: Ask the user to clarify. Don't guess at field structures.
- **Stages that don't map cleanly**: Generate them as stage files but note in guidance that they're mechanical, not analytical.
