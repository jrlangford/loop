---
name: audit
description: "Audit an existing implementation against Loop framework principles — anti-pattern checks, structural analysis, and contract alignment. Reads implementation files directly. If loop-workspace design artifacts exist, also reports design-implementation discrepancies. Use on any multi-stage pipeline."
argument-hint: "[path-or-description]"
---

# Loop: Audit Implementation

Check an existing multi-stage pipeline implementation against Loop framework principles and anti-patterns. Unlike `/loop:review` (which checks design artifacts), this skill reads the implementation directly.

If `loop-workspace/` design artifacts exist (from `/loop:phase-define` through `/loop:phase-context`, or from `/loop:reverse`), the audit also compares implementation behavior against design intent and reports discrepancies.

## Input

`$ARGUMENTS` should identify the implementation to audit. Accepts:
- A directory path (e.g., `skills/` or `src/pipeline/`)
- A description of what to audit (e.g., "the DDD skills in this project")
- Nothing — ask the user what to audit

## What You Produce

A single file: `loop-workspace/audit.md` — findings from anti-pattern checks, structural analysis, and (if design artifacts exist) design-implementation discrepancies.

This skill does not create design artifacts. To get an implementation into Loop vocabulary first, run `/loop:reverse`.

## How to Run

### Step 1: Read the implementation

Read implementation files to understand what the pipeline actually does. Adapt to the implementation type:
- **Claude Code skills**: Read each `SKILL.md` and supporting docs.
- **Scripts/code**: Read orchestration logic, function signatures, data flow.
- **Mixed**: Read both skill definitions and code.

Use subagents for parallel discovery when the implementation has many files.

Build a working understanding of the implementation at both levels:

**Stage level**: What transformation units exist, what artifacts pass between them, what each stage loads into context, what external sources each stage reads from, and what external sinks each stage writes to. Stages should be isolated transformations — they produce an artifact and stop, without knowing what comes next. Stages may be implemented as independent skills, as reference documents in a shared resource directory (read by an orchestrator), or as functions/modules in code.

**Workflow level**: How stages are sequenced, where validation gates are placed, what feedback loops exist, what iteration bounds and termination conditions are configured. This is the wiring — it should be lightweight orchestration, not transformation logic.

### Step 2: Check for design artifacts

Look for `loop-workspace/` in the current project directory. Check for:

**Stage-level artifacts**: `transformation.md`, `stages.md`, `artifacts.md`, `context-specs.md`

**Workflow-level artifacts**: `workflows/<name>/gates.md`, `workflows/<name>/loops.md` (check for multiple workflows)

If design artifacts exist, note them — they'll be used for discrepancy analysis in Step 5. Their presence does not change how Steps 3-4 run.

### Step 3: Run anti-pattern checks

Check the *implementation directly*. Implementation-level checks catch things design review misses.

**6.1 Kitchen Sink Stage**
- Does any implementation unit perform multiple transformation types?
- Are there units with complex internal phasing that could be separate stages?
- **Severity**: warning if 2 verbs, error if 3+

**6.2 Echo Chamber Loop**
- Are there loops that could run autonomously without convergence checks?
- Do revision/retry paths track whether they're making progress?
- **Severity**: error if no convergence check on autonomous loops; warning if human-gated loops lack progress tracking

**6.3 History Avalanche**
- Do late-pipeline stages read early-pipeline artifacts they don't need?
- Does context accumulate within stages across sub-phases?
- Are there stages that load all upstream outputs rather than specific fields?
- **Severity**: warning if unjustified history, error if full history in 3+ stages

**6.4 Phantom Feedback Loop**
- Are there validation gates that are unlikely to ever fail?
- Are there retry paths that make only cosmetic changes?
- Are human review gates specific enough to catch real problems?
- **Severity**: warning

**6.5 Hardcoded Chain**
- Do implementation units invoke their successor directly rather than producing an artifact and stopping?
- Could the same stage be reused in a different workflow without modification?
- **Severity**: warning

**6.6 Ouroboros**
- Are there circular dependencies between stages that aren't declared as intentional loops?
- **Severity**: error

**6.7 Telephone Game**
- Do inter-stage data structures rely on free-text interpretations where enums or source references would work?
- Are there long pipelines (5+ stages) with no mechanism to compare late-stage output against original input?
- Do data structures mix observed facts with evaluative conclusions in single fields?
- **Severity**: warning if free-text fields dominate without source references; error if 5+ stages with no identity verification and no re-grounding

**6.8 Fire-and-Forget Emit**
- Are there stages that write to external systems (APIs, databases, git, Slack)?
- Do those stages have idempotency markers (stable IDs, transaction references)?
- Are gates placed *before* external writes, not after?
- If loops or retry paths route back through an Emit stage, can writes be safely repeated without duplication?
- Are notification sinks handled as fire-and-forget (logged but non-blocking)?
- **Severity**: error if emit stage has no idempotency strategy; warning if loop re-entry through emit stage without tight cap

