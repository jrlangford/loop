# Stage: Define Transformation

## Intent

Define the pipeline's transformation from task description.

## Category & Posture

**Transform** — Convert representations. Input and output are structurally different. The input is free-form natural language; the output is a structured problem definition.

## Input

- **Pipeline input**: Natural language task description (free text — one sentence to multiple paragraphs)
- **Pipeline input**: Interaction level (`minimal` | `per-stage` | `none`)

No upstream artifacts — this is the first stage.

## Output

- **Artifact**: Transformation Definition
- **Write to**: `loop-workspace/transformation.md`
- **Contract**: Read `loop/contracts/transformation-definition.md` for the output schema.

## Steps

1. Read the task description carefully. Identify what the pipeline should do, not how.
2. Write the `task` field as a single sentence capturing the core transformation.
3. Elicit the **input specification**: What does this pipeline receive? What format? How variable? What quality issues might the input have?
4. Elicit the **output specification**: What does this pipeline produce? What format? What quality criteria define success? Who consumes the output?
5. Perform **gap analysis**: What makes this transformation hard? Where would a single LLM call fail? What domain knowledge is needed? Which parts are critical-correctness vs. best-effort?
6. Elicit **domain guidelines**: Does the user have domain-specific quality standards, acceptance criteria, validation rules, or terminology definitions that should govern pipeline correctness? Examples: "a valid citation must link to a peer-reviewed source", "severity must use the CVSS scale", "all monetary values in USD". These are rules the pipeline must respect that an LLM cannot reliably infer from general knowledge. If the user provides guidelines, record each with what it governs and how it can be checked. If the user has none, note this in the gap analysis — the absence is itself a signal for downstream gate placement.
7. Identify **complexity signals**: Does the pipeline need parallelization? Iterative refinement? External sources or sinks? Are there error reinforcement risks?
8. Challenge vague answers. If the task description is underspecified, flag specific ambiguities rather than inventing details. At `minimal` or `per-stage` interaction, ask the user to clarify. At `none`, note the ambiguity in the gap analysis.

## Sources

None.

## Sinks

None.

## Guidance

- **Focus on the "what", not the "how"**: Do not suggest stages, architecture, or implementation details. Those are downstream concerns.
- **Distinguish staging need from single-call tasks**: If the task description is simple enough for a single well-prompted LLM call (no multi-step reasoning, no external data, no quality iteration needed), say so in the gap analysis. Not every task needs a pipeline.
- **Elicit, don't assume**: When the task description is vague, identify what's missing. "Summarize documents" → what kind of documents? What length? What audience? What counts as a good summary?
- **Complexity signals are flags, not decisions**: Note whether external sources, sinks, parallelization, etc. are likely needed. Don't design around them yet — that's for decomposition.
- **Be concrete in gap analysis**: "It's hard" is not a gap analysis. "The pipeline must handle 50-page technical documents where key information is distributed across non-adjacent sections, making single-pass extraction unreliable" is.
- **Domain guidelines are validation fuel**: The gap analysis identifies *what's hard*; domain guidelines specify *what "correct" means* in the user's context. A gate without domain guidelines can only check structure and generic plausibility. A gate with domain guidelines can check domain-specific correctness. When eliciting guidelines, prompt for the rules a domain expert would use to review the pipeline's output — not implementation preferences.
- **At `none` interaction level**: Work entirely from the task description. Make reasonable assumptions where needed, but flag each assumption explicitly in the gap analysis so the downstream stages can see where uncertainty lies.
