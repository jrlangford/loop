# Stage: Specify Artifacts

## Intent

Specify inter-stage data contracts.

## Category & Posture

**Transform** — Convert representations. Input and output are structurally different. The input is a stage list; the output is typed artifact contracts.

## Input

- **Artifact**: Stage Decomposition
- **Read from**: `loop-workspace/stages.md`
- **Contract**: Read `loop/contracts/stage-decomposition.md` for the input schema.

## Output

- **Artifact**: Artifact Specifications
- **Write to**: `loop-workspace/artifacts.md`
- **Contract**: Read `loop/contracts/artifact-specifications.md` for the output schema.

## Steps

1. Read the stage decomposition. For each pair of adjacent stages (and the pipeline input/output), define what crosses the boundary.
2. For each artifact, specify:
   - **Name**: Descriptive, unique across the pipeline.
   - **Boundary**: "[Stage A] → [Stage B]"
   - **Content**: What it carries (one sentence).
   - **Structure**: Fields, types, constraints. Be explicit — every field has a type and any enum values are listed.
   - **Identity fields**: Fields that must not mutate across downstream stages. These enable mechanical drift checking.
   - **Omitted**: What the upstream stage produced or could produce but this artifact deliberately excludes. Explicit omission prevents downstream stages from expecting data that won't be there.
   - **Validation**: How to check conformance — field presence, type checks, referential integrity rules.
   - **Reasoning trace**: None, Summary, or Full — with rationale for the choice.
3. Include pipeline input artifacts (what the pipeline receives from the user) and pipeline output artifacts (what the pipeline delivers).
4. Apply **handoff drift prevention** techniques:
   - **Enumerate, don't describe**: Use enums and closed vocabularies instead of free text where possible.
   - **Reference, don't paraphrase**: When downstream stages need upstream information, carry it as a reference (ID, name) rather than a re-stated summary.
   - **Separate observation from judgment**: If a stage both observes and evaluates, put observations and evaluations in separate fields.
5. Verify every stage boundary has an artifact. Verify no orphan artifacts (every artifact must be produced by one stage and consumed by at least one).

## Sources

None.

## Sinks

None.

## Guidance

- **Contracts are specifications, not documentation**: Every field must have a clear type and constraints. "A summary of the analysis" is not a field spec. "summary: string, max 200 words, covering key findings from each section" is.
- **Identity fields are the drift defense**: Choose fields whose mutation would indicate the pipeline has lost track of the original input. Typically: the task statement, stage names, artifact names — things that anchor cross-references.
- **Reasoning trace defaults to None**: Include reasoning traces only when downstream stages or the final consumer need to understand why, not just what. Summary for tradeoff decisions. Full only for review/audit outputs.
- **Don't carry forward unnecessary context**: Each artifact should carry exactly what the consuming stage needs — no more. Extraneous fields increase noise in the consumer's context window.
