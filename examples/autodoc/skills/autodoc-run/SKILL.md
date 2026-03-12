---
name: autodoc-run
description: Run the autodoc pipeline to extract structured behaviour documents from source code. Analyzes a codebase to identify decision boundaries and produces one behaviour document per boundary following a standardized template with contracts, scenarios, and traceability. Use when the user wants to document code behaviour, extract decision boundaries, generate behaviour specs, reverse-engineer behaviour documentation, or run `/autodoc-run`.
---

# Autodoc Pipeline

Extract structured behaviour documents from source code by surveying the codebase, identifying decision boundaries, and producing one behaviour document per boundary with contracts, scenarios, and traceability.

## Quick Start

1. Ask the user for the target scope (files/directories or "full repo") and any optional reference documents
2. Check for an existing `autodoc-workspace/` — if artifacts exist, offer to resume from the last completed phase
3. Run the pipeline phases in order, delegating each stage to a subagent

## Pipeline Overview

```
┌─────────────────┐     ┌──────────────────┐
│ Gather Refs (1) │     │ Survey Code (2)  │
│   [Enrich]      │     │   [Extract]      │
└────────┬────────┘     └────────┬─────────┘
         │                       │
         │              ┌────────▼─────────┐
         │              │ Gate: Structural  │
         │              │ Map Validity      │
         │              └────────┬─────────┘
         │                       │
         │    ┌──────────────────▼──────────┐
         └───►  Identify Boundaries (3)     │
              │   [Extract]                 │
              └──────────────┬──────────────┘
                             │
              ┌──────────────▼──────────────┐
              │ Gate: Boundary Quality       │
              │ (Schema + Semantic)          │
              └──────────────┬──────────────┘
                             │
              ┌──────────────▼──────────────┐
              │ Extract Behaviours (4)       │
              │ [Transform] — fan-out        │
              └──────────────┬──────────────┘
                             │
              ┌──────────────▼──────────────┐
              │ Gate: Document Conformance   │
              │ (per-document, in fan-out)   │
              └──────────────┬──────────────┘
                             │
              ┌──────────────▼──────────────┐
              │ Deduplicate Behaviours (5)   │
              │ [Evaluate]                   │
              └──────────────┬──────────────┘
                             │
              ┌──────────────▼──────────────┐
              │ Gate: Dedup Consistency       │
              └──────────────┬──────────────┘
                             │
              ┌──────────────▼──────────────┐
              │ Gate: Post-Pipeline          │
              │ Consistency (Semantic)       │
              └──────────────┬──────────────┘
                             │
                        Pipeline Output
```

Stages 1 and 2 are independent — run them in parallel.
Stage 4 boundaries are independent — run them in parallel where practical.

## Precondition Checks

Before starting the pipeline:

1. **Target scope** (required): Ask the user for files/directories to analyze, or whether to scan the full repo. Without this, the pipeline cannot start.
2. **References** (optional): If the user provides reference documents, validate accessibility:
   - Local files: verify paths exist using the Glob tool
   - URLs: no pre-check (Stage 1 handles fetch)
   - Notion pages: check if the Notion MCP server is connected. If not, warn the user that Notion references will be skipped — do not block the pipeline.
3. **Shared resources** (required): Verify the `autodoc/` directory is accessible (contains `stages/` and `contracts/` subdirectories). If not found, stop and tell the user to install the autodoc skill set.

## Resumption

Before running, check which artifacts already exist in `autodoc-workspace/`:

| Artifact | Workspace Path | Phase to Skip |
|----------|---------------|---------------|
| `analysis-request.md` | `autodoc-workspace/analysis-request.md` | Phase 0 |
| `reference-index.md` | `autodoc-workspace/reference-index.md` | Phase 1a |
| `structural-map.md` | `autodoc-workspace/structural-map.md` | Phase 1b |
| `boundary-list.md` | `autodoc-workspace/boundary-list.md` | Phase 2 |
| `behaviours/` (non-empty) | `autodoc-workspace/behaviours/` | Phase 3 |
| `deduplicated/` + `deduplication-report.md` | `autodoc-workspace/deduplicated/` | Phase 4 |

Report which phases were skipped due to existing artifacts.

---

## Phase 0: Initialize

1. Collect user input: target scope (file/directory paths or `full_repo`) and optional references list
2. Create `autodoc-workspace/` directory (and `behaviours/`, `deduplicated/` subdirectories)
3. Write `autodoc-workspace/analysis-request.md` with structured input:

```yaml
target_scope:
  mode: "specified" | "full_repo"
  paths: [<file/directory paths>]    # when mode = "specified"

references:                           # may be empty
  - { type: "file", locator: "<path>" }
  - { type: "url", locator: "<url>" }
  - { type: "notion", locator: "<page_id>" }
```

