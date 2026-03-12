# Pipeline Design Review

## Summary
- **Files reviewed**: `transformation.md`, `stages.md`, `artifacts.md`, `context-specs.md`, `workflows/autodoc/gates.md`, `workflows/autodoc/loops.md`
- **Missing files**: `workflows/autodoc/preconditions.md` (optional — see INFO finding below)
- **Issues found**: 0 ERROR, 1 WARNING, 3 INFO

## Issues

### WARNING: Worst-case cost ratio exceeds 3× threshold
- **Location**: Workflow-wide (gates.md, loops.md)
- **Anti-pattern**: None (structural concern)
- **Finding**: Best-case inference calls: ~36. Worst-case inference calls: ~135. Ratio: 3.75×, above the 3× flag threshold. The driver is Stage 4 fan-out retries — if all ~30 boundary extractions hit the 2-retry cap, that's 90 calls vs. 30. Additionally, the Consistency Repair loop can re-extract up to 30 boundaries and re-run Stage 5, adding another ~31 calls.
- **Suggested fix**: This is acceptable in practice — Stage 4 produces template-guided documents with deterministic gate criteria, so most documents should pass Gate 3 on the first attempt. The realistic worst case is closer to 45-50 calls (a few retries + no consistency repair). No design change needed, but implementers should monitor Gate 3 failure rates. If >30% of documents fail Gate 3 consistently, the Stage 4 scaffolding (template + extraction guidance) needs improvement.
- **Skill to re-run**: None

---

### INFO: No preconditions file defined
- **Location**: `workflows/autodoc/` (missing `preconditions.md`)
- **Finding**: Stage 1 has source dependencies: local filesystem, URLs, and Notion MCP. Currently, Notion MCP availability is checked within Stage 1 execution (context-specs.md scaffolding). If the MCP is misconfigured, Stage 1 discovers this mid-execution and reports which references couldn't be loaded. The pipeline degrades gracefully — this is well-designed. However, a preconditions file would allow the orchestrator to validate Notion MCP connectivity, URL reachability, and file existence before Stage 1 runs, providing faster failure.
- **Suggested fix**: Optional. The graceful degradation in Stage 1 is sufficient for a pipeline with no required external dependencies. Consider adding preconditions if the pipeline is automated (no human watching Stage 1 output) and Notion references are frequently used.
- **Skill to re-run**: `/loop-wf-design` Step 7

---

### INFO: Boundary Quality gate coverage reconciliation is signature-based
- **Location**: `workflows/autodoc/gates.md` — Gate: Boundary Quality, semantic criteria
- **Finding**: The coverage reconciliation check compares the Boundary List against the Structural Map to find missed boundaries. However, the Structural Map carries signatures and call relationships but not code bodies. The gate infers "this construct probably has a decision boundary" from names and signatures (e.g., a method named `HandleRetry` or a function returning `(result, error)`). Constructs with generic signatures (e.g., `Process(ctx)`) that contain significant decision logic internally would be missed by this heuristic. This is a known trade-off — including code bodies in the gate context would significantly increase its cost.
- **Suggested fix**: Acceptable as-is. The exclusion validation (spot-checking 2-3 excluded constructs by re-reading their source) provides a secondary check. The post-pipeline coverage gap report gives the user a final opportunity to identify misses. Document this limitation in implementation notes.
- **Skill to re-run**: None

---

### INFO: Multi-run pipeline reliability not addressed
- **Location**: Design-wide
- **Finding**: LLM stages are stochastic — the same input produces different outputs across runs. The design does not address how to characterize pipeline reliability (gate pass rates, loop iteration distributions, output quality variance across runs). A single test run cannot confirm the pipeline is reliable.
- **Suggested fix**: During implementation testing, run the pipeline 3-5 times against the same codebase and measure: (1) Gate 3 first-pass rate, (2) Boundary count variance across runs, (3) Behaviour document quality consistency. If Gate 3 first-pass rate is <70% or boundary count variance >20%, revisit Stage 4 scaffolding or Stage 3 heuristics respectively.
- **Skill to re-run**: None (implementation concern)

