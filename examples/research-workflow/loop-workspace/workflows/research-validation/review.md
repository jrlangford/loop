# Pipeline Design Review

## Summary
- **Files reviewed**: `transformation.md`, `stages.md`, `artifacts.md`, `context-specs.md`, `workflows/research-validation/gates.md`, `workflows/research-validation/loops.md`
- **Missing files**: `workflows/research-validation/preconditions.md`
- **Issues found**: 0 errors, 0 warnings, 3 info

## Issues

### INFO: Web search source dependency has no preconditions
- **Location**: `stages.md` (Stages 3, 5) / `workflows/research-validation/`
- **Anti-pattern**: None
- **Finding**: Verify Claims and Reconcile Disagreements both depend on web search as an external source. No preconditions are defined to validate web search availability before the pipeline runs. If web search is unavailable or rate-limited mid-pipeline, the failure occurs after Extract and Classify have already run — wasting those calls.
- **Suggested fix**: Define `preconditions.md` for this workflow with a web search availability check (required, not optional — the pipeline cannot function without it).
- **Skill to re-run**: Step 7 of `/loop:design` (preconditions)

### INFO: Stochastic validation not addressed in design
- **Location**: General (all artifacts)
- **Anti-pattern**: None
- **Finding**: The pipeline has multiple stochastic stages (Extract, Classify, Verify x3, Compare, Reconcile, Compile). The design does not discuss multi-run testing to characterize gate pass rates, loop iteration distributions, or output quality variance. A single test run cannot capture pipeline reliability.
- **Suggested fix**: When implementing, plan for multi-run testing — run the pipeline 5-10 times on the same input to characterize: extraction completeness rate, citation gate pass rate, average reconciliation rounds needed, and final report quality variance.
- **Skill to re-run**: None (implementation concern)

### INFO: Compare Assessments context width for large documents
- **Location**: `context-specs.md` (Stage: Compare Assessments)
- **Anti-pattern**: None
- **Finding**: The context spec already notes this: Compare Assessments receives 3 full reviewer assessments simultaneously. For documents with 30+ claims, each assessment could be substantial (evidence entries, reasoning per claim). The total context could approach limits. The spec suggests per-claim decomposition as a fallback but doesn't define a trigger threshold.
- **Suggested fix**: During implementation, monitor context usage for this stage. If it exceeds 75% of capacity on test documents, decompose Compare to process claims in batches rather than all-at-once.
- **Skill to re-run**: None (implementation concern)

## Anti-Pattern Audit

| Anti-Pattern | Status | Notes |
|-------------|--------|-------|
| Kitchen Sink Stage | **Pass** | All stage intents are single-verb. Verify Claims ("assess") is the broadest but web research is the method, not a separate transformation. |
| Echo Chamber Loop | **Pass** | No reinforcing loops. The consensus loop has echo chamber mitigation: varied search strategies, stagnation detection, web search for new evidence in reconciliation. |
| History Avalanche | **Pass** | No stage receives full pipeline history. Only Compare Assessments on rounds 2+ receives the previous Agreement Report — a single artifact, justified for tracking position changes. |
| Phantom Feedback Loop | **Pass** | All loops have specific, actionable criteria. Stagnation detector prevents cosmetic cycling. Gate criteria are concrete (schema checks, metric thresholds, identity verification). |
| Hardcoded Chain | **Pass** | Stages are independent units. No stage references a specific successor. Stages are reusable across workflows. |
| Ouroboros | **Pass** | The only circular flow (Compare ↔ Reconcile) is an intentional loop with termination (semantic: no disputes remaining; hard cap: 3 rounds; stagnation: no position changes). |
| Telephone Game | **Pass** | Strong drift mitigation: identity fields (`claim_id`, `text`) pass through every stage unchanged. Enums used for verdict, confidence, claim_type, agreement_status. Observation (evidence) and judgment (verdict, reasoning) separated into distinct fields throughout. |
| Fire-and-Forget Emit | **N/A** | No emit stages or sink dependencies. |

## Structural Audit

| Check | Status | Notes |
|-------|--------|-------|
| Artifact completeness | **Pass** | Every stage boundary has an artifact spec, including the loopback artifact (Reconciled Assessments → Compare Assessments). All artifact fields have identified downstream consumers. |
| Gate coverage | **Pass** | Critical boundaries gated: extraction completeness (semantic), citation accuracy (schema+metric), agreement routing (schema+metric), reconciliation progress (metric+identity), report completeness (schema+metric). Ungated boundary (Extract→Classify) justified — misclassification doesn't skip verification. |
| Completeness checking | **Pass** | Extraction Completeness gate uses source-artifact reconciliation (the most thorough option). Report Completeness gate checks claim count parity. Citation gate checks all cited claims have non-null `citation_valid`. |
| Loop safety | **Pass** | All 4 loops have semantic termination + hard caps. Caps are tight (1-3). Evaluator and refiner are separate stages with separate contexts in the consensus loop. Degradation detection via stagnation for the primary loop; not needed for 1-2 retry loops. |
| Context hygiene | **Pass** | Default "no history" policy honored. Only justified deviation: Compare Assessments on rounds 2+. No stage carries scaffolding from another stage. |
| Handoff drift resilience | **Pass** | Enums throughout. Identity fields declared and verified by identity gate. Semantic gates run in clean contexts. Source references (verbatim `text`, `location`) preserved at every stage. |
| Re-grounding | **Pass** | 6-stage pipeline with identity fields providing continuous re-grounding. The feedback loop narrows rather than expands. Compile stage works from consolidated final artifacts, not accumulated history. |

## Cost Estimate

### Workflow: research-validation

**Best case** (no disputes, all gates pass first try):

| Component | Calls |
|-----------|-------|
| Extract Claims | 1 |
| Extraction Completeness gate (semantic) | 1 |
| Classify Claims | 1 |
| Verify Claims (x3 parallel) | 3 |
| Compare Assessments | 1 |
| Compile Report | 1 |
| **Total** | **8** |

**Worst case** (all retries exhausted, 3 reconciliation rounds, stagnation on round 3):

| Component | Calls |
|-----------|-------|
| Extract Claims (1 + 2 retries) | 3 |
| Extraction Completeness gate (semantic, each attempt) | 3 |
| Classify Claims | 1 |
| Verify Claims (3 × (1 + 1 retry)) | 6 |
| Compare Assessments (3 rounds + 1 schema retry) | 4 |
| Reconcile Disagreements (3 rounds) | 3 |
| Compile Report (1 + 2 retries) | 3 |
| **Total** | **23** |

**Ratio**: 23/8 = 2.9× (under 3× threshold — acceptable)

**Typical case** (extraction passes on first try, 1 reviewer needs citation retry, 1 reconciliation round resolves most disputes):

| Component | Calls |
|-----------|-------|
| Extract Claims | 1 |
| Extraction Completeness gate | 1 |
| Classify Claims | 1 |
| Verify Claims (3 + 1 retry) | 4 |
| Compare Assessments (2 rounds) | 2 |
| Reconcile Disagreements (1 round) | 1 |
| Compile Report | 1 |
| **Total** | **11** |

## Pipeline Health

**This pipeline is ready to implement.** No errors or warnings. The design is clean:

- Well-decomposed stages with single-verb intents
- Strong drift mitigation through identity fields, enums, and separated observation/judgment
- Appropriate gate coverage at critical boundaries with completeness checking
- Tight loop bounds with stagnation detection on the primary consensus loop
- Clean context hygiene with justified history inclusion only where needed

The 3 INFO items are implementation concerns, not design flaws. The preconditions item (web search availability) should be addressed before production use but does not block the design.
