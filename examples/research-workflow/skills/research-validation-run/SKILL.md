---
name: research-validation-run
description: >-
  This skill should be used when the user wants to validate research claims in a markdown document.
  It orchestrates a multi-stage pipeline that extracts claims, classifies them, launches 3 parallel
  reviewer agents to independently verify each claim via web research, compares their findings,
  reconciles disagreements through up to 3 feedback rounds, and compiles a scored validation report.
  Trigger when: user asks to "validate research", "check claims", "verify citations", or
  "review research quality" for a markdown document.
---

# Research Validation Pipeline

Validate research claims in a markdown document through parallel independent review, agreement comparison, and iterative reconciliation.

## Pipeline Overview

```
Source Document
      │
      ▼
┌─────────────┐    ┌───────────────────────┐
│ Extract     │───▶│ Gate: Extraction      │──fail──▶ retry (max 2)
│ Claims      │    │ Completeness          │
└─────────────┘    └───────────┬───────────┘
                               │ pass
                               ▼
                   ┌─────────────────────┐
                   │ Classify Claims     │
                   └──────────┬──────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
       ┌────────────┐ ┌────────────┐ ┌────────────┐
       │ Verify     │ │ Verify     │ │ Verify     │
       │ Claims (1) │ │ Claims (2) │ │ Claims (3) │
       └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
             │               │               │
             ▼               ▼               ▼
       ┌────────────┐ ┌────────────┐ ┌────────────┐
       │ Gate:      │ │ Gate:      │ │ Gate:      │
       │ Citation   │ │ Citation   │ │ Citation   │
       │ Accuracy   │ │ Accuracy   │ │ Accuracy   │
       └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
             │               │               │
             └───────────────┼───────────────┘
                             │
                             ▼
                 ┌─────────────────────┐
                 │ Compare Assessments │◀─────────────────────┐
                 └──────────┬──────────┘                      │
                            │                                 │
                            ▼                                 │
                 ┌─────────────────────┐                      │
                 │ Gate: Agreement     │──no disputes──▶ Compile
                 │ Threshold           │──round 3───────▶ Compile
                 └──────────┬──────────┘                      │
                            │ disputes remain                 │
                            ▼                                 │
                 ┌─────────────────────┐                      │
                 │ Reconcile           │                      │
                 │ Disagreements       │                      │
                 └──────────┬──────────┘                      │
                            │                                 │
                            ▼                                 │
                 ┌─────────────────────┐                      │
                 │ Gate: Reconciliation│──stagnation──▶ Compile
                 │ Progress            │                      │
                 └──────────┬──────────┘                      │
                            │ progress                        │
                            └─────────────────────────────────┘

                 ┌─────────────────────┐    ┌───────────────────┐
                 │ Compile Report      │───▶│ Gate: Report      │──fail──▶ retry (max 2)
                 │                     │    │ Completeness      │
                 └─────────────────────┘    └────────┬──────────┘
                                                     │ pass
                                                     ▼
                                            Validation Report
```

## How to Run

### Precondition Checks

Before starting the pipeline, verify:

1. **Source document exists**: Check that the user has specified a markdown file to validate. Copy or symlink it to `research-validation-workspace/source-document.md`.
2. **Web search available**: Execute a test web search query to confirm web search is accessible. If unavailable, abort — the pipeline cannot function without web access for claim verification.

If preconditions fail, report which check failed and stop.

### Resumption

If `research-validation-workspace/` already exists with artifacts, check which phase to resume from:

| Artifact exists | Skip to |
|----------------|---------|
| `claim-list.md` | Phase 2 (Classify) |
| `typed-claim-list.md` | Phase 3 (Verify) |
| `reviewer-*-assessment.md` (all 3) | Phase 4 (Compare) |
| `agreement-report.md` | Phase 5 (Reconcile) or Phase 6 (Compile) |
| `validation-report.md` | Done — present the report |

Present the resumption point to the user and ask whether to resume or start fresh.

### Phase 1: Extract Claims

**Delegate to subagent.** Launch a subagent (Agent tool) with a prompt that includes:
- "Read `research-validation/stages/extract-claims.md` for stage instructions"
- "Read `research-validation/contracts/claim-list.md` for the output schema"
- "Read the source document from `research-validation-workspace/source-document.md`"
- "Execute the extraction and write the Claim List to `research-validation-workspace/claim-list.md`"

After the subagent completes, verify `research-validation-workspace/claim-list.md` exists.

#### Gate: Extraction Completeness

