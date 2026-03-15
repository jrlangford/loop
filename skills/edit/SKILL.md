---
description: "Workflow: edit an existing pipeline design — maps staleness from a modification, selectively re-executes affected stages, and reviews consistency. Use when modifying a design that already exists in loop-workspace/."
---

# Loop: Edit Workflow

Orchestrate the edit workflow for an existing Loop pipeline design. Take a user's modification request, trace its impact through the design's connection graph, selectively re-execute only the affected stages, and verify consistency of the updated design.

## Pipeline Overview

```
User modification applied to artifact
        │
        ▼
  Map Staleness (Stage 8)
        │
        ▼
  Staleness Map Validation gate ◄──── Staleness Map Correction loop (cap 2)
        │
        ▼
  Staleness Map Acceptance gate (human, conditional)
        │
        ▼
  Selective Re-execution
  ┌─────────────────────────────────────────────────────┐
  │ For each stale artifact, in pipeline order:         │
  │   Re-run producing stage → same gates/loops as      │
  │   design workflow (Stages 1-6 use inherited gates)  │
  │   Stages 4+5 may run in parallel if both stale     │
  └─────────────────────────────────────────────────────┘
        │
        ▼
  Review Design (Stage 7)
        │
        ▼
  Review Correction loop (cap 3 cycles, cascade budget 10)
  ── with edit-specific addenda (no Map Staleness re-invocation)
        │
        ▼
  Updated design complete
```

## Inputs

- **Existing workspace**: `loop-workspace/` with design artifacts from a prior `/loop:design` run
- **Modification request**: What the user wants to change (natural language or specific artifact edits)
- **Interaction level**: `minimal` (default), `per-stage`, or `none` — controls human checkpoints

## Preconditions

Before starting, verify `loop-workspace/` exists and contains at minimum:

- `loop-workspace/stages.md`
- `loop-workspace/artifacts.md`

If either is missing, there is no design to edit. Direct the user to `/loop:design` instead.

Also inventory all existing artifacts so you know the full set for staleness analysis:
- `loop-workspace/transformation.md`
- `loop-workspace/stages.md`
- `loop-workspace/artifacts.md`
- `loop-workspace/context-specs.md`
- `loop-workspace/workflows/<name>/gates.md`
- `loop-workspace/workflows/<name>/loops.md`
- `loop-workspace/workflows/<name>/review.md`

## Execution

### Phase 1: Apply Modification

1. Understand the user's modification request. Determine which artifact file(s) it affects directly.
2. Help the user apply the change to the appropriate artifact file. This may involve editing `transformation.md`, adding/removing a stage in `stages.md`, changing an artifact spec in `artifacts.md`, etc.
3. Record the **change source** for staleness analysis:
   - Which file was modified
   - What specifically changed (added, removed, or altered content)
   - Classify as **structural** (added/removed stages, changed dependencies — deep cascade) or **content** (modified criteria, updated fields — shallow cascade)

### Phase 2: Map Staleness

**Delegate to a subagent.** Provide:
- The stage file: `loop/stages/map-staleness.md`
- The contract file: `loop/contracts/staleness-map.md`
- All workspace artifacts (full file contents)
- The modification details from Phase 1 (change source, what changed, classification)

The subagent writes the staleness map to `loop-workspace/staleness-map.md`.

#### Gate: Staleness Map Validation

Run after the subagent completes. Two parts:

**Schema checks** (inline):
- [ ] Every workspace artifact appears in either `stale_artifacts` or `unaffected_artifacts`
- [ ] Every entry in `stale_artifacts` has: `artifact`, `reason`, `cascade_path`, `recommended_stage`, `cascade_type`
- [ ] Every entry in `unaffected_artifacts` has: `artifact`, `reason`
- [ ] Every `recommended_stage` value exists in `loop-workspace/stages.md`
- [ ] `change_source` field is present and non-empty

