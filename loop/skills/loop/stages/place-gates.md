# Stage: Place Gates

## Intent

Place validation checkpoints at artifact boundaries.

## Category & Posture

**Transform** — Convert representations. The input is stages + artifact specs; the output is gate specifications.

## Input

- **Artifact**: Stage Decomposition — read from `loop-workspace/stages.md`
  - Contract: Read `loop/contracts/stage-decomposition.md`
- **Artifact**: Artifact Specifications — read from `loop-workspace/artifacts.md`
  - Contract: Read `loop/contracts/artifact-specifications.md`
- **Pipeline input**: Interaction level (`minimal` | `per-stage` | `none`)
- **Pipeline input**: Workflow name (gates are workflow-scoped)

## Output

- **Artifact**: Gate Specifications
- **Write to**: `loop-workspace/workflows/<workflow>/gates.md`
- **Contract**: Read `loop/contracts/gate-specifications.md` for the output schema.

## Steps

1. For each artifact boundary in artifacts.md, decide whether a gate is needed:
   - **Gate needed**: The artifact has validation rules that can fail, the failure would cascade downstream, and the cost of a gate is less than the cost of late detection.
   - **No gate needed**: The boundary is low-risk (simple pass-through, or the next stage inherently validates its input), AND there's a downstream gate that catches the same issues. Document the rationale as an ungated boundary.
2. For each gate, determine the **type**:
   - **Schema**: Check structural presence of required fields/sections. Use when the artifact has explicit required fields.
   - **Metric**: Check quantitative thresholds (counts, percentages, word minimums). Use when quality can be measured numerically.
   - **Identity**: Verify specific fields haven't changed from upstream. Use at boundaries where drift is a risk.
   - **Semantic**: Run a separate LLM evaluation in clean context. Use when quality requires judgment (coherence, completeness, faithfulness to source). Specify the validation context — what the evaluator sees.
   - **Consensus**: Run multiple independent evaluations, compare results. Use for high-stakes decisions.
   - **Human**: Pause and present to the user. Use where interaction level permits and the decision requires human judgment.
3. For each gate, design the **failure route**:
   - **routes_to**: Which stage should re-run on failure. Usually the producing stage.
   - **carries**: What feedback the re-running stage receives. Be specific — "which fields are missing" not "there were problems."
   - **max_retries**: How many times to retry. 1-3 is typical. Higher for cheap deterministic gates, lower for expensive semantic gates.
   - **escalation**: What happens after max retries exhausted. Options: present to user, skip with warning, abort pipeline.
4. Map **interaction levels to gate types**:
   - At `none`: All gates are automated (Schema, Metric, Identity, Semantic, Consensus). No Human gates.
   - At `minimal`: Human gates only for critical ambiguities. Most gates automated.
   - At `per-stage`: Human gates after every stage, in addition to automated gates.
5. For boundaries with combined gate types (e.g., Schema + Semantic), specify the order: run cheap deterministic checks first, expensive semantic checks only if deterministic checks pass.

## Sources

None.

## Sinks

None.

## Guidance

- **Gates are checkpoints, not bottlenecks**: A gate should catch real problems without false-positiving on normal LLM variance. Overly tight semantic criteria create loops that never terminate.
- **Distinguish deterministic from probabilistic failures**: Schema and Identity gates are deterministic — the output either has the field or doesn't. Semantic gates are probabilistic — different evaluators may disagree. Design criteria accordingly.
- **Semantic gates need clean context**: Specify that semantic evaluations run in a dedicated subagent with only the artifact, validation criteria, and relevant source material. Do not evaluate in the producing stage's context — the reasoning trace biases the evaluation.
- **Failure feedback must be actionable**: "Gate failed" is not actionable. "Missing field: identity_fields in artifact 'Stage Decomposition'. Expected: array of field names that must not mutate. Found: field absent." is actionable.
- **Silent omission is the hardest failure**: A stage that produces plausible but incomplete output won't fail schema checks. Design semantic gates to catch omissions — compare against the source's scope, not just the output's structure.