**Schema check** (inline — orchestrator reads the artifact):
- [ ] Every claim has a non-empty `text` field
- [ ] Every claim has a valid `location`
- [ ] No duplicate `claim_id` values
- [ ] `has_citation` is consistent with `citations` field

**Semantic check** (run in a **dedicated gate subagent** — not inline):
Launch a separate subagent whose prompt includes only the source document and the Claim List. Instruct it to check whether any verifiable claims in the source were missed. This subagent must not share context with the extraction subagent.

- [ ] No verifiable claims in the source document are missing from the Claim List

**On failure**: Re-launch the extraction subagent with the gate feedback appended to its prompt. Max 2 retries. After 2 retries, proceed with what was extracted and note potential incompleteness.

### Phase 2: Classify Claims

**Delegate to subagent.** Launch a subagent with a prompt that includes:
- "Read `research-validation/stages/classify-claims.md` for stage instructions"
- "Read `research-validation/contracts/typed-claim-list.md` for the output schema"
- "Read the Claim List from `research-validation-workspace/claim-list.md`"
- "Execute classification and write the Typed Claim List to `research-validation-workspace/typed-claim-list.md`"

After the subagent completes, verify `research-validation-workspace/typed-claim-list.md` exists.

No gate at this boundary — classification is best-effort and downstream stages handle ambiguous types gracefully.

### Phase 3: Verify Claims (parallel)

Launch 3 parallel reviewer subagents (Agent tool). Each reviewer's prompt must include:
- "Read `research-validation/stages/verify-claims.md` for stage instructions"
- "Read `research-validation/contracts/reviewer-assessment.md` for the output schema"
- "Read the Typed Claim List from `research-validation-workspace/typed-claim-list.md`"
- "Write output to `research-validation-workspace/reviewer-[N]-assessment.md`"

Each reviewer:
- Receives the same Typed Claim List
- Works independently with no access to other reviewers' outputs
- Uses web search to verify claims and check citations

**Precondition propagation**: Each reviewer subagent's prompt must explicitly instruct it to use the WebSearch tool for claim verification. Include a re-validation step: "Before verifying any claims, perform a test web search to confirm you have internet access. If the search fails, report the failure and stop — do not attempt to verify claims without web search capability." This is necessary because subagents run in isolated contexts and may not inherit the main agent's tool access or network permissions.

Each reviewer should use varied search strategies to reduce echo chamber risk.

#### Gate: Citation Accuracy (per reviewer)

For each reviewer assessment independently:

**Schema check:**
- [ ] `citation_valid` is non-null for every claim where `has_citation` was true
- [ ] `verdict` and `confidence` are valid enum values
- [ ] `evidence_found` entries have non-empty `source_url` and `relevant_excerpt`

**Metric check:**
- [ ] Every `claim_id` from the Typed Claim List appears exactly once (no dropped claims, no duplicates)

**On failure**: Re-launch only the failing reviewer subagent with feedback about missing citation checks or dropped claims. Max 1 retry per reviewer. After 1 retry, proceed with partial assessment — mark unchecked citations as `citation_valid: null`.

### Phase 4: Compare Assessments

**Delegate to subagent.** Launch a subagent with a prompt that includes:
- "Read `research-validation/stages/compare-assessments.md` for stage instructions"
- "Read `research-validation/contracts/agreement-report.md` for the output schema"
- "Read all 3 reviewer assessments from `research-validation-workspace/reviewer-[1-3]-assessment.md`"
- "Set `round_number` to [N]" (1 for initial comparison, incremented on loop re-entry)
- "Write the Agreement Report to `research-validation-workspace/agreement-report.md`"

After the subagent completes, verify `research-validation-workspace/agreement-report.md` exists.

#### Gate: Agreement Threshold

**Schema check** (inline):
- [ ] Every `claim_id` appears in exactly one of `agreed_claims` or `disputed_claims`
- [ ] `agreement_status` values are valid enums
- [ ] On rounds 2+: `previous_disagreement_points` is non-null for disputed claims

**Routing** (not pass/fail):
- If `disputed_claims` is empty → proceed to Phase 6 (Compile Report)
- If `round_number` is 3 and disputes remain → mark remaining as unresolvable, proceed to Phase 6
- Otherwise → proceed to Phase 5 (Reconcile Disagreements)

**On schema failure**: Re-launch the comparison subagent with feedback. Max 1 retry. After 1 retry, abort — a malformed Agreement Report cannot be safely routed.

### Phase 5: Reconcile Disagreements

