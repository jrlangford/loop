# Context Specifications

## Stage: Extract Claims

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Source Document (raw markdown) |
| System prompt | Yes | Role: claim extraction specialist. Extract every verifiable claim and its citations. Do not evaluate, classify, or judge — only identify and extract. |
| Examples | Yes | 2-3 examples showing: a sentence that is a claim vs. one that isn't; how to handle compound claims (split them); how to identify implicit claims |
| Domain reference | No | — |
| Upstream history | No | — |
| Reasoning trace | No | — |

### Channel Assessment
- **Signal**: The source document + extraction instructions + examples. Compact channel — the document is the payload, instructions are brief.
- **Noise**: Deliberately excluded: any evaluation criteria, classification rules, or validation logic. The extractor should not be primed to think about whether claims are true.
- **Information rate**: Within single-inference capacity. Extraction from an article-length document is well within one pass. The output (structured claim list) is shorter than the input.

## Stage: Classify Claims

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Claim List (structured claims from Extract) |
| System prompt | Yes | Role: claim classifier. Assign each claim a type: factual, analytical, or opinion. Provide brief rationale. |
| Examples | Yes | 3-4 examples showing edge cases: factual vs. analytical (data point vs. interpretation), analytical vs. opinion (evidence-based reasoning vs. value judgment), hedged claims ("suggests that...") |
| Domain reference | No | — |
| Upstream history | No | — |
| Reasoning trace | No | Extraction has no reasoning trace |

### Channel Assessment
- **Signal**: Structured claim list + classification rules + edge case examples. Clean channel — input is already structured, task is well-bounded.
- **Noise**: Excluded: source document (classification operates on extracted claim text, not surrounding prose), citations (not relevant to type classification).
- **Information rate**: Low. Each claim is classified independently. Even with 50+ claims, this is straightforward single-inference work.

## Stage: Verify Claims (x3 parallel instances)

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Typed Claim List (claims with type classifications) |
| System prompt | Yes | Role: independent research reviewer. For each claim: (1) check citation accuracy if cited, (2) search for supporting/contradicting evidence, (3) render a verdict with confidence. Work independently — do not assume other reviewers exist. |
| Examples | Yes | 1-2 examples showing: how to structure evidence entries, how to assess citation validity, what "insufficient_evidence" vs. "unverifiable" means |
| Domain reference | No | — |
| Upstream history | No | — |
| Reasoning trace | Summary | `classification_rationale` from Typed Claim List — reviewers may adjust approach based on claim type rationale |

### Channel Assessment
- **Signal**: Claims to verify + verification instructions + web search results (injected during execution as tool use). The claim list is the static payload; web results are dynamic signal.
- **Noise**: Excluded: source document (the claim `text` field carries the verbatim quote — sufficient for verification without the full document). Excluded: other reviewers' work (independence is critical).
- **Information rate**: Moderate-to-high. Each claim requires web research, evidence assessment, and judgment. For documents with many claims, this stage does significant work — but the parallelisation across 3 instances distributes the load. Each instance handles the full claim list, which is manageable for article-length documents.
- **Long generation note**: This stage produces the longest output (per-claim assessments with evidence). For documents with 30+ claims, the output may be substantial. The structured output format (fields per claim) helps maintain consistency across a long generation.

### Echo Chamber Mitigation
Each reviewer instance should use varied search strategies. The system prompt should instruct reviewers to:
- Use different search query formulations
- Consult different source types where possible
- Not rely on a single source for any verdict

This is guidance, not enforcement — the agreement gate downstream is the structural mitigation.

## Stage: Compare Assessments

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | 3 Reviewer Assessment artifacts (all three, merged into context) |
| System prompt | Yes | Role: assessment comparator. For each claim, determine if reviewers agree (unanimous/majority) or disagree (split). For disagreements, summarise positions and identify the specific point of divergence. |
| Examples | No | The task is clear from the artifact structure |
| Domain reference | No | — |
| Upstream history | Partial | On rounds 2+: the previous Agreement Report (to populate `previous_disagreement_points` and `position_changed`). On round 1: none. |
| Reasoning trace | Summary | Reviewer `reasoning` fields — needed to understand *why* positions differ |

