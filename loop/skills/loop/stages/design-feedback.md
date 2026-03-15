# Stage: Design Feedback

## Intent

Design feedback loops with termination conditions.

## Category & Posture

**Transform** — Convert representations. The input is stages + artifacts + gates; the output is loop specifications.

## Input

- **Artifact**: Stage Decomposition — read from `loop-workspace/stages.md`
  - Contract: Read `loop/contracts/stage-decomposition.md`
- **Artifact**: Artifact Specifications — read from `loop-workspace/artifacts.md`
  - Contract: Read `loop/contracts/artifact-specifications.md`
- **Artifact**: Gate Specifications — read from `loop-workspace/workflows/<workflow>/gates.md`
  - Contract: Read `loop/contracts/gate-specifications.md`
- **Pipeline input**: Workflow name (loops are workflow-scoped)

## Output

- **Artifact**: Loop Specifications
- **Write to**: `loop-workspace/workflows/<workflow>/loops.md`
- **Contract**: Read `loop/contracts/loop-specifications.md` for the output schema.

## Steps

1. Identify loop candidates from gate failure routes. Every gate with `routes_to` pointing to a stage that has already run is a potential loop. The gate failure route defines the loop path.
2. Classify each loop as **Reinforcing** or **Balancing**:
   - **Reinforcing**: Each iteration amplifies the previous output (e.g., expanding coverage, adding detail). Requires novelty detection to prevent Echo Chamber.
   - **Balancing**: Each iteration corrects toward a target (e.g., fixing validation failures, resolving inconsistencies). Converges naturally when criteria are met.
3. For each loop, specify **termination conditions**:
   - **Semantic termination**: What "done" means in terms of output quality. Tied to the gate criteria that trigger the loop.
   - **Hard cap**: Maximum iterations. Must always be present. 2-3 for balancing loops, 1-2 for expensive semantic loops. Never exceed 10 without explicit justification.
4. Design **degradation detectors** for each loop:
   - Track a measurable quality signal across iterations (violation count, completeness score, etc.).
   - Define what worsening looks like: "If violations increase or stay the same across two consecutive iterations."
   - When degradation is detected, stop the loop and use the best iteration.
5. Specify **best-iteration selection**: How to pick the best output when the loop is terminated by degradation or hard cap rather than semantic success. Usually: fewest violations, most complete, or most consistent with source.
6. Map each loop to an **established pattern**:
   - **Evaluator-optimizer**: Gate evaluates, stage optimizes. Most common for correction loops.
   - **Prompt chaining**: Output of one stage feeds the next in sequence.
   - **Parallelisation**: Multiple independent evaluations compared.
   - **Orchestrator-workers**: Central coordinator delegates to specialized workers.
7. Check for **anti-patterns**:
   - **Echo Chamber**: Reinforcing loop without novelty detection. Each iteration looks like the last.
   - **Phantom Feedback**: Loop that never triggers because gate criteria are too loose.
   - **Ouroboros**: Circular dependency where loop A triggers loop B which triggers loop A.

## Sources

None.

## Sinks

None.

## Guidance

- **Gate failure routes are the primary source of loops**: Don't invent loops that don't connect to gates. If there's no gate to trigger the loop, the loop has no activation signal.
- **Every loop must have both semantic and hard-cap termination**: Semantic termination defines success; hard cap prevents infinite cycling. Both are required — no exceptions.
- **Degradation detectors prevent runaway iteration**: Without degradation detection, a loop can worsen output with each iteration while staying under the hard cap. The detector is the safety net.
- **Balancing loops should converge**: If a balancing loop consistently hits its hard cap, either the gate criteria are too tight, the producing stage can't reliably meet the criteria, or the task needs restructuring. Design for convergence within 2-3 iterations.
- **Worst-case cost matters**: Calculate the maximum number of inference calls if all loops hit their hard caps. If the worst-case cost exceeds 3× the best-case cost, consider tightening caps or reducing loop nesting.
- **This is the highest fan-in stage**: Three input artifacts. Focus on the gate specifications — they contain the failure routes that define loops. Use stages.md for stage names and artifacts.md for boundary references.