4. Run precondition checks (see above)

---

## Phase 1a: Gather References

Run in parallel with Phase 1b.

Delegate to a subagent via the Agent tool:

**Subagent prompt:**
> Read `autodoc/stages/gather-references.md` for your instructions. Read `autodoc/contracts/reference-index.md` for the output schema. Read the analysis request from `autodoc-workspace/analysis-request.md`. Write your output to `autodoc-workspace/reference-index.md`.

If references include Notion pages, append to the prompt:
> This pipeline uses Notion references. Use the Notion MCP server's `notion-fetch` tool. Perform a test call to verify the MCP server is connected before loading Notion pages — if it fails, report which references could not be loaded and continue with the rest.

After the subagent completes, verify `autodoc-workspace/reference-index.md` exists.

No gate after this stage — an empty or partial reference index is valid.

---

## Phase 1b: Survey Codebase

Run in parallel with Phase 1a.

Delegate to a subagent via the Agent tool:

**Subagent prompt:**
> Read `autodoc/stages/survey-codebase.md` for your instructions. Read `autodoc/contracts/codebase-structural-map.md` for the output schema. Read the analysis request from `autodoc-workspace/analysis-request.md`. Write your output to `autodoc-workspace/structural-map.md`. Use the Read, Glob, and Grep tools to explore the codebase. Process files individually — do not try to load the entire codebase at once.

After the subagent completes, verify `autodoc-workspace/structural-map.md` exists.

### Gate: Structural Map Validity (Schema + Metric)

Run inline after the subagent completes. Read `autodoc-workspace/structural-map.md` and check:

- [ ] Every file in target_scope is represented in the map
- [ ] Every construct has non-empty `name`, `signature`, and valid `line_range`
- [ ] `language` is detected for each file (not null or "unknown")
- [ ] At least one construct found across all files
- [ ] `test_mapping_conventions` is populated

**On failure → Survey Retry loop:**
- Re-run the Phase 1b subagent with failure details appended to the prompt: "Previous attempt failed validation. Fix these issues: [list failures]"
- Max retries: 2
- **Degradation detector**: Track count of successfully parsed files per iteration. If the count decreases between iterations (re-run broke previously working parses), stop and use the iteration with the highest parse count.
- **Escalation**: If <80% of files parsed after retries, report unparseable files to the user. Proceed with the partial map.

---

## Phase 2: Identify Boundaries

Wait for both Phase 1a and Phase 1b to complete.

Delegate to a subagent via the Agent tool:

**Subagent prompt:**
> Read `autodoc/stages/identify-boundaries.md` for your instructions. Read `autodoc/contracts/boundary-list.md` for the output schema. Read `autodoc/contracts/codebase-structural-map.md` and `autodoc/contracts/reference-index.md` for input schemas. Read `autodoc-workspace/structural-map.md` for the structural map. Read `autodoc-workspace/reference-index.md` for the reference index (may be empty — proceed without it if so). Write your output to `autodoc-workspace/boundary-list.md`. Use the Read tool to access source code files at the locations identified in the structural map.

After the subagent completes, verify `autodoc-workspace/boundary-list.md` exists.

### Gate: Boundary Quality (Schema + Semantic)

**Schema checks** — run inline:

- [ ] Every boundary has a single `type` from the enum (`conditional_branch` | `error_handling` | `validation_gate` | `state_transition` | `integration_point` | `config_driven`)
- [ ] `decision_summary` is one sentence per boundary
- [ ] `evidence` is non-empty for each boundary
- [ ] `location.file` values exist in the structural map

**Semantic checks** — delegate to a dedicated subagent with clean context:

**Semantic gate subagent prompt:**
> You are a boundary quality evaluator. Read the Boundary List from `autodoc-workspace/boundary-list.md` and the Codebase Structural Map from `autodoc-workspace/structural-map.md`. Evaluate:
>
> 1. **Accuracy spot-check**: For 3-5 boundaries, read the source code at each boundary's location using the Read tool. Does the `decision_summary` accurately describe the decision shown in `evidence`? Report any inaccuracies.
> 2. **Coverage reconciliation**: Compare the Boundary List against the Structural Map. For constructs with signatures suggesting decision patterns (error handling, state transitions, integration calls), check whether they were evaluated. Flag constructs that appear to contain decision boundaries but have no boundary entry.
> 3. **Exclusion validation**: For 2-3 constructs absent from the boundary list that appear to contain branching logic, read the source code and verify the exclusion is justified (trivial getter, boilerplate, language idiom).
>
> Report: list of issues found (false positives, missed boundaries, inaccurate summaries). If no issues, report "PASS".

