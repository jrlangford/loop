# Feedback Loop Specifications

## Loop: Survey Retry
- **Type**: Balancing
- **Stages involved**: Stage 2 (Survey Codebase) → Gate 1 (Structural Map Validity) → Stage 2
- **Purpose**: Correct parse failures in the structural map before boundary identification begins
- **Established pattern**: Evaluator-optimizer (simple retry variant — gate provides specific errors, stage re-runs with error context)
- **Termination**:
  - **Semantic**: All files in target scope parsed successfully with valid constructs, or ≥80% parsed (escalation threshold)
  - **Hard cap**: 2 iterations
- **Degradation detector**: Track count of successfully parsed files per iteration. If the count decreases between iterations (re-run broke previously working parses), fire immediately and use the iteration with the highest parse count.
- **Best-iteration selection**: Use iteration with highest file parse count. At cap 2, this is straightforward — compare both and take the better one.
- **Anti-pattern risks**: Low. This is a mechanical retry with deterministic gate criteria. Phantom feedback is unlikely since schema/metric gates have hard pass/fail.

---

## Loop: Boundary Retry
- **Type**: Balancing
- **Stages involved**: Stage 3 (Identify Boundaries) → Gate 2 (Boundary Quality) → Stage 3
- **Purpose**: Correct boundary identification gaps and false positives flagged by coverage reconciliation
- **Established pattern**: Evaluator-optimizer — semantic gate evaluates boundary quality and coverage, feeds specific corrections back to the identification stage
- **Termination**:
  - **Semantic**: Schema checks pass AND semantic spot-check finds no inaccurate summaries AND coverage reconciliation flags no major constructs with unexamined decision patterns
  - **Hard cap**: 2 iterations
- **Degradation detector**: Track two metrics across iterations:
  1. **Boundary count stability** — if the count swings by more than 30% between iterations (e.g., 15 → 25 → 12), the stage is over-correcting rather than converging. Fire on the second swing.
  2. **Issue count trend** — track the number of issues flagged by the semantic gate. If issue count does not decrease between iterations, the retry is not helping. Fire after one non-improving iteration.
- **Best-iteration selection**: Use the iteration with the lowest semantic gate issue count. If issue counts are equal, prefer the later iteration (it had corrective feedback).
- **Anti-pattern risks**:
  - **Phantom Feedback**: If the semantic gate's coverage reconciliation is too loose (only checking obvious patterns from signatures), it may pass boundaries that are actually misidentified. The spot-check of 3-5 boundaries provides a secondary signal.
  - **Over-correction**: Stage 3 re-running with "you missed these boundaries" feedback might add the flagged boundaries but drop others it previously found. The degradation detector's count stability check catches this.

---

## Loop: Document Retry
- **Type**: Balancing
- **Stages involved**: Stage 4 (Extract Behaviours, single boundary) → Gate 3 (Document Conformance) → Stage 4 (same boundary)
- **Purpose**: Correct structural or completeness failures in individual behaviour documents
- **Established pattern**: Evaluator-optimizer (per-document retry — scoped to a single boundary's extraction, not the full fan-out)
- **Termination**:
  - **Semantic**: Document passes all schema, metric, and identity checks — template conformance, at least one scenario, at least one code reference, identity fields match boundary location
  - **Hard cap**: 2 iterations
- **Degradation detector**: Track gate failure reasons across iterations. If the second iteration fails on *different* criteria than the first (fixing one problem introduced another), fire and use the iteration with fewer total failures.
- **Best-iteration selection**: Use iteration with fewer gate failures. If tied, prefer the iteration that passes the identity check (code reference accuracy is more important than structural completeness).
- **Anti-pattern risks**: Low. Schema/metric/identity gates are deterministic. Each retry is scoped to a single document, so failures are isolated — one document's retry cannot affect others.

---

## Loop: Deduplication Retry
- **Type**: Balancing
- **Stages involved**: Stage 5 (Deduplicate Behaviours) → Gate 4 (Deduplication Consistency) → Stage 5
- **Purpose**: Correct arithmetic inconsistencies or lost documents in the deduplication merge
- **Established pattern**: Evaluator-optimizer (simple retry — gate provides specific inconsistencies, stage re-merges)
- **Termination**:
  - **Semantic**: Count arithmetic is consistent, no documents lost, all traceability links preserved in merged documents
  - **Hard cap**: 1 iteration
- **Degradation detector**: Not applicable at cap 1 — only one retry attempt. If it fails, escalation skips deduplication entirely (pass-through unmerged set).
- **Best-iteration selection**: Not applicable — cap 1 means choose between the original attempt and the retry. If retry also fails, use the unmerged input set (escalation path from gate spec).
- **Anti-pattern risks**: Low. Schema gate is deterministic. Escalation is safe (unmerged set is valid, just potentially contains duplicates).

---

## Loop: Consistency Repair
- **Type**: Balancing
- **Stages involved**: Gate 5 (Post-Pipeline Consistency) → Stage 4 (Extract Behaviours, affected boundaries only) → Stage 5 (Deduplicate) → Gate 5
- **Purpose**: Correct stale or orphaned code references by re-extracting affected behaviours using the structural map as ground truth
- **Established pattern**: Evaluator-optimizer (cross-stage repair — gate after Stage 5 routes back to Stage 4 for specific boundaries, then output flows forward through Stage 5 again)
- **Termination**:
  - **Semantic**: No stale references (all code references match constructs in the structural map) and no orphaned behaviours (all referenced files exist in the map)
  - **Hard cap**: 1 iteration (this is a two-hop path: Stage 4 → Stage 5 → Gate 5, so even one iteration is relatively expensive)
- **Degradation detector**: Compare stale/orphaned reference count before and after the repair iteration. If count does not decrease, the re-extraction is producing the same bad references — stop and escalate.
- **Best-iteration selection**: Use the iteration with fewer stale/orphaned references. If the repair iteration is worse, use the original.
- **Anti-pattern risks**:
  - **Cross-stage routing**: Gate 5 fires after Stage 5 but routes to Stage 4. This is intentional — the problem is in extraction (Stage 4), not deduplication (Stage 5). But the re-extracted documents must flow through Stage 5 again, creating a two-hop retry. The cap of 1 keeps this bounded.
  - **Partial re-extraction**: Only affected boundaries are re-extracted, not the full set. The re-extracted documents replace their originals in the document set before Stage 5 re-runs. Stage 5 sees a mix of original and repaired documents — this is correct behaviour, not a consistency issue.

---

## Structural Pattern: Decompose-Aggregate (Stage 4)

Stage 4 implements a **decompose-aggregate** pattern, not a feedback loop, but worth documenting as a structural design element:

- **Decompose**: The Boundary List (from Stage 3) is split into individual boundary entries
- **Process**: Each boundary is extracted independently in a separate subagent context, producing one behaviour document. Boundaries can be processed in parallel since they share the same inputs (code files, reference index, template) but operate on independent code regions.
- **Aggregate**: Individual behaviour documents are collected into the Behaviour Document Set
- **Contradiction handling**: Not applicable — each boundary maps to a distinct code location, so independently extracted documents cannot contradict each other. Duplication (overlapping boundaries) is handled downstream by Stage 5.
- **Gate integration**: Gate 3 (Document Conformance) runs per-document within the fan-out. A failing document is retried independently without affecting other extractions.