**Coverage requirement**: The audit report must address all 8 anti-patterns by name, even if no issue is found. For clean anti-patterns, include an INFO-level note confirming the check passed (e.g., "INFO: Ouroboros — no circular dependencies found"). This ensures every audit is verifiably complete — a missing anti-pattern means the check wasn't performed, not that the implementation is clean.

### Step 4: Run structural checks

These go beyond anti-patterns to assess implementation quality:

**Cross-stage contract alignment:**
- Does what Stage A produces actually match what Stage B expects?
- Are there implicit assumptions about artifact format not documented?
- Are there version/schema mismatches between producers and consumers?

**Error recovery:**
- What happens when a stage fails mid-execution?
- Is there checkpointing? Can the pipeline resume?
- Are partial artifacts left behind that could confuse re-runs?

**Context window budget (for LLM-based stages):**
- Estimate actual token usage per stage based on files loaded
- Flag stages that load supporting docs exceeding reasonable budgets
- Note whether the implementation manages context deliberately or just loads everything

**Source dependencies:**
- Does the implementation read from external resources (web, APIs, MCP servers, databases)?
- Are these sources declared in the stage definitions, or are they implicit/hidden?
- What happens when a source is unavailable — does the stage fail gracefully or crash?
- Are there stages assumed to be pure transformations that actually have undeclared external dependencies?

**Sink dependencies:**
- Does the implementation write to external systems (APIs, databases, git, Slack, notification services)?
- Are these sinks declared in the stage definitions, or are they hidden?
- Do Emit stages have idempotency markers (stable IDs, checksums, transaction references) to prevent duplicate writes on retry?
- Are gates placed *before* external writes to validate artifacts before they leave the pipeline?
- What happens if a sink write fails — does the stage retry safely, or risk partial/duplicate writes?
- Are notification sinks (Slack, email, webhooks) handled as fire-and-forget (non-blocking), or do failures incorrectly halt the pipeline?
- If loops or retry paths pass through Emit stages, are iteration caps tight (≤3) and idempotency explicitly addressed?

**Precondition checks:**
- Does the pipeline validate that external sources and sinks are reachable before starting? (E.g., API tokens valid, MCP servers connected, git branch writable, Slack channel exists.)
- If the pipeline has external dependencies but no precondition checks, flag as WARNING — mid-pipeline failures due to misconfigured integrations waste all prior work.
- If stages are delegated to subagents (parallel workers, decompose-aggregate), do the subagent prompts include the relevant preconditions? Subagents run in isolated contexts and may lack tool access, network permissions, or MCP server connections that the orchestrator validated. Flag as WARNING if subagents depend on external resources but receive no re-validation instructions in their prompts.

**Context isolation:**
- Does the orchestrator delegate stages to subagents (Agent tool), or does it execute stage transformations in its own context? An orchestrator that runs stages inline accumulates every stage's working memory — file reads, intermediate reasoning, correction attempts — creating the context pollution that staging is designed to prevent. Flag as WARNING if stages run in the orchestrator's context.
- Do semantic gates run in dedicated subagents with clean context (artifact + criteria only)? A semantic gate evaluated in the same context as the producing stage inherits the production trajectory, making it unreliable. Flag as WARNING if semantic gates run inline.
- When loops re-run a stage after gate failure, does the re-run use a fresh subagent? Re-running in the same context preserves the failed attempt's reasoning, anchoring the retry to the same errors. Flag as WARNING if retries share context with the failed attempt.

**Stage/workflow separation:**
- Are stages isolated transformations, or do they contain wiring logic (sequencing, gate checks, loop control)?
- Could the same stage be reused in a different workflow without modification?
- Is workflow-level configuration (gate criteria, iteration bounds, stage ordering) separate from stage definitions?
- Do stages invoke other stages directly, or do they produce an artifact and stop?

**Stages as skills (structural anti-pattern):**
- Are individual pipeline stages implemented as independently invocable skills (each with its own `SKILL.md` and slash command)? If so, flag as WARNING. Stages should be reference documents in a shared resource directory, read by an orchestrator skill — not standalone skills. The problems with stages-as-skills:
  - **Contract duplication**: Each stage skill must inline its input and output artifact schemas to be self-contained. The same schema gets duplicated across every producer and consumer. A contract change must propagate to every copy.
  - **No shared resources**: Stages in the same pipeline share concepts (enums, taxonomies, workspace conventions) that must be copy-pasted into each skill rather than defined once.
  - **Skill proliferation**: A 6-stage pipeline produces 7 skills (6 stages + orchestrator). Users see N slash commands when they need one entry point.
  - **False independence**: Stage skills appear independently invocable but rarely make sense outside their pipeline sequence. The independence is architectural overhead without practical benefit.
- The recommended structure is a shared resource directory (`<prefix>/`) with `stages/` (reference documents) and `contracts/` (artifact schemas), plus orchestrator skills (`<prefix>-run/`) as the only user-facing entry points.