Gate passes if schema checks pass AND semantic subagent reports PASS or only minor issues.

**On failure → Boundary Retry loop:**
- Re-run the Phase 2 subagent with gate feedback appended: "Previous attempt had these issues: [list from gate]. Fix these specific problems."
- Max retries: 2
- **Degradation detectors**:
  - *Boundary count stability*: If the count swings by more than 30% between iterations (e.g., 15 → 25 → 12), the stage is over-correcting. Stop and use the iteration with the lowest semantic gate issue count.
  - *Issue count trend*: If issue count does not decrease between iterations, the retry is not helping. Stop after one non-improving iteration.
- **Best-iteration selection**: Use the iteration with the lowest semantic gate issue count. If tied, prefer the later iteration.
- **Escalation**: Present the boundary list and flagged issues to the user. Let them decide which boundaries to keep, add, or remove.

---

## Phase 3: Extract Behaviours (Fan-Out)

Read `autodoc-workspace/boundary-list.md`. For each boundary entry, delegate to a separate subagent.

**Per-boundary subagent prompt:**
> Read `autodoc/stages/extract-behaviours.md` for your instructions. Read `autodoc/contracts/behaviour-document.md` for the output schema. Read `autodoc/contracts/boundary-list.md` for the input schema.
>
> Here is your boundary entry:
> ```
> [paste the specific boundary entry]
> ```
>
> Read the source code at the boundary's location using the Read tool. Check `autodoc-workspace/structural-map.md` for the test file mapping — if a test file exists for this boundary's file, read it and look for test functions covering this boundary's function. If reference_hints is non-empty, read matching entries from `autodoc-workspace/reference-index.md`. Write your output to `autodoc-workspace/behaviours/BHV-<hex>.md` (generate a random hex ID).

Boundaries can be processed in parallel since they are independent. Launch multiple subagents concurrently.

After all subagents complete, verify behaviour documents exist in `autodoc-workspace/behaviours/`.

### Gate: Document Conformance (Per-Document, Schema + Metric + Identity)

For each behaviour document, check inline:

- [ ] Document follows behaviour template structure
- [ ] All required sections present: classification, description, trigger, actors, contracts, scenarios, traceability
- [ ] `id` is valid `BHV-<hex>` format (4-6 hex characters)
- [ ] `category` is one of: `specified`, `implicit`, `undefined`
- [ ] `status` is `draft`, `source` is `implementation`
- [ ] At least one scenario (happy path with Given/When/Then)
- [ ] At least one code reference in traceability
- [ ] Non-testable conditions have explicit rationale
- [ ] Code references match the boundary's location (file and function correspond)
- [ ] `reference_hints` carried forward unchanged from boundary entry

**On failure → Document Retry loop (per-document):**
- Re-run only the failing boundary's subagent with validation failures appended to the prompt
- Max retries: 2
- **Degradation detector**: Track gate failure reasons across iterations. If the second iteration fails on *different* criteria than the first (fixing one problem introduced another), stop and use the iteration with fewer total failures.
- **Best-iteration selection**: Use iteration with fewer gate failures. If tied, prefer the iteration that passes the identity check (code reference accuracy matters more than structural completeness).
- **Escalation**: Include the malformed document with `status: draft` and a validation warning appended to its Notes section.

---

## Phase 4: Deduplicate Behaviours

Delegate to a subagent via the Agent tool:

**Subagent prompt:**
> Read `autodoc/stages/deduplicate-behaviours.md` for your instructions. Read `autodoc/contracts/deduplicated-behaviour-set.md` for the output schema. Read `autodoc/contracts/behaviour-document.md` for the input schema. Read all behaviour documents from `autodoc-workspace/behaviours/`. Write deduplicated documents to `autodoc-workspace/deduplicated/`. Write the deduplication report to `autodoc-workspace/deduplication-report.md`.

After the subagent completes, verify `autodoc-workspace/deduplicated/` has files and `autodoc-workspace/deduplication-report.md` exists.

### Gate: Deduplication Consistency (Schema)

Run inline:

- [ ] `total_extracted - duplicates_merged = final_count` (arithmetic consistency)
- [ ] Every BHV-id from the input set appears in the output set or in a merge record's `merged_from` list
- [ ] For each merge: the kept document contains all `code_references` and `test_references` from both the kept and merged documents
- [ ] No BHV-id appears in both the output set and a `merged_from` list

**On failure → Deduplication Retry loop:**
- Re-run the Phase 4 subagent with inconsistencies appended to the prompt
- Max retries: 1
- **Escalation**: Skip deduplication entirely. Copy the unmerged set from `autodoc-workspace/behaviours/` to `autodoc-workspace/deduplicated/`. Report the deduplication failure to the user.

---

