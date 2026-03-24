# Contract: Transformation Definition

**Boundary**: Define Transformation → Decompose Stages
**Workspace path**: `loop-workspace/transformation.md`

## Content

Problem definition — what the pipeline does, what it receives, what it produces, what's hard about the transformation, and early complexity signals.

## Structure

| Field | Type | Description |
|-------|------|-------------|
| `task` | string | One-sentence pipeline description |
| `input_spec` | structured | Format, structure, variability, volume, quality issues |
| `output_spec` | structured | Format, structure, quality criteria, consumer |
| `gap_analysis` | structured | Hard parts, where single-pass fails, domain knowledge needed, critical-correctness vs. best-effort areas |
| `domain_guidelines` | structured (optional) | Domain-specific quality standards, acceptance criteria, validation rules, or terminology definitions that downstream gates should enforce. Omit only when the transformation requires no domain-specific validation beyond what the LLM can infer from general knowledge. |
| `complexity_signals` | structured | Flags for parallelization, refinement, external sources, external sinks, notification needs, error reinforcement risk |

## Identity Fields

- `task` — the one-sentence description anchors the entire design

## Omitted

Implementation details, stage suggestions, architecture decisions — those are downstream concerns.

## Validation

- `task` is a single sentence
- `input_spec` and `output_spec` are both present and non-empty
- `gap_analysis` identifies at least one difficulty
- If `domain_guidelines` is present, each entry specifies what it governs (which aspect of quality or correctness) and how it can be checked (measurable threshold, reference document, or judgment criteria)
- If `domain_guidelines` is absent, `gap_analysis` states why domain-specific validation is unnecessary or notes that domain rules were unavailable
- `complexity_signals` is present

## Reasoning Trace

None — the artifact is the user's intent, not the result of inference.