**Loop safety:**
- Do all loops (including gate retry paths) have a hard iteration cap? A retry path without a maximum is an unbounded loop.
- Do loops track quality or progress across iterations? Without tracking, there's no way to detect degradation — the loop may make things worse without anyone noticing.
- When degradation is detected, does the loop select the best iteration's output or always use the last? Using the last iteration's output means more iterations create more opportunities to end in a worse state.
- For balancing loops: are the evaluating and refining stages separate inference calls with separate contexts? Combining evaluation and refinement in the same context allows the producer's trajectory to bias the evaluation.
- Are iteration bounds reasonable? Flag caps above 10 for balancing loops, above 5 for reinforcing loops, or above 3 for loops involving Emit stages — high caps with stochastic stages increase the chance of ending in a degraded state, and with Emit stages also risk duplicate external writes.

**Stochastic validation:**
- LLM stages are stochastic — the same input can produce different outputs across runs. Does the implementation track run-to-run variance? Look for: gate pass/fail logging, loop iteration count tracking, output quality metrics across runs. If the pipeline has no mechanism to characterize its reliability distribution (gate pass rates, loop iteration distributions, output quality variance), flag as WARNING — single-run validation cannot capture whether the pipeline is reliable or just got lucky.
- **Severity**: warning if no variance tracking exists for pipelines with semantic gates or feedback loops

**Cross-unit dependencies:**
- Are there shared files or configurations that multiple stages depend on?
- Could changing a shared dependency break a downstream stage silently?

**Handoff drift resilience:**
- Do inter-stage data structures use enums and closed vocabularies where the domain allows, or do they pass free-text fields that invite reinterpretation across stages?
- Do artifacts carry source references (file paths, line numbers, verbatim quotes) alongside interpretation, or do stages only pass their summary/paraphrase forward?
- Are factual observations and evaluative judgments kept in distinct fields, or merged in ways that allow judgment drift to contaminate the factual record?
- Are there fields that should remain stable across stages (identity fields) but are not verified?
- For long pipelines: is there any mechanism to compare late-stage artifacts against the original input, or does the pipeline assume each handoff preserves fidelity?
- Do semantic validation steps (LLM-based quality checks) share context with the producing stage, or do they operate in an independent context?

### Step 5: Compare against design (if artifacts exist)

If `loop-workspace/` contains design artifacts, compare each against what the implementation actually does. Check both levels:

- **Stage-level**: Do the implemented stages match `stages.md`? Do the actual data contracts match `artifacts.md`? Do context loads match `context-specs.md`?
- **Workflow-level**: Do the implemented gates match `workflows/<name>/gates.md`? Do the actual feedback loops match `workflows/<name>/loops.md`? If multiple workflows are defined, are they all implemented?

For each discrepancy, classify it:

| Type | Meaning | Resolution direction |
|------|---------|---------------------|
| **Design drift** | Implementation evolved past the design | Update the design artifact |
| **Implementation gap** | Design specifies something the implementation doesn't do | Implement it, or remove from design |
| **Structural mismatch** | Same thing modeled differently | Decide which is correct, align the other |
| **Undesigned behavior** | Implementation does something design doesn't mention | Add to design if intentional, remove if accidental |

Skip this section entirely if no design artifacts exist.

### Step 6: Write the audit report

Write `loop-workspace/audit.md`:

```markdown
# Pipeline Implementation Audit

## Summary
- **Implementation type**: [Skills | Agent framework | Scripts | Mixed]
- **Files examined**: [count and key files]
- **Stages identified**: [count]
- **Issues found**: [count by severity]
- **Design artifacts found**: [Yes — list files | No]

## Issues

### [ERROR | WARNING | INFO]: [Issue title]
- **Location**: [Implementation file and section]
- **Anti-pattern**: [Name, if applicable — e.g., Kitchen Sink Stage, Echo Chamber Loop]
- **Finding**: [What's wrong — reference the actual implementation]
- **Suggested fix**: [How to address it]
- **Loop skill**: [Which /loop:* skill's output would guide the fix, if any]

### [Next issue]
...

## Design–Implementation Discrepancies
<!-- Only if design artifacts exist. Omit section entirely otherwise. -->

### [DRIFT | GAP | MISMATCH | UNDESIGNED]: [Title]
- **Design says**: [What the design artifact specifies]
- **Implementation does**: [What the implementation actually does]
- **Artifact**: [Which loop-workspace file]
- **Resolution**: [Update design | Implement | Align | Add or remove]

### [Next discrepancy]
...

## Implementation Health
<!-- Overall assessment. Strengths and risks. Be direct. -->
```

### Step 7: Present findings

Walk the user through issues by severity (errors first). For each, reference the specific implementation file.

If discrepancies were found, present them grouped by resolution direction — design updates together, implementation gaps together.

The user or a workflow skill (`/loop:analyze`, `/loop:align`) determines what to run next.

## Guidance

- **Read the implementation, not just the structure.** Pay attention to edge cases, error paths, and implicit behavior.
- **Don't penalize non-Loop implementations for not being Loop.** Focus on whether the *underlying patterns* are sound, not whether Loop vocabulary was used.
- **Implementation context matters.** A human-gated pipeline has different risks than a fully autonomous one. Calibrate severity accordingly.
- **Be direct about strengths too.** If the implementation handles something well, say so. The audit should give an accurate picture, not just a list of problems.
