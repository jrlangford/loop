# Stage: Budget Context

## Intent

Budget context window per stage.

## Category & Posture

**Transform** — Convert representations. The input is stages + artifact specs; the output is per-stage context budgets.

## Input

- **Artifact**: Stage Decomposition — read from `loop-workspace/stages.md`
  - Contract: Read `loop/contracts/stage-decomposition.md`
- **Artifact**: Artifact Specifications — read from `loop-workspace/artifacts.md`
  - Contract: Read `loop/contracts/artifact-specifications.md`

## Output

- **Artifact**: Context Specifications
- **Write to**: `loop-workspace/context-specs.md`
- **Contract**: Read `loop/contracts/context-specifications.md` for the output schema.

## Steps

1. For each stage in stages.md, assess what goes into the context window:
   - **Germane load** (signal): Input artifact(s), system prompt with role instructions, domain reference material the stage needs to do its job.
   - **Extraneous load** (noise): Anything not directly needed — framework theory, upstream reasoning traces, artifacts from unrelated stages, implementation details.
   - **Intrinsic load**: The inherent complexity of the stage's task. If the stage processes large or variable-size inputs, note a chunking strategy (e.g., "work module-by-module", "process one section at a time").
2. Determine the **history policy**:
   - Default is **none** — each stage sees only its input artifacts, not the reasoning traces of prior stages.
   - Use **summary** only if the stage genuinely needs to know why upstream decisions were made (not just what they decided).
   - Use **full** only for review/audit stages that must trace reasoning quality.
   - Every deviation from "none" requires explicit justification.
3. Specify the **isolation model**: How the stage's context is managed.
   - Most stages: subagent with fresh context, seeing only the stage file, relevant contracts, and input artifact(s).
   - Interactive stages (at `per-stage` or `minimal` interaction): may run in orchestrator context to enable user dialogue.
   - Semantic gates: dedicated subagent with clean context (not the producing stage's context).
4. Assess **channel capacity risk**: Stages with multi-artifact input (high fan-in) risk exceeding effective context capacity. Flag these and suggest mitigation (e.g., summarize one input, process in chunks).

## Sources

None.

## Sinks

None.

## Guidance

- **History is the primary noise source**: The default is no history. Upstream reasoning traces are the biggest contributor to History Avalanche. Each stage should work from artifacts (the distilled output), not from the reasoning that produced them.
- **Signal/noise is relative to the stage**: What's germane for one stage is extraneous for another. Gate types are noise for decomposition but signal for gate placement.
- **Context specs are stage-level, not workflow-level**: The same stage may participate in multiple workflows with different gates and loops, but its context budget is the same. Gates and loops operate outside the stage's context — they're the orchestrator's concern.
- **Don't include framework theory in stage context**: Stages need task-specific instructions and domain knowledge, not general pipeline design principles.