### Channel Assessment
- **Signal**: Three reviewer assessments side by side + comparison instructions. On round 2+, the previous Agreement Report adds context about what changed.
- **Noise**: Excluded: source document, typed claim list (claim identity fields in assessments are sufficient). On rounds 2+, only the previous round's Agreement Report — not all prior rounds.
- **Information rate**: Moderate. This stage reads 3x the data of a single assessment but produces a compressed output (agreement/disagreement per claim). The comparison is mechanical for agreed claims; judgment is needed only for characterising disagreements.
- **Context size note**: With 3 full reviewer assessments, this is the widest context in the pipeline. For documents with many claims, the three assessments together could be substantial. However, the structured format enables efficient comparison — the model can process claim-by-claim rather than needing holistic understanding.

## Stage: Reconcile Disagreements

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Agreement Report (`disputed_claims` section only — agreed claims are excluded) |
| System prompt | Yes | Role: dispute resolver. Re-examine each disputed claim with knowledge of all reviewers' positions. Search for additional evidence. Either revise your position with rationale, or maintain it with explanation. On round 3: mark remaining disputes as unverifiable. |
| Examples | No | — |
| Domain reference | No | — |
| Upstream history | No | The Agreement Report's `reviewer_positions` and `previous_disagreement_points` carry all needed context from prior rounds |
| Reasoning trace | Summary | `reasoning_summary` from reviewer positions in the Agreement Report |

### Channel Assessment
- **Signal**: Only the disputed claims + reviewer positions + reconciliation instructions. This is a deliberately narrow channel — agreed claims are excluded entirely.
- **Noise**: Excluded: agreed claims (no action needed), full evidence lists from reviewers (condensed to `key_evidence` in the Agreement Report), source document.
- **Information rate**: Low-to-moderate. The dispute set shrinks each round (as claims reach agreement). By round 3, only the most genuinely ambiguous claims remain. This natural narrowing keeps the channel efficient across iterations.

## Stage: Compile Report

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Final Agreement Report (agreed claims) + final Reconciled Assessments (reconciled + unverifiable claims) |
| System prompt | Yes | Role: report assembler. Compile all claim results into the structured validation report format. Calculate summary statistics. No new judgments — pure assembly. |
| Examples | Yes | 1 example showing the expected output format (report structure) |
| Domain reference | No | — |
| Upstream history | No | — |
| Reasoning trace | No | Not needed for assembly |

### Channel Assessment
- **Signal**: The final state of all claims (agreed, reconciled, unverifiable) + report format template.
- **Noise**: Excluded: intermediate round data (only final results), raw reviewer assessments (already consolidated), source document (claim `text` and `location` fields carry what's needed for the report).
- **Information rate**: Low. This is mechanical assembly and formatting. The input is already structured; the output is a reformatting with summary statistics added.

## Cross-Pipeline Notes

### History discipline
No stage receives full pipeline history. The only non-default history inclusion is Compare Assessments on rounds 2+, which receives the *previous round's* Agreement Report — a single artifact, not accumulated history. This is justified because the Compare stage must track whether positions changed across rounds.

### Re-grounding check
This is a 6-stage pipeline with a feedback loop. Cumulative drift risk is mitigated by:
- Identity fields (`claim_id`, `text`) passing through unchanged at every stage — the original claim text is always present for reference
- The Compile stage works from final consolidated artifacts, not from a chain of transformations
- The feedback loop (Compare ↔ Reconcile) narrows rather than expands — fewer claims each round, not more context

### Widest context window
Stage 4 (Compare Assessments) has the widest context: 3 full reviewer assessments simultaneously. For very long documents with many claims, this could approach context limits. If this becomes an issue, the stage could be decomposed to compare claim-by-claim rather than all-at-once, but for article-length documents this should be well within capacity.
