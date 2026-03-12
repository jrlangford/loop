# Stage Decomposition

## Pipeline Overview
Validate research claims in markdown documents through parallel independent review, agreement comparison, and iterative reconciliation to produce a scored validation report.
Total stages: 6

## Stages

### Stage 1: Extract Claims
- **Category**: Extract
- **Intent**: Identify individual claims and their associated citations from the source document
- **Input**: Raw markdown document
- **Output**: Structured list of claims (text, location in document, associated citations if any)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Critical correctness — missing a claim is a silent failure. Must ensure completeness.

### Stage 2: Classify Claims
- **Category**: Evaluate
- **Intent**: Categorize each claim as factual, analytical, or opinion
- **Input**: Structured claim list from Stage 1
- **Output**: Typed claim list (each claim tagged with type and classification rationale)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Best-effort — edge cases between opinion and fact are genuinely ambiguous. Classification determines downstream validation approach.

### Stage 3: Verify Claims (x3 parallel)
- **Category**: Enrich
- **Intent**: Research and assess each claim's accuracy independently
- **Input**: Typed claim list from Stage 2
- **Output**: Per-reviewer assessment (evidence found, citation check result, confidence judgment per claim)
- **Sources**: Web search (citation verification and factual research)
- **Sinks**: None
- **Complexity**: Parallel fan-out — 3 independent instances of the same stage. Echo chamber risk: agents using similar search queries may converge on the same incorrect information. Citation accuracy is critical correctness (binary check). Web source availability may vary between reviewers.

### Stage 4: Compare Assessments
- **Category**: Evaluate
- **Intent**: Identify agreement and disagreement across reviewer assessments
- **Input**: 3 reviewer assessment artifacts from Stage 3
- **Output**: Agreement report (per-claim: agreed/disagreed, points of divergence, claims needing re-review)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must handle partial agreement (e.g., 2 of 3 agree). Agreement threshold determines which claims enter the reconciliation loop.

### Stage 5: Reconcile Disagreements
- **Category**: Refine
- **Intent**: Re-examine disputed claims with knowledge of other reviewers' findings
- **Input**: Agreement report from Stage 4 + original reviewer assessments
- **Output**: Updated assessments for disputed claims (revised judgment with reasoning)
- **Sources**: Web search (additional research on disputed claims)
- **Sinks**: None
- **Complexity**: Feedback loop target — runs up to 3 rounds. After 3 rounds without agreement, remaining disputes are marked unverifiable. Must avoid reinforcing errors across rounds (balancing loop needed). Feeds back into Stage 4 for re-comparison.

### Stage 6: Compile Report
- **Category**: Synthesise
- **Intent**: Assemble the final validation report from all assessments
- **Input**: Final assessments (agreed claims from Stage 4 + reconciled claims from Stage 5 + unverifiable verdicts)
- **Output**: Structured validation report with per-claim entries, confidence scores, and summary statistics
- **Sources**: None
- **Sinks**: None
- **Complexity**: None identified. Pure assembly — no judgment calls, just formatting and aggregation.
