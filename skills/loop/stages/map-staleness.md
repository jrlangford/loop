# Stage: Map Staleness

## Intent

Trace impact of changes through the design's connection graph.

## Category & Posture

**Evaluate** — Assess against criteria. Separate observation from judgment. The observation is "what is connected to the change"; the judgment is "what is stale."

## Input

- **Pipeline input (edit workflow)**: Modification request — what the user wants to change
- **Pipeline input (edit workflow)**: Existing workspace — all current design artifacts
- **Modified artifact**: The changed file after the user's modification has been applied

All workspace artifacts:
- `loop-workspace/transformation.md`
- `loop-workspace/stages.md`
- `loop-workspace/artifacts.md`
- `loop-workspace/context-specs.md`
- `loop-workspace/workflows/<workflow>/gates.md`
- `loop-workspace/workflows/<workflow>/loops.md`

## Output

- **Artifact**: Staleness Map
- **Write to**: `loop-workspace/staleness-map.md`
- **Contract**: Read `loop/contracts/staleness-map.md` for the output schema.

## Steps

1. Identify the **change source**: Which artifact was modified and what specifically changed. Classify the change:
   - **Structural**: Added/removed stages, changed dependencies, new artifact boundaries. Deep cascade.
   - **Content**: Modified criteria, updated field values, changed descriptions. Shallow cascade.

2. Build the **connection graph** from the workspace artifacts:
   - **Forward edges** (stage dependencies): Stage A's output is Stage B's input → B depends on A.
   - **Backward edges** (feedback connections): Gate failure at boundary A→B routes to Stage C → C is connected to A→B boundary.
   - **Loop edges**: Loop connecting Stage X → Stage Y → Stage X → Y depends on X and X must handle Y's feedback.

3. **Trace forward** from the change source through stage dependencies. Every artifact that takes the changed artifact as input (directly or transitively) is potentially stale.

4. **Trace backward** through feedback loop connections and gate failure routes. A new feedback loop connecting to a previously unconnected stage means that stage's artifact spec, context budget, and definition may all need updating.

5. For each reachable artifact, record:
   - Why it's stale (the specific connection to the change source)
   - The cascade path (the sequence of connections from change to this artifact)
   - Which stage should re-run to refresh it
   - Whether the cascade is structural or content

6. For each unreachable artifact, record why it's unaffected.

7. Verify completeness: every artifact in the workspace appears in either `stale_artifacts` or `unaffected_artifacts`.

## Sources

None.

## Sinks

None.

## Guidance

- **Trace both directions**: Forward cascade through dependencies is obvious. Backward cascade through feedback connections is not — a new loop connecting to a previously unconnected stage can invalidate artifacts that appear "upstream" of the change.
- **Structural changes cascade deeper than content changes**: Adding a new stage invalidates artifacts.md, context-specs.md, and all workflow gates/loops. Changing a gate's criteria only affects the loop that references it.
- **Be conservative**: When in doubt, mark an artifact as stale. It's cheaper to re-execute an unaffected stage than to miss a genuine inconsistency.
- **The staleness map is advisory**: The orchestrator and user decide what to actually re-execute. The map provides the analysis; it doesn't mandate action.
- **This stage needs full workspace context**: Like Review Design, this stage legitimately needs all artifacts in context simultaneously to build the connection graph. Structure the traversal systematically — forward first, then backward — to manage cognitive load.
- **Example cascade patterns**:
  - "Adding a stage" → invalidates artifacts.md, context-specs.md, and all workflow gates/loops
  - "Changing a gate's criteria" → affects only the loop that references that gate
  - "Adding a feedback loop" → may invalidate the target stage's artifact spec (must handle feedback input) and context budget (new input to include)