**Semantic checks** (clean subagent — provide only the staleness map and workspace artifacts, no producing-stage context):
- [ ] Every `cascade_path` is traceable through the connection graph (each hop corresponds to a real dependency, feedback connection, or loop edge)
- [ ] No invalid cascade paths (referencing connections that do not exist)
- [ ] No directly-dependent artifact is incorrectly marked as unaffected (check immediate forward dependencies of the change source)

**On failure** → Staleness Map Correction loop.

#### Loop: Staleness Map Correction

- **Type**: Balancing
- **Path**: Map Staleness → Staleness Map Validation → Map Staleness
- **Hard cap**: 2 retries
- **Degradation signal**: Validation failure count. If failures do not decrease between iterations, escalate.
- **Escalation**: Present the staleness map to the user as advisory. Let the user decide which artifacts to treat as stale.

#### Gate: Staleness Map Acceptance (Human, Conditional)

- At `minimal` or `per-stage` interaction level: Present the staleness map to the user. Show which artifacts are flagged stale, with reasons and cascade paths.
  - **User accepts as-is** → pass, proceed with the map unchanged.
  - **User modifies** (adds or removes artifacts from the stale set) → pass, proceed with the user's modified map.
  - **User rejects the analysis** → route back to Map Staleness with user feedback. Max 1 retry. If user rejects again, abort the edit workflow.
- At `none` interaction level: Skip this gate entirely.

### Phase 3: Selective Re-execution

Determine which stages to re-run from the staleness map. Order them according to pipeline order from `stages.md`:

1. Define Transformation (Stage 1) → produces `transformation.md`
2. Decompose Stages (Stage 2) → produces `stages.md`
3. Specify Artifacts (Stage 3) → produces `artifacts.md`
4. Budget Context (Stage 4) → produces `context-specs.md`
5. Place Gates (Stage 5) → produces `workflows/<name>/gates.md`
6. Design Feedback (Stage 6) → produces `workflows/<name>/loops.md`

For each stale artifact in pipeline order:

1. Identify the producing stage from `recommended_stage` in the staleness map.
2. **Delegate to a subagent** with the same delegation protocol as the design workflow:
   - Provide the stage file from `loop/stages/`
   - Provide the relevant contract file from `loop/contracts/`
   - Provide upstream artifacts as input. If an upstream artifact was NOT flagged stale, use the existing version. If it was stale and has already been re-executed in this pass, use the freshly updated version.
3. **Run the same gates as the design workflow** for that stage:
   - Define Transformation → Transformation Completeness gate
   - Decompose Stages → Decomposition Validity gate
   - Specify Artifacts → Contract Integrity gate + Re-grounding gate
   - Place Gates → Gate Referential Integrity gate
   - Budget Context → ungated
   - Design Feedback → ungated
4. **Handle the same loops as the design workflow** for that stage:
   - Transformation Refinement (cap 2)
   - Decomposition Correction (cap 3)
   - Contract Correction (cap 2)
   - Re-grounding Correction (cap 1)
   - Gate Correction (cap 2)

**Important**: Gates validate against CURRENT upstream artifacts — the versions that exist right now in the workspace, whether re-executed in this pass or carried over unchanged. Do not validate against the original pre-edit versions.

**Parallelism**: Stages 4 (Budget Context) and 5 (Place Gates) can run in parallel if both are stale, since they share the same upstream dependencies (`stages.md` + `artifacts.md`) and produce independent outputs. All other stages must run sequentially in pipeline order.

**Workflow scope**: If multiple workflows exist under `loop-workspace/workflows/`, re-execute workflow-scoped stages (Place Gates, Design Feedback) for every workflow that references the affected stages.

### Phase 4: Review

1. **Delegate Review Design (Stage 7) to a subagent.** Provide:
   - The stage file: `loop/stages/review-design.md`
   - The contract file: `loop/contracts/review-results.md`
   - All workspace artifacts (updated versions)

2. Apply the **Review Correction loop** with edit-specific addenda:
   - **Inherited behavior**: cap 3 cycles, cascade budget 10 calls per cycle
   - **Additional termination criterion**: No new staleness detected in this cycle
   - **Additional degradation signal**: Review discovers artifacts that should have been in the staleness map
   - **Ouroboros prevention**: Do NOT re-invoke Map Staleness from review correction. If the review finds artifacts that should have been flagged stale but were not, emit a WARNING to the user. Do not cascade back to Phase 2.
   - **Additional check**: Verify consistency between re-executed and non-re-executed artifacts (boundary contracts still hold, references still resolve)

