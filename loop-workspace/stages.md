# Stage Decomposition

## Pipeline Overview
Take a task description and produce a complete, internally consistent Loop pipeline design — with configurable human interaction and graph-aware cascade detection for edits.
13 stages total (8 design/edit + 5 add-workflow).

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

### Stage 9: Extract-Existing-Design
- **Category**: Extract
- **Intent**: Index the existing pipeline's stages, artifacts, context specs, and workflow configurations
- **Input**: Populated `loop-workspace/` directory (all stage-level artifacts and existing workflow directories)
- **Output**: Structured inventory of existing stages (names, categories, input/output contracts), existing artifacts, existing context specs, and existing workflow gate/loop configurations
- **Sources**: Existing `loop-workspace/` directory contents (stages.md, artifacts.md, context-specs.md, workflows/*/gates.md, workflows/*/loops.md)
- **Sinks**: None
- **Complexity**: Must capture enough contract detail per stage for downstream reuse analysis — not just names, but input/output shapes and domain assumptions. Volume scales with existing pipeline size.

### Stage 10: Analyze-Reuse
- **Category**: Evaluate
- **Intent**: Assess each existing stage's applicability to the new workflow's requirements
- **Input**: Existing design inventory (from Extract-Existing-Design) and the new workflow's natural-language description
- **Output**: Reuse analysis report: per-stage reuse verdict (reuse as-is, not applicable) with rationale, plus list of capability gaps requiring new stages
- **Sources**: None
- **Sinks**: None
- **Complexity**: This is the core judgment call. Each reuse decision requires comparing the new workflow's semantic needs against the existing stage's contract shapes and domain assumptions. Incorrect classifications here propagate downstream. Findings must be presented for human review before proceeding.

### Stage 11: Define-New-Stages
- **Category**: Transform
- **Intent**: Specify new stages needed to fill capability gaps identified in the reuse analysis
- **Input**: Reuse analysis report (capability gaps) and existing design inventory (to avoid naming collisions)
- **Output**: New stage definitions (name, category, intent, input, output, context specs) and corresponding new artifact contracts, formatted for append to shared artifacts
- **Sources**: None
- **Sinks**: None
- **Complexity**: Must respect the append-only constraint — new entries must not collide with existing names or create ambiguous references in the dependency graph. Each new stage must follow the one-verb heuristic and fit cleanly into the existing artifact dependency structure.

### Stage 12: Compose-Workflow
- **Category**: Synthesise
- **Intent**: Assemble the new workflow's gates and loops from reused and newly defined stages
- **Input**: Reuse analysis report (reused stages), new stage definitions, and existing design inventory
- **Output**: New workflow directory content: gates.md and loops.md for the new workflow
- **Sources**: None
- **Sinks**: None
- **Complexity**: Gate criteria on shared stages must be compatible with any existing workflow's gate criteria for those same stages. Loop definitions must reference only stages that actually exist (reused or newly added). May also need to update transformation.md scope if the new workflow broadens the pipeline's purpose.

### Stage 13: Validate-Consistency
- **Category**: Evaluate
- **Intent**: Verify cross-workflow consistency across all workflows including the new one
- **Input**: Full extended design: existing design inventory, new stage definitions, new workflow gates/loops, and all existing workflow configurations
- **Output**: Validation report: pass/fail with list of inconsistencies (naming collisions, conflicting gate criteria on shared stages, dangling references, incompatible context specs)
- **Sources**: Existing `loop-workspace/` workflow directories (for cross-workflow comparison)
- **Sinks**: None
- **Complexity**: Requires holistic reasoning about the full set of gates, loops, and context specs simultaneously. Conflicting gate criteria on shared stages may be subtle. If inconsistencies are found, this stage produces actionable findings that drive refinement upstream.