## Phase 5: Post-Pipeline Consistency Gate (Semantic)

Delegate to a dedicated subagent with clean context:

**Consistency gate subagent prompt:**
> You are a consistency evaluator. Read the deduplicated behaviour documents from `autodoc-workspace/deduplicated/` — extract only code_references and traceability from each. Read the Codebase Structural Map from `autodoc-workspace/structural-map.md`. Evaluate:
>
> 1. **Stale references**: Does every `code_reference` (file:function, file:line) correspond to a construct in the structural map? List any that don't.
> 2. **Orphaned behaviours**: Do all code references point to files present in the structural map? List any pointing to absent files.
> 3. **Coverage gaps** (advisory, non-blocking): Are there constructs in the structural map with decision-boundary patterns (conditional branches, error handling, state transitions visible from signatures) not referenced by any behaviour document? List them — these are informational, not failures.
>
> Report: PASS/FAIL for stale+orphaned. Advisory list for coverage gaps.

**On failure (stale or orphaned) → Consistency Repair loop:**
- Re-extract only the affected boundaries through Phase 3 (with corrected locations from the structural map), then re-run Phase 4 (deduplication) with the mixed set of original + repaired documents
- Max iterations: 1
- **Degradation detector**: Compare stale/orphaned reference count before and after repair. If count does not decrease, stop and use the original.
- **Escalation**: Flag affected documents with a traceability warning in their Notes section. Include in output. Report to user.

**On advisory (coverage gaps):** Report the coverage gap list to the user at pipeline completion. Do not block output.

---

## Phase 6: Finalize

Report pipeline completion:

1. List all output files in `autodoc-workspace/deduplicated/`
2. Report deduplication statistics: extracted → merged → final count
3. Report any coverage gaps from the post-pipeline consistency gate
4. Report any documents with validation warnings or traceability issues
5. Print the Pipeline Run Summary (see below)

---

## Error Handling

- **Stage failure** (subagent crashes or produces no output): Report which stage failed and what the last successful artifact was. Suggest resuming from that point using the resumption table.
- **Human escalation**: When gate retries are exhausted, present the artifact and issues to the user. Ask whether to proceed with the current artifact, manually fix, or abort the pipeline.
- **Pipeline abort**: If a required stage fails after all retries and escalation, stop the pipeline. Preserve all workspace artifacts in `autodoc-workspace/` for diagnosis.

---

## Pipeline Run Summary

At the end of each run, report:

- **Gate results**: pass/fail for each gate, with criteria details for any failures
- **Loop iterations**: how many retries each loop used (0 = first attempt passed)
- **Artifact counts**: files surveyed, boundaries identified, behaviours extracted, duplicates merged, final output count
- **Coverage gaps**: constructs with potential decision boundaries not covered by any behaviour document
- **Warnings**: documents with validation warnings, references that failed to load
- **Degradation signals**: loops that hit their hard cap, escalations triggered

---

## Orchestration Rules

These rules govern how the orchestrator manages the pipeline. They exist to prevent context pollution, ensure gate independence, and maintain pipeline integrity.

1. **Delegate every stage to a subagent.** The orchestrator's context should contain only orchestration state — stage completion status, gate results, loop counters, degradation signals. Never execute stage transformations (code reading, boundary identification, document writing) in the orchestrator's own context. This prevents accumulated working memory from biasing later stages.

2. **Run semantic gates in dedicated subagents.** Semantic evaluation requires clean context — only the artifact under evaluation and the validation criteria. If a semantic gate runs in the orchestrator's context (which contains orchestration history) or in the producing stage's subagent (which contains transformation reasoning), the evaluation is biased. Schema and metric gates are deterministic and can run inline.

3. **Include only relevant context in subagent prompts.** Each subagent gets: the stage file, relevant contract files, and input artifact path. No prior stages' reasoning traces, no other stages' artifacts (unless explicitly specified as passthrough artifacts), no orchestration history.

4. **Propagate preconditions into subagent prompts.** Subagents may run in isolated contexts without the same tool access or network permissions as the orchestrator. When a stage needs specific tools (Read, Glob, Grep, WebFetch, Notion MCP), explicitly instruct the subagent to use them. For Notion references, include a re-validation step: "Perform a test call to verify the MCP server is connected before loading pages."

5. **Preserve all workspace artifacts.** Never delete intermediate outputs from `autodoc-workspace/`. Failed attempts, superseded artifacts, and gate feedback are valuable for diagnosis and resumption.

6. **Report progress after each phase.** Tell the user which phase completed, what was produced (artifact name and key stats like count), and what comes next.

7. **Gates are checkpoints, not bottlenecks.** Move through passing gates quickly. Spend time only on failures — diagnosing, retrying, or escalating.
