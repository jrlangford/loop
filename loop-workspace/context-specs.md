# Context Specifications

## Stage: Define Transformation

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Task description (user-provided free text) |
| System prompt | Yes | Transformation definition role — elicit input/output specs, gap analysis, complexity signals. Challenge vague answers. |
| Examples | No | — |
| Domain reference | Yes | Complexity signal checklist (parallelization, refinement, sources, sinks, error reinforcement). Single-call-vs-staging decision criteria. |
| Upstream history | No | First stage — no upstream |
| Reasoning trace | No | — |

### Channel Assessment
- **Signal**: Task description + elicitation structure (worksheet questions)
- **Noise**: Framework theory, anti-pattern definitions, implementation details — none of these are needed to define the transformation
- **Information rate**: Low — well within single-inference capacity. The main challenge is elicitation quality, not context volume.

### Isolation Model
Interactive stage when interaction level is `minimal` or `per-stage` — runs in the orchestrator's context to enable user dialogue. At `none`, runs as a subagent with the task description as sole input.

## Stage: Decompose Stages

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Transformation Definition (transformation.md) |
| System prompt | Yes | Decomposition role — apply one-verb heuristic, identify context isolation boundaries, check Kitchen Sink. |
| Examples | No | — |
| Domain reference | Yes | Stage category table (Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit). Ordering principles (narrow before wide, fail-fast, cheap before expensive, emit last). |
| Upstream history | No | Transformation definition carries everything needed |
| Reasoning trace | No | — |

### Channel Assessment
- **Signal**: Transformation definition + decomposition heuristics
- **Noise**: Artifact schemas, gate types, feedback loop patterns — not yet relevant
- **Information rate**: Low to moderate — depends on transformation complexity. A complex multi-domain pipeline may push toward decomposition into many stages, but the decomposition task itself is bounded.

### Isolation Model
Subagent with fresh context. Sees only transformation.md and decomposition instructions. If interaction level is `per-stage`, results are presented to user before proceeding.

## Stage: Specify Artifacts

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Stage Decomposition (stages.md) |
| System prompt | Yes | Contract design role — specify typed boundaries, apply handoff drift techniques, identify identity fields. |
| Examples | No | — |
| Domain reference | Yes | Handoff drift techniques (enumerate don't describe, reference don't paraphrase, separate observation from judgment). Reasoning trace decision guide. |
| Upstream history | No | Stage decomposition carries all needed stage info |
| Reasoning trace | No | — |

### Channel Assessment
- **Signal**: Stage list (names, categories, intents, inputs, outputs) + contract design heuristics
- **Noise**: Transformation gap analysis, complexity signals — already distilled into the stage decomposition
- **Information rate**: Moderate — scales with stage count. Each artifact requires field-level specification. For pipelines with 8+ stages, this is the densest stage in terms of output volume.

### Isolation Model
Subagent with fresh context. Sees only stages.md and artifact specification instructions.

## Stage: Budget Context

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Stage Decomposition (stages.md) + Artifact Specifications (artifacts.md) |
| System prompt | Yes | Context budgeting role — assess signal/noise per stage, apply history default, check load conflicts. |
| Examples | No | — |
| Domain reference | Yes | History Avalanche definition. Channel capacity concepts (signal, noise, interference). Isolation model options (subagent delegation, clean context for semantic gates). |
| Upstream history | No | Stages and artifacts carry everything needed |
| Reasoning trace | No | — |

### Channel Assessment
- **Signal**: Stage list + artifact contracts + budgeting framework
- **Noise**: Transformation gap analysis, complexity signals not relevant to context budgeting
- **Information rate**: Moderate — two input artifacts, but the task per stage is bounded (assess what goes in, what stays out). Fan-in from stages.md and artifacts.md is the main context cost.

### Isolation Model
Subagent with fresh context. Sees stages.md, artifacts.md, and context budgeting instructions. This is the first stage with multi-artifact input — both are needed because context budgets depend on what each stage does (from stages.md) and what it receives (from artifacts.md).

## Stage: Place Gates

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Stage Decomposition (stages.md) + Artifact Specifications (artifacts.md) |
| System prompt | Yes | Gate placement role — identify failure modes, assign gate types, design failure routes, set escalation paths. |
| Examples | No | — |
| Domain reference | Yes | Gate type table (Schema, Metric, Identity, Semantic, Consensus, Human). Failure routing guidance (deterministic vs. probabilistic failures). Silent omission detection strategies. Interaction level mapping to gate types. |
| Upstream history | No | Stages and artifacts carry everything needed |
| Reasoning trace | No | — |

