# Stage: Decompose Stages

## Intent

Decompose transformation into bounded stages.

## Category & Posture

**Transform** — Convert representations. Input and output are structurally different. The input is a problem definition; the output is a stage list.

## Input

- **Artifact**: Transformation Definition
- **Read from**: `loop-workspace/transformation.md`
- **Contract**: Read `loop/contracts/transformation-definition.md` for the input schema.

## Output

- **Artifact**: Stage Decomposition
- **Write to**: `loop-workspace/stages.md`
- **Contract**: Read `loop/contracts/stage-decomposition.md` for the output schema.

## Steps

1. Read the transformation definition. Focus on the gap analysis and complexity signals — these drive decomposition boundaries.
2. Apply the **one-verb heuristic**: each stage's intent must be a single verb phrase. If you need "and", "then", or a semicolon, you have two stages.
3. Assign each stage a **category** from the enum:
   - **Extract**: Index, don't analyse. Resist adding interpretation.
   - **Enrich**: Add information, don't transform structure.
   - **Transform**: Convert representations. Input and output are structurally different.
   - **Evaluate**: Assess against criteria. Separate observation from judgment.
   - **Synthesise**: Combine inputs into a new whole. Reference sources, don't paraphrase.
   - **Refine**: Improve based on specific feedback. Change only what the feedback addresses.
   - **Emit**: Push to external target. Validate completeness before writing.
4. Order stages following these principles:
   - **Narrow before wide**: Reduce scope early; expand later.
   - **Fail-fast**: Put stages likely to reject input early in the pipeline.
   - **Cheap before expensive**: Run fast/cheap stages before slow/expensive ones.
   - **Emit last**: External writes happen at the end, after all quality checks.
5. Identify **context isolation boundaries**: Where does a fresh context window help? A new stage is warranted when the upstream working memory (reasoning traces, intermediate notes) would pollute downstream analysis.
6. Check for **parallel opportunities**: Stages that share the same input and have no dependency between them can run in parallel. Note this in the overview.
7. Write the stage decomposition with overview (one-line summary + stage count) and the ordered stage list.

## Sources

None.

## Sinks

None.

## Guidance

- **Kitchen Sink detection**: If a stage's complexity notes run longer than 2-3 sentences, or if the intent can't be expressed as a single verb phrase, it's doing too much. Split it.
- **Don't over-decompose**: Each stage boundary incurs handoff cost (information loss, gate overhead). A stage that does one simple thing in 10 tokens doesn't need its own context window. Target the sweet spot where each stage requires enough reasoning to benefit from isolation.
- **The decomposition must cover the full gap analysis**: Every difficulty identified in transformation.md's gap analysis must map to at least one stage. If a difficulty is unaddressed, either add a stage or explain why it's handled implicitly.
- **Verify against source material**: Re-read the transformation definition after drafting the decomposition. Ensure no drift — the stages should collectively achieve exactly the transformation described, nothing more.
