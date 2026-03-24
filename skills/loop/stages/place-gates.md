# Stage: Place Gates

## Intent

Place validation checkpoints at artifact boundaries.

## Category & Posture

**Transform** — Convert representations. The input is stages + artifact specs; the output is gate specifications.

## Input

- **Artifact**: Transformation Definition — read from `loop-workspace/transformation.md`
  - Contract: Read `loop/contracts/transformation-definition.md`
- **Artifact**: Stage Decomposition — read from `loop-workspace/stages.md`
  - Contract: Read `loop/contracts/stage-decomposition.md`
- **Artifact**: Artifact Specifications — read from `loop-workspace/artifacts.md`
  - Contract: Read `loop/contracts/artifact-specifications.md`
- **Pipeline input**: Pipeline interaction level (`minimal` | `per-stage` | `none`) — the interaction level the *designed pipeline* will have at runtime
- **Pipeline input**: Workflow name (gates are workflow-scoped)

## Output

- **Artifact**: Gate Specifications
- **Write to**: `loop-workspace/workflows/<workflow>/gates.md`
- **Contract**: Read `loop/contracts/gate-specifications.md` for the output schema.

## Steps

1. For each artifact boundary in artifacts.md, decide whether a gate is needed:
   - **Gate needed**: The artifact has validation rules that can fail, the failure would cascade downstream, and the cost of a gate is less than the cost of late detection.
   - **No gate needed**: The boundary is low-risk (simple pass-through, or the next stage inherently validates its input), AND there's a downstream gate that catches the same issues. Document the rationale as an ungated boundary.
2. **Surface domain guidelines for this boundary.** If `transformation.md` includes a `domain_guidelines` section, extract every guideline relevant to the artifact being checked at this boundary. Present them as candidate validation criteria — reframed from the transformation perspective ("the pipeline must respect X") to the validation perspective ("check that the artifact satisfies X"). If no domain guidelines exist, or none apply to this boundary, note the absence — the gate will rely on structural checks and general LLM judgment only.
3. For each gate, determine the **type**:
   - **Schema**: Check structural presence of required fields/sections. Use when the artifact has explicit required fields.
   - **Metric**: Check quantitative thresholds (counts, percentages, word minimums). Use when quality can be measured numerically.
   - **Identity**: Verify specific fields haven't changed from upstream. Use at boundaries where drift is a risk.
   - **Semantic**: Run a separate LLM evaluation in clean context. Use when quality requires judgment (coherence, completeness, faithfulness to source). Specify the validation context — what the evaluator sees. When domain guidelines apply to this boundary, encode them as explicit criteria the evaluator must check — do not rely on the evaluator inferring domain rules from general knowledge.
   - **Consensus**: Run multiple independent evaluations, compare results. Use for high-stakes decisions.
   - **Human**: Pause and present to the user. Use where interaction level permits and the decision requires human judgment.
4. For each gate, design the **failure route**:
   - **routes_to**: Which stage should re-run on failure. Usually the producing stage.
   - **carries**: What feedback the re-running stage receives. Be specific — "which fields are missing" not "there were problems."
   - **max_retries**: How many times to retry. 1-3 is typical. Higher for cheap deterministic gates, lower for expensive semantic gates.
   - **escalation**: What happens after max retries exhausted. Options: present to user, skip with warning, abort pipeline.
5. Map **pipeline interaction levels to gate types**:
   - At `none`: All gates are automated (Schema, Metric, Identity, Semantic, Consensus). No Human gates.
   - At `minimal`: Human gates only for critical ambiguities. Most gates automated.
   - At `per-stage`: Human gates after every stage, in addition to automated gates.
6. **Assess human gate candidates** — For every artifact boundary, evaluate against six risk dimensions using signals from `transformation.md`, `stages.md`, and `artifacts.md`. This step runs regardless of pipeline interaction level — it *recommends*, it doesn't *place*. The disposition depends on the interaction level.

   | Dimension | Signal source | Trigger |
   |-----------|--------------|---------|
   | **Irreversible side effects** | Stage has sinks (Emit category) | Any external write that can't be undone (database mutations, sent messages, published artifacts) |
   | **Domain authority gap** | `transformation.md` gap analysis flags domain knowledge; `domain_guidelines` absent or does not cover this boundary | Pipeline lacks an authoritative source for domain validation — correctness depends on knowledge the LLM may not have. Stronger signal when `domain_guidelines` is absent entirely. |
   | **Subjective quality criteria** | `artifacts.md` validation uses subjective terms (e.g., "clear", "appropriate", "good") | Quality can't be reliably machine-evaluated — requires human taste or judgment |
   | **High fan-in convergence** | `stages.md` shows 3+ artifacts merging into one stage | Information loss at merge points — a human can catch whether the merge preserved what matters |
   | **Semantic gate stacking** | 3+ consecutive semantic gates without a deterministic anchor | Probabilistic confidence compounds — each semantic gate adds uncertainty, and without a hard checkpoint the pipeline may drift |
   | **Error reinforcement risk** | `transformation.md` complexity signals flag reinforcing loops without external correction | A reinforcing loop that lacks external input risks amplifying errors — human review breaks the echo chamber |

   For each boundary where one or more dimensions trigger, produce a `human_gate_candidates[]` entry (see the gate specifications contract for the schema). Set disposition based on pipeline interaction level:
   - At `none`: disposition = `documented` — record the candidate as an observation in the gate spec but do not place a Human gate.
   - At `minimal`: promote to a Human gate (or combined gate, e.g., Semantic + Human) if two or more dimensions trigger. For single-dimension triggers, disposition = `documented` unless the dimension is **Irreversible side effects**, which always promotes.
   - At `per-stage`: promote all candidates to Human gates.
7. For boundaries with combined gate types (e.g., Schema + Semantic), specify the order: run cheap deterministic checks first, expensive semantic checks only if deterministic checks pass.

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
- **Domain guidelines turn generic gates into domain-aware gates**: A semantic gate without domain guidelines can only check "does this look reasonable?" A semantic gate with domain guidelines checks "does this satisfy the rules the domain expert specified?" When domain guidelines exist, encode them verbatim as gate criteria — do not paraphrase or generalize, as the specificity is the value.
- **Mandatory human gates are workflow split points**: If a promoted Human gate fires on every run (not just as escalation after retries) and all paths from input to output pass through it, it is a cut vertex — the workflow is really two independent workflows joined by a human handoff. Consider splitting into two workflows where the first produces the artifact the human reviews, and the second declares the approved artifact as a precondition. See anti-pattern #9 (Toll Booth Pipeline).