3. **Edit-specific review routing**:

   | Finding | Route |
   |---------|-------|
   | Missed staleness (artifact that should have been re-executed) | User notification as WARNING — do not re-invoke Map Staleness |
   | Inconsistency between re-executed and non-re-executed artifact | Re-run the producing stage of the re-executed artifact (non-re-executed is assumed correct) |

4. **Cross-workflow review**: If multiple workflows exist, run cross-workflow review after per-workflow reviews complete. Write cross-workflow results to `loop-workspace/review.md`.

5. **Verdict**:
   - PASS or PASS_WITH_WARNINGS → edit is complete
   - FAIL with actionable errors → apply review correction loop (re-run the indicated stages within cascade budget, then re-review)

## Resumption Table

When re-invoked, check for edit-specific artifacts to determine where to resume:

| Artifact | If present, resume from |
|----------|------------------------|
| No `staleness-map.md` | Phase 1 (Apply Modification) |
| `staleness-map.md` exists | Phase 3 (Selective Re-execution) — ask user to confirm the map is still valid |
| `staleness-map.md` + all stale artifacts refreshed | Phase 4 (Review) |
| `review.md` with PASS/PASS_WITH_WARNINGS | Edit already complete |

Present the current state and ask: "Continue from [next phase], or start fresh?"

## Error Handling

- **Stage failure**: Present the error to the user. Offer to retry the failed stage or abort. The workspace preserves all completed artifacts — partial re-execution progress is not lost.
- **Cascade budget enforcement**: Track inference calls within each review correction cycle. Max 10 additional calls (stages + gates + loops triggered by the cascade) per cycle. Reset the counter at the start of each review cycle. If the budget is exhausted mid-cycle, stop the cascade and present remaining issues to the user.
- **Human escalation**: When a gate escalates to human, present the issue clearly with the artifact and the specific problem. Wait for the user's decision before proceeding.
- **Pipeline abort**: If the user chooses to abort, the workspace is preserved. The staleness map and any partially re-executed artifacts remain. Re-invoking `/loop:edit` will detect existing state and offer to resume.

## Pipeline Run Summary

After completion, present:
- **Modification applied**: What changed and where
- **Staleness map**: How many artifacts were flagged stale vs. unaffected
- **Re-executed stages**: Which stages ran, with gate results and loop iteration counts
- **Skipped stages**: Which stages were not re-executed (and why — unaffected)
- **Review verdict**: PASS, PASS_WITH_WARNINGS, or FAIL with details
- **Warnings**: Any missed staleness detected during review, any user overrides to the staleness map
- **Cost**: Total inference calls (staleness mapping + re-execution + review)

## Guidance

- **Re-execute in pipeline order.** Even if only stages 3 and 5 are stale, run 3 first so that 5 gets the updated `artifacts.md` as input.
- **Use current upstream artifacts for gate validation.** Gates check the artifact against whatever is in the workspace now, not the pre-edit version.
- **Never re-invoke Map Staleness from review correction.** This prevents an Ouroboros loop where review triggers staleness mapping which triggers re-execution which triggers review. Flag missed staleness as a WARNING instead.
- **Be conservative with staleness.** It is cheaper to re-execute an unaffected stage than to miss a genuine inconsistency. When in doubt, include an artifact in the stale set.
- **Cascade budget: 10 calls per review correction cycle.** Count every subagent delegation, gate evaluation, and loop iteration. Reset at each new review cycle. This prevents runaway cascades.
- **You are the orchestrator, not the executor.** Each stage is handled by a subagent with its own stage file and contract. Your job is sequencing, gate checking, loop management, staleness tracking, and progress reporting.
- **Preserve the workspace.** Never delete artifacts from previous phases. Overwrite stale artifacts with fresh versions — the workspace is the pipeline's state.