## Anti-Pattern Audit

| Anti-pattern | Status | Notes |
|-------------|--------|-------|
| Kitchen Sink Stage | **Pass** | All stages pass one-verb heuristic. Stage 4 lists 8 sub-steps but these all serve "produce one behaviour document" — the fan-out keeps each invocation focused. |
| Echo Chamber Loop | **Pass** | No reinforcing loops in the design. All 5 loops are balancing (gate-retry). |
| History Avalanche | **Pass** | Context specs explicitly specify no history at every stage. Isolation model requires fresh subagent contexts. |
| Phantom Feedback Loop | **Pass** | All gates have specific, actionable criteria. Semantic gates include spot-checks and reconciliation. Deterministic gates (schema/metric/identity) have hard pass/fail. |
| Hardcoded Chain | **Pass** | Stages reference inputs and outputs, not specific successor stages. Stages are composable — could be reused in a different workflow. |
| Ouroboros | **Pass** | The Consistency Repair loop (Gate 5 → Stage 4 → Stage 5 → Gate 5) is a declared loop with termination (cap 1), not an unintentional circular dependency. |
| Telephone Game | **Pass** | Boundary type uses closed enum. Evidence is verbatim code. Identity fields declared and checked at every boundary. Post-pipeline consistency gate re-grounds against the structural map. `reference_hints` carry source locators, not paraphrases. |
| Fire-and-Forget Emit | **N/A** | No emit stages — pipeline output is local markdown files only. |

## Structural Audit

| Check | Status | Notes |
|-------|--------|-------|
| Artifact completeness | **Pass** | Every stage boundary has an artifact spec. Every artifact field has a named consumer. |
| Gate coverage | **Pass** | High-uncertainty stage (Stage 3) has semantic gate with coverage reconciliation. All gates have failure routes, max retries, and escalation. |
| Sink safety | **N/A** | No sinks. |
| Context isolation | **Pass** | Explicitly specified: stages in subagent contexts, semantic gates in dedicated clean contexts. |
| Loop safety | **Pass** | All loops have semantic termination + hard cap. All applicable loops have degradation detectors. Caps ≤2. Best-iteration selection specified. Evaluator/refiner separation via clean gate contexts. |
| Context hygiene | **Pass** | No-history default honored everywhere. No cross-stage scaffolding contamination. |
| Handoff drift resilience | **Pass** | Closed enum for boundary types. Verbatim evidence. Identity fields with identity gates. Post-pipeline re-grounding. Semantic gates in clean contexts. |

## Cost Estimate

### Workflow: autodoc

| Scenario | Inference Calls | Notes |
|----------|----------------|-------|
| **Best case** | ~36 | All gates pass first try. Stage 4 fan-out: ~30 calls. |
| **Realistic case** | ~45 | A few Stage 4 retries, no consistency repair. |
| **Worst case** | ~135 | All retries fire, full consistency repair. |
| **Ratio** | 3.75× | Above 3× threshold — driven by Stage 4 fan-out retries (see WARNING). |

Gate cost breakdown:
- Schema/Metric/Identity gates: 0 inference calls (deterministic)
- Boundary Quality semantic: 1 call per evaluation
- Post-Pipeline Consistency semantic: 1 call per evaluation

## Pipeline Health

**Ready to implement.** No errors. The design is clean — well-isolated stages, appropriate gate coverage, bounded loops with degradation detection, and a post-pipeline re-grounding check that closes the loop between output and structural truth. The one warning (cost ratio) is driven by the fan-out structure and is acceptable in practice given the deterministic nature of Gate 3.

The three INFO findings are implementation concerns, not design flaws:
- Preconditions are optional given the graceful degradation design
- Signature-based coverage reconciliation is a documented trade-off
- Multi-run reliability testing is standard implementation practice

Artifact inventory:
- Stage-level: `transformation.md`, `stages.md`, `artifacts.md`, `context-specs.md`
- Workflow-level: `workflows/autodoc/gates.md`, `workflows/autodoc/loops.md`
- Review: `workflows/autodoc/review.md`
