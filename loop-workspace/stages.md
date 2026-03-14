# Stage Decomposition

## Pipeline Overview
Take a task description and produce a complete, internally consistent Loop pipeline design — with configurable human interaction and graph-aware cascade detection for edits.
8 stages total.

## Stages

### Stage 1: Define Transformation
- **Category**: Transform
- **Intent**: Define the pipeline's transformation from task description
- **Input**: Natural language task description (pipeline input)
- **Output**: Transformation definition (task statement, input/output specs, gap analysis, complexity signals)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must distinguish between tasks that need staging and those a single call can handle. Must elicit sufficient detail from vague descriptions — ambiguity here cascades into every downstream stage.

### Stage 2: Decompose Stages
- **Category**: Transform
- **Intent**: Decompose transformation into bounded stages
- **Input**: Transformation definition
- **Output**: Stage decomposition (ordered stage list with categories, intents, inputs, outputs, dependencies)
- **Sources**: None
- **Sinks**: None
- **Complexity**: One-verb heuristic enforcement. Kitchen Sink detection. Must identify natural context isolation boundaries — where a fresh context window helps rather than hurts.

### Stage 3: Specify Artifacts
- **Category**: Transform
- **Intent**: Specify inter-stage data contracts
- **Input**: Stage decomposition
- **Output**: Artifact specifications (typed contracts with structure, validation rules, identity fields, omitted fields)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must prevent handoff drift — use closed vocabularies over free text, references over paraphrases, separate observation from judgment. Identity fields must be mechanically checkable.

### Stage 4: Budget Context
- **Category**: Transform
- **Intent**: Budget context window per stage
- **Input**: Stage decomposition + artifact specifications
- **Output**: Context specifications (per-stage context budgets — germane, extraneous, intrinsic load, history policy)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Default is no history — deviations must be justified. Must assess whether stages with multi-artifact input risk exceeding effective channel capacity.

### Stage 5: Place Gates
- **Category**: Transform
- **Intent**: Place validation checkpoints at artifact boundaries
- **Input**: Stage decomposition + artifact specifications
- **Output**: Gate specifications (gate positions, types, criteria, failure routes, max retries, escalation paths)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must distinguish deterministic failures (schema/metric) from probabilistic failures (semantic). Gate criteria must be tight enough to catch real problems but not so tight they false-positive on LLM variance. Interaction level setting determines which gates are human vs. automated. Workflow-scoped — same stages can have different gates in different workflows.

### Stage 6: Design Feedback
- **Category**: Transform
- **Intent**: Design feedback loops with termination conditions
- **Input**: Stage decomposition + artifact specifications + gate specifications
- **Output**: Loop specifications (loop types, stages involved, termination conditions, degradation detectors, iteration caps)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must classify each loop as reinforcing or balancing. Every loop needs both semantic termination and a hard cap. Degradation detectors must distinguish normal LLM variance from true quality decline. New feedback connections may require upstream stages to handle feedback input they weren't originally designed for. Workflow-scoped.

### Stage 7: Review Design
- **Category**: Evaluate
- **Intent**: Evaluate design for anti-patterns and consistency
- **Input**: All workspace artifacts (transformation.md, stages.md, artifacts.md, context-specs.md, gates.md, loops.md)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must detect cross-cutting issues that no individual phase gate catches — Kitchen Sink, Echo Chamber, History Avalanche, Phantom Feedback, Hardcoded Chain, Ouroboros, Telephone Game. Must verify internal consistency across all artifacts (referential integrity, completeness, implementability). Findings may route back to earlier stages for correction.

### Stage 8: Map Staleness
- **Category**: Evaluate
- **Intent**: Trace impact of changes through the design's connection graph
- **Input**: Modified artifact + full workspace (all existing design artifacts)
- **Output**: Staleness map (which artifacts are stale, why, and which stages need re-execution)
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must trace both forward (stage dependencies) and backward (feedback loop connections, gate failure routes). A new feedback loop connecting to a previously unconnected stage means that stage's artifact spec, context budget, and definition may all need updating. Must distinguish structural changes (added/removed stages) from content changes (modified criteria) — different cascade depths.
