---
name: loop-wf-design
description: "Workflow: guided greenfield pipeline design — walks through all design phases from transformation definition to review. Use when designing a new LLM pipeline from scratch."
argument-hint: "[task-description]"
---

# Loop: Design Workflow

Orchestrate the full design-forward workflow for a new LLM pipeline. This skill guides the user through each phase in sequence, checking preconditions and tracking progress.

## Workflow Sequence

```
Stage level:  /loop-define → /loop-decompose → /loop-artifacts → /loop-context
Workflow level:  /loop-gates <name> → /loop-feedback <name>
Review:  /loop-review
```

## How to Run

### Step 1: Check workspace state

Look for `loop-workspace/` in the current project directory.

- **No workspace**: Start from `/loop-define` (Step 2)
- **Workspace exists with some artifacts**: Inventory what's present. Determine which phase to resume from — the first phase whose output artifact is missing. Present status to the user and ask if they want to continue from where they left off or start fresh.

### Step 2: Run stage-level phases

These produce reusable, workflow-independent artifacts.

| Phase | Skill | Precondition | Produces |
|-------|-------|-------------|----------|
| 1 | `/loop-define` | None | `transformation.md` |
| 2 | `/loop-decompose` | `transformation.md` exists | `stages.md` |
| 3 | `/loop-artifacts` | `stages.md` exists | `artifacts.md` |
| 4 | `/loop-context` | `stages.md` + `artifacts.md` exist | `context-specs.md` |

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
| 5 | `/loop-gates <name>` | `stages.md` + `artifacts.md` exist | `workflows/<name>/gates.md` |
| 6 | `/loop-feedback <name>` | Above + `workflows/<name>/gates.md` exists | `workflows/<name>/loops.md` |

### Step 5: Review

Run `/loop-review`. It reviews stage-level artifacts and the active workflow.

- If no ERROR-severity issues: the design is complete. Present the full artifact inventory.
- If ERROR-severity issues exist: present them and ask the user which to address. For each, identify which upstream skill to re-run. After fixes, re-run `/loop-review` (max 3 review cycles).

### Step 6: Additional workflows (optional)

After the first workflow is complete, ask the user if they want to define another workflow over the same stages. If yes, return to Step 3 with a new workflow name. The stage-level artifacts are already done — only the workflow-level phases need to run again.

### Step 7: Completion

When all workflows are designed (review passes or user accepts remaining issues):
- Present a summary: stage count, artifact count, workflow count, gates and loops per workflow
- Note any accepted warnings
- The `loop-workspace/` directory contains the complete specification
- Suggest running `/loop-implement` to generate Claude Code skills from the design

## Guidance

- **You are the orchestrator, not the executor.** Each phase is handled by its own skill. Your job is sequencing, precondition checking, and progress tracking.
- **The user can exit at any point.** Re-invoking `/loop-wf-design` should detect existing workspace state and resume.
- **Don't skip phases.** Even if the user says "I don't need gates," run `/loop-gates` — it may flag that explicitly. The skill will handle the "no gates needed" case.
- **Pass `$ARGUMENTS` to `/loop-define`** if the user provided a task description.
- **Stage-level artifacts are shared.** If the user defines multiple workflows, stages, artifacts, and context specs are defined once and reused. Only gates and loops are per-workflow.
