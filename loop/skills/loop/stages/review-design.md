# Stage: Review Design

## Intent

Evaluate design for anti-patterns and consistency.

## Category & Posture

**Evaluate** — Assess against criteria. Separate observation from judgment. Evidence required for every finding.

## Input

All workspace artifacts:
- `loop-workspace/transformation.md` — Transformation Definition
- `loop-workspace/stages.md` — Stage Decomposition
- `loop-workspace/artifacts.md` — Artifact Specifications
- `loop-workspace/context-specs.md` — Context Specifications
- `loop-workspace/workflows/<workflow>/gates.md` — Gate Specifications
- `loop-workspace/workflows/<workflow>/loops.md` — Loop Specifications

Contracts:
- Read `loop/contracts/review-results.md` for the output schema.

## Output

- **Artifact**: Review Results
- **Write to**: `loop-workspace/workflows/<workflow>/review.md` (per-workflow) or `loop-workspace/review.md` (cross-workflow)
- **Contract**: Read `loop/contracts/review-results.md` for the output schema.

## Steps

### 1. Anti-Pattern Check

Check for each of the eight anti-patterns:

| Anti-pattern | What to look for |
|-------------|-----------------|
| **Kitchen Sink Stage** | Stage intent has conjunctions, complexity notes exceed 3 sentences, or the stage's input→output transformation requires multiple distinct cognitive operations |
| **Echo Chamber Loop** | Reinforcing loop without novelty detection or diversity mechanism |
| **History Avalanche** | Any stage with history_policy other than "none" without strong justification; stages accumulating upstream reasoning traces |
| **Phantom Feedback Loop** | Gate criteria so loose that the gate effectively always passes; loop that never triggers correction |
| **Hardcoded Chain** | Stages that reference their successor by name; stages that embed assumptions about what comes next |
| **Ouroboros** | Circular dependencies where loop A triggers loop B which triggers loop A; re-grounding or review loops that can cascade infinitely |
| **Telephone Game** | Free-text fields carried across 3+ stages without re-grounding; paraphrased references instead of IDs; no identity fields at boundaries |
| **Fire-and-Forget Emit** | Emit stages without idempotency strategy, pre-write gate, or iteration caps on loops containing them |

### 2. Consistency Checks

**Referential integrity**:
- Every stage name in stages.md is referenced by at least one artifact boundary
- Every artifact name in artifacts.md is referenced by at least one gate or ungated boundary justification
- Every gate's `routes_to` stage exists in stages.md
- Every gate's `artifact_checked` exists in artifacts.md
- Every loop's `stages_involved` names exist in stages.md
- Every context spec's `stage` name exists in stages.md

**Completeness**:
- Every stage boundary has an artifact specification
- Every artifact boundary has a gate or ungated justification
- Every loop has semantic termination + hard cap
- Every stage has a context specification

**Implementability**:
- Output is directly consumable by `/loop:implement` — all required fields are present, all enums use valid values, all references resolve

### 3. Cost Estimate

Calculate best-case, typical, and worst-case inference call counts. Flag if worst/best ratio exceeds 3×.

### 4. Verdict

- **PASS**: No findings above INFO severity
- **PASS_WITH_WARNINGS**: WARNING findings exist but no ERRORs
- **FAIL**: At least one ERROR finding

Every finding must include: severity, location (artifact + section), description (what's wrong), and recommendation (what to fix and which phase to re-run).

## Sources

None.

## Sinks

None.

## Guidance

- **Assess independently**: Do not share context with any producing stage. The reviewer must evaluate the design on its own merits, not influenced by the reasoning that produced it.
- **Evidence required**: Every finding must cite the specific artifact and section where the issue exists. "The decomposition might have Kitchen Sink stages" is not a finding. "Stage 3 'Analyse and Classify Input' has a conjunction in its intent, suggesting two distinct operations" is.
- **Severity calibration**: ERROR = blocks implementation (broken references, missing required artifacts, anti-pattern that will cause pipeline failure). WARNING = degrades quality but doesn't block (loose gate criteria, suboptimal context budgets). INFO = observation worth noting (design choices that are valid but have tradeoffs).
- **Recommendations must be actionable**: Each finding's recommendation specifies which phase to re-run and what change to make. "Fix the decomposition" is not actionable. "Re-run `/loop:phase-decompose` — split Stage 3 into 'Analyse Input' and 'Classify Input'" is.
- **This is the most context-intensive stage**: All 6+ artifacts must be in context simultaneously. Structure the review as a checklist to manage cognitive load: anti-patterns first (cross-cutting), then consistency (per-artifact), then completeness (per-boundary).