**Delegate to subagent.** Launch a subagent with a prompt that includes:
- "Read `research-validation/stages/reconcile-disagreements.md` for stage instructions"
- "Read `research-validation/contracts/reconciled-assessments.md` for the output schema"
- "Read the Agreement Report from `research-validation-workspace/agreement-report.md` — reconcile disputed claims only"
- "Use web search for additional evidence"
- "Write Reconciled Assessments to `research-validation-workspace/reconciled-assessments.md`"

**Precondition propagation**: The reconciliation subagent's prompt must include: "Use the WebSearch tool to find additional evidence for disputed claims. Before starting, perform a test web search to confirm access. If unavailable, report the failure and stop."

After the subagent completes, verify `research-validation-workspace/reconciled-assessments.md` exists.

#### Gate: Reconciliation Progress

**Metric check (stagnation detection — inline):**
- [ ] At least one `position_changed: true` across all revised assessments

**Identity check (inline):**
- [ ] `claim_id` and `text` fields match the Agreement Report's `disputed_claims`

**On stagnation** (no positions changed): Exit the reconciliation loop. Reclassify all remaining disputed claims as unresolvable with reason "reviewer positions unchanged after reconciliation round [N]". Proceed to Phase 6.

**On identity failure**: Re-launch the reconciliation subagent with feedback. Max 1 retry. After 1 retry, abort — identity drift in the feedback loop indicates a structural problem.

**On progress** (at least one position changed): Return to Phase 4 (Compare Assessments) with `round_number` incremented. The Compare stage will re-evaluate agreement using the revised positions.

### Phase 6: Compile Report

**Delegate to subagent.** Launch a subagent with a prompt that includes:
- "Read `research-validation/stages/compile-report.md` for stage instructions"
- "Read `research-validation/contracts/validation-report.md` for the output schema"
- "Assemble the final report from: Agreed claims (from `research-validation-workspace/agreement-report.md`), Reconciled claims (from `research-validation-workspace/reconciled-assessments.md`, if any), Unresolvable claims, Opinion claims (classify as `opinion_not_verified`)"
- "Write the Validation Report to `research-validation-workspace/validation-report.md`"

After the subagent completes, verify `research-validation-workspace/validation-report.md` exists.

#### Gate: Report Completeness

**Schema check** (inline):
- [ ] Report has valid structure — `summary` fields present, all enum values valid
- [ ] Every claim result has all required fields

**Metric check** (inline):
- [ ] `total_claims` equals the count of entries in `claim_results`
- [ ] The set of `claim_id`s in `claim_results` plus `unverifiable_claims` matches the original Claim List exactly
- [ ] Summary counts sum to `total_claims`: `verified_supported + verified_contradicted + insufficient_evidence + unverifiable + opinion_claims = total_claims`

**On failure**: Re-launch the compilation subagent with specific discrepancy details. Max 2 retries. After 2 retries, present the report as-is with a warning about potential incompleteness.

### Phase 7: Present Results

Present the completed Validation Report to the user. Include:
- The summary statistics table
- Any warnings from escalation (incomplete extraction, partial reviewer assessments, report completeness issues)
- The full report is available at `research-validation-workspace/validation-report.md`

## Pipeline Run Summary

After completion, report:
- **Stages executed**: which stages ran (including retries)
- **Gate results**: pass/fail for each gate, with details on any failures
- **Reconciliation rounds**: how many rounds the consensus loop ran, how many claims were disputed, how many resolved per round
- **Escalations**: any gates that hit their retry limit and proceeded with warnings
- **Final statistics**: from the Validation Report summary

## Guidance

- **Delegate every stage to a subagent.** Never execute stage transformations in the orchestrator's own context. Each stage subagent gets fresh context with only the stage file, contracts, and input artifact. The orchestrator retains only orchestration state — stage completion, gate results, loop counters — not stage working memory.
- **Gates are checkpoints, not bottlenecks.** Run gate checks immediately after each stage. Schema and metric checks are fast — do them inline in the orchestrator (reading the artifact file). **Semantic gates must run in a dedicated subagent** — not inline in the orchestrator or in the producing stage's subagent.
- **Propagate preconditions to subagents.** Any subagent that needs external resources (web search, MCP servers, APIs) must be explicitly told to use those tools in its prompt, with a re-validation step before starting work.
- **Track the reconciliation loop.** Report the round number, how many claims moved from disputed to agreed, and whether stagnation was detected.
- **Preserve the workspace.** Do not delete intermediate artifacts. They enable resumption and post-hoc diagnosis.
- **Report progress.** After each phase, briefly report what was produced and any gate results before proceeding to the next phase.
