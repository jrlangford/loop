---
name: design
description: "Workflow: guided greenfield pipeline design — walks through all design phases from transformation definition to review. Use when designing a new LLM pipeline from scratch."
argument-hint: "[task-description]"
---

# Loop: Design Workflow

Orchestrate the full design-forward workflow for a new LLM pipeline. This skill guides the user through each phase in sequence, checking preconditions and tracking progress.

## Workflow Sequence

```
Stage level:  /loop:phase-define → /loop:phase-decompose → /loop:phase-artifacts → /loop:phase-context
Workflow level:  /loop:phase-gates <name> → /loop:phase-feedback <name>
Review:  /loop:review
```

## How to Run

### Step 1: Check workspace state

Look for `loop-workspace/` in the current project directory.

- **No workspace**: Start from `/loop:phase-define` (Step 2)
- **Workspace exists with some artifacts**: Inventory what's present. Determine which phase to resume from — the first phase whose output artifact is missing. Present status to the user and ask if they want to continue from where they left off or start fresh.

### Step 2: Run stage-level phases

These produce reusable, workflow-independent artifacts.

| Phase | Skill | Precondition | Produces |
|-------|-------|-------------|----------|
| 1 | `/loop:phase-define` | None | `transformation.md` |
| 2 | `/loop:phase-decompose` | `transformation.md` exists | `stages.md` |
| 3 | `/loop:phase-artifacts` | `stages.md` exists | `artifacts.md` |
| 4 | `/loop:phase-context` | `stages.md` + `artifacts.md` exist | `context-specs.md` |

Before each phase:
- Verify preconditions are met (upstream artifacts exist)
- Tell the user which phase they're entering and what it produces

After each phase:
- Confirm the output artifact was written
- Ask the user if they're satisfied or want to re-run the phase
- If satisfied, proceed to the next phase

### Step 3: Name the workflow

After stage-level artifacts are complete, ask the user to name the workflow. If only one workflow is planned, "default" is fine. If the user wants multiple workflows over the same stages, they can re-run Steps 4–5 with different names.

### Step 4: Run workflow-level phases

These produce artifacts scoped to the named workflow under `loop-workspace/workflows/<name>/`.

| Phase | Skill | Precondition | Produces |
|-------|-------|-------------|----------|
| 5 | `/loop:phase-gates <name>` | `stages.md` + `artifacts.md` exist | `workflows/<name>/gates.md` |
| 6 | `/loop:phase-feedback <name>` | Above + `workflows/<name>/gates.md` exists | `workflows/<name>/loops.md` |

### Step 5: Review

Run `/loop:review`. It reviews stage-level artifacts and the active workflow.

Before presenting results, verify the design includes **context isolation guarantees**:
- `context-specs.md` should specify that each stage runs in a fresh context (subagent delegation) — not inline in the orchestrator
- Semantic gates should be specified as running in dedicated clean contexts (artifact + validation criteria only), not sharing the producing stage's context
- If `context-specs.md` is silent on isolation model, flag this as a WARNING to the user and suggest re-running `/loop:phase-context` to address it

Then:
- If no ERROR-severity issues: the design is complete. Present the full artifact inventory.
- If ERROR-severity issues exist: present them and ask the user which to address. For each, identify which upstream skill to re-run. After fixes, re-run `/loop:review` (max 3 review cycles).

### Step 6: Additional workflows (optional)

After the first workflow is complete, ask the user if they want to define another workflow over the same stages. If yes, return to Step 3 with a new workflow name. The stage-level artifacts are already done — only the workflow-level phases need to run again.

### Step 7: Preconditions (optional)

If any stages have source or sink dependencies (external reads or writes), ask the user whether to define preconditions for this workflow. Preconditions validate that external dependencies are reachable and properly configured before the first stage runs — preventing mid-pipeline failures due to expired tokens, misconfigured integrations, or unavailable services.

If the user wants preconditions:
- List all source and sink dependencies from `stages.md`
- For each, ask: required (abort if missing) or optional (warn and continue in degraded mode)?
- Note any credentials, API tokens, or configuration that must be validated
- If any stages will be delegated to subagents (parallel workers, decompose-aggregate patterns), note which preconditions must be propagated to subagent prompts — subagents run in isolated contexts and may not inherit the main agent's tool access, network permissions, or MCP server connections
- Write preconditions to `loop-workspace/workflows/<name>/preconditions.md`

If the pipeline has no external dependencies, skip this step.

### Step 8: Completion

When all workflows are designed (review passes or user accepts remaining issues):
- Present a summary: stage count, artifact count, workflow count, gates and loops per workflow
- Note any accepted warnings
- The `loop-workspace/` directory contains the complete specification
- Suggest running `/loop:implement` to generate Claude Code skills from the design

## Guidance

- **You are the orchestrator, not the executor.** Each phase is handled by its own skill. Your job is sequencing, precondition checking, and progress tracking.
- **The user can exit at any point.** Re-invoking `/loop:design` should detect existing workspace state and resume.
- **Don't skip phases.** Even if the user says "I don't need gates," run `/loop:phase-gates` — it may flag that explicitly. The skill will handle the "no gates needed" case.
- **Pass `$ARGUMENTS` to `/loop:phase-define`** if the user provided a task description.
- **Stage-level artifacts are shared.** If the user defines multiple workflows, stages, artifacts, and context specs are defined once and reused. Only gates and loops are per-workflow.
