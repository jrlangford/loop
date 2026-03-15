---
description: "Workflow: extract a rich pipeline description from an existing implementation, then run it through the design and implement pipeline to produce a clean Loop plugin. Use on any multi-stage pipeline to rebuild it properly."
argument-hint: "[path-or-description]"
---

# Loop: Reverse-Engineer and Rebuild

Take an existing multi-stage pipeline implementation, extract a rich transformation description in Loop vocabulary, then feed it through the standard design and implementation pipeline to produce a clean, properly structured Loop plugin.

## Workflow Sequence

```
Extract description → /loop:design → /loop:implement → /loop:audit-implementation → Fix issues
```

## How to Run

### Step 1: Identify the implementation

`$ARGUMENTS` should identify the implementation. Accepts:
- A directory path (e.g., `skills/` or `src/pipeline/`)
- A description of what to reverse-engineer (e.g., "the DDD skills in this project")
- Nothing — ask the user what to analyze

### Step 2: Extract the transformation description

Read `loop/vocabulary.md` for the full definitions of stages, artifacts, gates, loops, sources, sinks, and stage classification. Use these definitions to map what you find in the implementation to Loop concepts.

Read the implementation files thoroughly. Adapt to the implementation type:
- **Claude Code plugin**: Look for `.claude-plugin/plugin.json`, `skills/<prefix>/stages/`, `skills/<prefix>/contracts/`, orchestrator skills.
- **Claude Code skills (one per stage)**: Each stage is an independent skill with its own `SKILL.md`.
- **Scripts/code**: Read orchestration logic, function signatures, data flow.
- **Mixed**: Read both skill definitions and code.

Use subagents for parallel discovery when the implementation has many files.

Produce a rich transformation description that captures everything `/loop:design` needs to produce proper artifacts without losing valuable elements from the source. The description must cover:

**Overall transformation:**
- What the pipeline takes as input (format, variability)
- What it produces as output (format, quality criteria)
- The gap between input and output — what work bridges them

**Stages discovered** (mapped to Loop vocabulary):
- Each stage's intent, mapped to a Loop category (Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit)
- What each stage actually does — the transformation logic, not just a label
- Dependencies between stages — what feeds what
- Stages that violate the one-verb heuristic (flag, but still capture what they do)

**Sources and sinks:**
- External resources stages read from (web, APIs, MCP servers, databases, filesystem)
- External targets stages write to (APIs, git, Slack, databases, notification services)
- How the implementation handles source unavailability
- Idempotency strategies for sinks (if any)

**Artifacts between stages:**
- What data passes between stages (structure, key fields)
- Which fields use enums/closed vocabularies vs free text
- Which fields carry source references vs paraphrased interpretations
- Identity fields that pass through unchanged

**Validation and feedback:**
- Gates or checks between stages (type, criteria, what happens on failure)
- Retry or revision loops (what triggers them, what gets fed back, iteration bounds)
- Human review points
- Missing validation — boundaries with no checks

**Context management:**
- What each stage loads into context
- Whether stages run in isolated contexts (subagents) or share context
- Whether semantic gates run in clean contexts
- History policy (explicit or implied)

**Domain constraints and complexity signals:**
- Error reinforcement risks
- Variable input sizes
- External dependency reliability concerns
- Anything that makes this pipeline harder than a simple linear chain

Write this description to `loop-workspace/extraction.md`. This file serves as the input to `/loop:design` in the next step.

Present the extraction to the user. Flag where interpretation was needed with `<!-- Synthesis note: ... -->` comments. Ask the user to review and correct before proceeding — errors here propagate through the entire design.

### Step 3: Run the design pipeline

Run `/loop:design` with the extracted description from `loop-workspace/extraction.md` as the task description input.

The design pipeline will produce proper artifacts — potentially restructuring stages, adding missing gates, designing feedback loops with proper termination conditions. It is not constrained to mirror the original implementation's structure; it designs from the transformation intent.

### Step 4: Implement

Run `/loop:implement` to generate a clean Loop plugin from the design artifacts.

### Step 5: Audit the implementation

Run `/loop:audit-implementation` against the generated plugin directory.

Present findings to the user.

### Step 6: Fix issues

For each ERROR and WARNING from the audit:
- **Implementation fixes**: edit the generated skill files directly
- **Design fixes**: update `loop-workspace/` artifacts and re-run `/loop:implement` for affected files

After fixes, re-run `/loop:audit-implementation` to verify. Max 2 audit-fix cycles.

### Step 7: Present results

Summarise the rebuild:
- Original implementation: what was analyzed (file count, type)
- Key elements preserved from the original (stages, sources, sinks, domain logic)
- Elements restructured by the design pipeline (merged stages, added gates, new feedback loops)
- Generated plugin: file count, invocation format (`/<prefix>:run`)
- Audit results: issues found and fixed
- Any remaining warnings

## Guidance

- **The extraction is the critical step.** Capture everything valuable from the original implementation — domain logic, external dependencies, validation criteria, complexity constraints. What the extraction misses, the design pipeline can't recover.
- **Map to vocabulary, don't just summarize.** "This skill calls an API" is a summary. "This stage is an Enriched Extract with a web API source, producing a structured entity list with closed-vocabulary classification fields" is a vocabulary mapping.
- **Flag interpretation.** When the implementation is ambiguous (is this one stage or two? is this a gate or just an if-statement?), use synthesis notes so the user can correct.
- **The design pipeline may restructure.** The original implementation might have Kitchen Sink stages, missing gates, or no feedback loops. The design pipeline will fix these. This is a feature — the point is to produce a properly structured pipeline, not to replicate the original's flaws.
- **Preserve the original.** This workflow generates a new plugin alongside the original implementation. It does not modify the original.
