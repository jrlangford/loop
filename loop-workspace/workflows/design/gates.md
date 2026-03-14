# Gate Specifications — Design Workflow

## Gate: Transformation Completeness (after Define Transformation)
- **Position**: Between Define Transformation and Decompose Stages
- **Artifact checked**: Transformation Definition
- **Type**: Schema + Human (conditional)
- **Criteria**:
  - Schema: `task` is a single sentence. `input_spec` and `output_spec` are both present and non-empty. `gap_analysis` identifies at least one difficulty. `complexity_signals` is present.
  - Semantic (at `none` interaction level only): The gap analysis identifies at least one specific difficulty (not generic statements like "it's hard"). The input and output specs are concrete enough to distinguish this pipeline from a different one. Minimum specificity: gap_analysis contains at least 50 words, input_spec describes format and variability, output_spec includes quality criteria.
  - Human (at `minimal` or `per-stage`): Present the transformation definition for user review when: the task description was vague (fewer than 2 sentences of input), the gap analysis flags uncertainty about whether staging is warranted, or complexity signals are ambiguous.
- **On failure**:
  - **Routes to**: Define Transformation
  - **Carries**: Which required sections are missing or incomplete. For human gate failures: the user's specific feedback on what needs clarification.
  - **Max retries**: 2
  - **Escalation**: Present the transformation definition as-is and warn that downstream quality may suffer from an underspecified foundation. At interaction level `none`, abort — an incomplete transformation definition cannot produce a reliable design.

## Gate: Decomposition Validity (after Decompose Stages)
- **Position**: Between Decompose Stages and Specify Artifacts
- **Artifact checked**: Stage Decomposition
- **Type**: Schema + Metric + Semantic
- **Criteria**:
  - Schema: Every stage has `name`, `category`, `intent`, `input`, `output`. Category is from the enum (Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit). No two stages share the same name. Stage count matches overview.
  - Metric: Stage count is between 2 and 15 (fewer than 2 suggests no decomposition occurred; more than 15 suggests over-decomposition). Every stage intent is a single verb phrase — no conjunctions ("and", "then", "plus"), no semicolons.
  - Semantic: Each stage does one bounded thing (Kitchen Sink check). Stage ordering follows the principles (narrow before wide, fail-fast, cheap before expensive, emit last). The decomposition covers the full gap analysis from transformation.md — no difficulties left unaddressed.
- **Validation context**: Semantic check runs in a clean subagent with only stages.md, the Kitchen Sink criteria, ordering principles, and the gap analysis section from transformation.md. Does NOT see the producing stage's decomposition rationale or context specs.
- **On failure**:
  - **Routes to**: Decompose Stages
  - **Carries**: Schema failures: which fields are missing or invalid. Metric failures: which stages violate the one-verb heuristic (with the offending intent quoted), or stage count issue. Semantic failures: which stages are Kitchen Sinks (with explanation), which gaps from transformation.md are unaddressed.
  - **Max retries**: 2
  - **Escalation**: Present the decomposition with warnings. If Kitchen Sink stages remain after retries, flag them as high-risk for downstream quality issues.

## Gate: Contract Integrity (after Specify Artifacts)
- **Position**: Between Specify Artifacts and Budget Context / Place Gates
- **Artifact checked**: Artifact Specifications
- **Type**: Schema + Identity
- **Criteria**:
  - Schema: Every stage boundary in stages.md has a corresponding artifact. Every artifact has `name`, `content`, `structure`, `validation`, `reasoning_trace`. No orphan artifacts (every artifact is produced by one stage and consumed by at least one). Artifacts consumed by Emit stages include idempotency markers.
  - Identity: Stage names referenced in artifact boundaries match exactly with stages.md. Artifact names are unique.
- **On failure**:
  - **Routes to**: Specify Artifacts
  - **Carries**: Schema failures: which boundaries lack artifacts, which artifacts are missing required fields, which artifacts are orphaned. Identity failures: which stage name references don't match stages.md (with expected vs. actual).
  - **Max retries**: 2
  - **Escalation**: Abort — artifact specifications with broken referential integrity will produce invalid gates and loops. The design cannot proceed.

## Gate: Re-grounding (after Specify Artifacts)
- **Position**: After Contract Integrity gate, before Budget Context / Place Gates
- **Artifact checked**: Artifact Specifications (compared against Transformation Definition)
- **Type**: Semantic
- **Criteria**: The artifact chain from pipeline input to pipeline output, as defined by the artifact specifications, faithfully represents the transformation described in transformation.md. Specifically:
  - The pipeline input artifact matches the input specification from transformation.md
  - The pipeline output artifact meets the quality criteria from transformation.md
  - The difficulties identified in gap analysis are addressed by the stage boundaries (each difficulty maps to at least one stage boundary where it's handled)
  - No stages or artifacts have been introduced that serve purposes outside the original transformation scope (scope creep)
- **Validation context**: Clean subagent with only transformation.md, the artifact chain summary (pipeline input → artifact 1 → artifact 2 → ... → pipeline output), and the re-grounding criteria. Does NOT see stages.md complexity notes or context specs.
- **On failure**:
  - **Routes to**: Decompose Stages (if drift is structural — wrong stages) or Specify Artifacts (if drift is in contracts — right stages, wrong boundaries)
  - **Carries**: Where divergence was detected — which aspects of the transformation are no longer faithfully represented, and whether the issue is structural (stage-level) or contractual (artifact-level).
  - **Max retries**: 1
  - **Escalation**: Present the divergence to the user with both the original transformation definition and the current artifact chain. The user decides whether to accept the drift (update transformation.md) or correct it (re-run the flagged stage).

## Gate: Gate Referential Integrity (after Place Gates)
- **Position**: Between Place Gates and Design Feedback
- **Artifact checked**: Gate Specifications
- **Type**: Schema + Identity
- **Criteria**:
  - Schema: Every gate has `name`, `position`, `artifact_checked`, `type`, `criteria`, `on_failure` (with `routes_to`, `carries`, `max_retries`, `escalation`). Gate type is from the enum. Max retries > 0. Escalation is non-empty. Every artifact boundary has either a gate or an ungated boundary with rationale.
  - Identity: Every `artifact_checked` matches an artifact name in artifacts.md. Every `routes_to` matches a stage name in stages.md. Gate positions reference stages that exist.
- **On failure**:
  - **Routes to**: Place Gates
  - **Carries**: Schema failures: which gates are missing required fields, which have invalid types. Identity failures: which references don't match (artifact names, stage names) with expected vs. actual.
  - **Max retries**: 2
  - **Escalation**: Abort — gate specifications with broken references will produce feedback loops that route to nonexistent stages.

## Ungated Boundaries

### Budget Context → Review Design
- **Rationale**: Context specifications inform the orchestrator's execution strategy but don't structurally cascade into other design artifacts. A suboptimal context budget degrades runtime quality but doesn't break referential integrity. Review Design (Stage 7) evaluates context specs as part of its comprehensive check — adding a gate here would duplicate that work.

### Design Feedback → Review Design
- **Rationale**: Loop specifications flow directly into Review Design, which is specifically designed to catch loop anti-patterns (Echo Chamber, Phantom Feedback, Ouroboros). A gate here would be redundant with the review stage's core purpose. If loops have referential integrity issues (nonexistent stages, missing termination), Review will catch them.