### Channel Assessment
- **Signal**: Stage list + artifact contracts (especially validation rules and identity fields) + gate placement heuristics
- **Noise**: Context budgets — not relevant to gate placement. Transformation gap analysis — already distilled into stages.
- **Information rate**: Moderate — similar to Budget Context. Two input artifacts plus gate design heuristics. The main complexity is failure mode analysis per boundary, which is analytically dense but bounded per gate.

### Isolation Model
Subagent with fresh context. Sees stages.md, artifacts.md, and gate placement instructions. Does NOT see context-specs.md — gate placement is independent of context budgets.

## Stage: Design Feedback

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Stage Decomposition (stages.md) + Artifact Specifications (artifacts.md) + Gate Specifications (gates.md) |
| System prompt | Yes | Feedback loop design role — classify loops, set termination conditions, design degradation detectors. |
| Examples | No | — |
| Domain reference | Yes | Loop classification (Reinforcing vs. Balancing). Established patterns table (Evaluator-optimizer, Prompt chaining, Parallelisation, Orchestrator-workers). Anti-pattern definitions (Echo Chamber, Phantom Feedback, Ouroboros). |
| Upstream history | No | Three input artifacts carry everything needed |
| Reasoning trace | No | — |

### Channel Assessment
- **Signal**: Stage list + artifact contracts + gate specs (failure routes are the primary source of loop candidates) + loop design patterns
- **Noise**: Context budgets — not relevant to loop design. Transformation definition — already distilled.
- **Information rate**: Moderate to high — three input artifacts is the largest fan-in in the pipeline. Gate failure routes are the primary signal for identifying loops. For complex pipelines with many gates, this stage approaches channel capacity limits. If the pipeline has 10+ gates, consider chunking: design loops for one workflow at a time.

### Isolation Model
Subagent with fresh context. Sees stages.md, artifacts.md, gates.md, and loop design instructions. This is the highest fan-in stage — three input artifacts. The gate specs are the critical input since failure routes define most loops.

## Stage: Review Design

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | All workspace artifacts (transformation.md, stages.md, artifacts.md, context-specs.md, gates.md, loops.md) |
| System prompt | Yes | Review role — check anti-patterns, verify consistency, assess completeness and implementability. |
| Examples | No | — |
| Domain reference | Yes | Anti-pattern definitions (Kitchen Sink, Echo Chamber, History Avalanche, Phantom Feedback, Hardcoded Chain, Ouroboros, Telephone Game). Consistency check rules (referential integrity, completeness). |
| Upstream history | No | Workspace artifacts are the complete design |
| Reasoning trace | Summary | From gates.md and loops.md — gate placement and loop design rationale helps the reviewer assess whether the reasoning was sound |

### Channel Assessment
- **Signal**: All 6 design artifacts + anti-pattern definitions + consistency rules
- **Noise**: Framework theory beyond anti-patterns — not needed for review. Decomposition heuristics, context budgeting theory — review checks results, not process.
- **Information rate**: High — this is the most context-intensive stage, receiving all artifacts. For large pipelines (10+ stages), this may approach effective capacity. Mitigate by structuring the review as a checklist: anti-patterns first (cross-cutting), then consistency (per-artifact), then completeness (per-boundary).

### Isolation Model
Subagent with fresh context. Sees all workspace artifacts and review instructions. Must NOT share context with any producing stage — the reviewer must assess the design independently. This is the only stage that legitimately needs all artifacts in context simultaneously.

## Stage: Map Staleness

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Modified artifact (the changed file) + full workspace (all existing design artifacts) |
| System prompt | Yes | Staleness analysis role — trace forward dependencies and backward feedback connections from the change source, classify cascade type (structural vs. content). |
| Examples | Yes | Example cascade patterns: "adding a stage invalidates artifacts.md, context-specs.md, and all workflow gates/loops" vs. "changing a gate's criteria only affects the loop that references it" |
| Domain reference | Yes | Connection graph traversal rules: forward (stage → artifact → downstream stage), backward (gate failure route → upstream stage, loop connection → participating stages). Structural vs. content change distinction. |
| Upstream history | No | The workspace artifacts and modification request carry everything needed |
| Reasoning trace | Full | The designer needs to see the traversal reasoning to evaluate whether the staleness analysis is correct |

### Channel Assessment
- **Signal**: The modified artifact + all current workspace artifacts (to build the connection graph) + traversal rules
- **Noise**: Framework theory, design process heuristics — not relevant to staleness analysis
- **Information rate**: High — similar to Review Design. Needs all artifacts to build the connection graph. The traversal itself is bounded but requires holding the full graph in context. For very large pipelines, consider providing a pre-computed dependency summary rather than raw artifacts.

### Isolation Model
Subagent with fresh context. Sees all workspace artifacts, the modification request, and staleness analysis instructions. Like Review, this stage legitimately needs the full workspace to trace connections.
