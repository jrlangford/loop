---
description: "Workflow: check alignment between a pipeline's design artifacts and its current implementation — surfaces drift, gaps, and mismatches. Use when design and implementation may have diverged over time."
argument-hint: "[path-or-description]"
---

# Loop: Align Design and Implementation Workflow

Orchestrate the continuous alignment workflow: audit an implementation against existing design artifacts, then guide the user through resolving discrepancies.

**Precondition**: Design artifacts must already exist in `loop-workspace/` (from `/loop:design` or `/loop:reverse`). If they don't, suggest running `/loop:design` (greenfield) or `/loop:analyze` (existing code) first.

## Workflow Sequence

```
/loop:audit → resolve discrepancies → /loop:audit (verify)
```

## How to Run

### Step 1: Verify design artifacts exist

Check `loop-workspace/` for design artifacts (`stages.md`, `artifacts.md`, etc.).

- **Design artifacts present**: Proceed to Step 2
- **No design artifacts**: Stop. Tell the user that `/loop:align` compares implementation against design — there's nothing to compare against yet. Suggest:
  - `/loop:design` to create design artifacts from scratch
  - `/loop:analyze` to reverse-engineer the implementation first

### Step 2: Run audit with discrepancy analysis

Run `/loop:audit` with `$ARGUMENTS` (the path or description of the implementation).

Since design artifacts exist, the audit will include a Design–Implementation Discrepancies section classifying each discrepancy as: design drift, implementation gap, structural mismatch, or undesigned behavior.

Pay special attention to **context isolation drift** — where the design specifies subagent delegation for stages but the implementation executes stages inline in the orchestrator, or where the design requires semantic gates in clean dedicated contexts but the implementation evaluates them in the producing stage's context. Context isolation drift is particularly insidious because it silently degrades pipeline quality without causing obvious failures.

### Step 3: Triage discrepancies

Present discrepancies grouped by resolution direction:

**Update design** (drift, undesigned behavior that's intentional):
- The implementation has evolved. The design artifacts need to catch up.
- Suggest which `/loop:*` design skill to re-run for each.
- If drift involves new external sinks (writes added since design was written), prioritize — undocumented sinks are a traceability and safety risk. The design's stage specs need updating to document the new sink and its idempotency strategy.

**Update implementation** (gaps, undesigned behavior that's accidental):
- The design specifies something the implementation doesn't do, or the implementation does something unintended.
- These are code changes, not design skill re-runs.

**Resolve structural mismatches** (requires a decision):
- Design and implementation model the same thing differently.
- Present both models and ask the user which is correct.

Ask the user to decide on each discrepancy before proceeding.

### Step 4: Apply resolutions

For design updates:
- Run the appropriate `/loop:*` design skill to update the artifact
- Verify the updated artifact is consistent with the rest of the design

For implementation updates:
- The user makes code changes (outside this workflow)

### Step 5: Verify alignment

After resolutions are applied, re-run `/loop:audit` to confirm discrepancies are resolved.

- If new discrepancies appeared (fixing one thing broke another): flag and triage again (max 2 alignment cycles)
- If clean: design and implementation are aligned. Present confirmation.

## Guidance

- **This is a maintenance workflow, not a design workflow.** It assumes both design and implementation exist. Its job is to keep them in sync.
- **Drift is normal.** Implementations evolve faster than documentation. The goal isn't to prevent drift but to periodically reconcile it.
- **Not every discrepancy needs resolution.** Some drift is intentional — the implementation improved on the design. In that case, update the design to match reality.
- **Keep alignment cycles short.** If resolving discrepancies keeps creating new ones, the design and implementation may have diverged too far for incremental alignment. Consider re-running `/loop:analyze` to create a fresh design baseline.
