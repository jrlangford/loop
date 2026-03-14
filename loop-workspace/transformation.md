# Transformation Definition

## Task

Take a task description and produce a complete, internally consistent Loop pipeline design — with configurable human interaction levels and graph-aware cascade detection for edits.

## Input

**Design workflow**: A natural language task description of what an LLM pipeline should do. Highly variable — could be one sentence or multiple paragraphs. May include domain context, constraints, or examples.

**Edit workflow**: An existing `loop-workspace/` with design artifacts, plus a user-specified modification (changed stage, new feedback loop, removed gate, etc.).

**Both workflows**: A human interaction level setting:
- **Minimal** (default): Human review only on critical issues that require clearer definition (ambiguous decomposition boundaries, conflicting quality criteria, unclear domain requirements)
- **Per-stage**: Human review after every stage output
- **None**: Fully automated, no human checkpoints

## Output

A complete set of `loop-workspace/` design documents:
- `transformation.md` — problem definition
- `stages.md` — stage decomposition
- `artifacts.md` — inter-stage data contracts
- `context-specs.md` — per-stage context budgets
- `workflows/<name>/gates.md` — validation checkpoints
- `workflows/<name>/loops.md` — feedback loop specifications

**Quality criteria**:
- **Internal consistency**: Every stage referenced in artifacts exists in stages.md. Every gate references a real artifact boundary. Every feedback loop connects to stages that can handle the feedback input.
- **Completeness**: Every stage has artifact specs. Every artifact boundary has a gate decision (gate or explicit no-gate justification). Every feedback loop has termination conditions.
- **Implementability**: Output is directly consumable by `/loop:implement`.

**Consumer**: `/loop:implement` (generates Claude Code plugin from design) and human designers reviewing the design.

## Gap Analysis

**Multiple distinct cognitive operations**: The transformation requires define → decompose → specify artifacts → budget context → place gates → design feedback loops → review. Each operation requires different analytical focus. A single LLM call cannot reliably perform all of these — decomposition requires structural thinking, artifact specification requires contract design, gate placement requires failure mode analysis, and feedback loop design requires dynamic systems thinking.

**Cascading quality dependencies**: Each phase builds on the previous. A bad decomposition (Kitchen Sink stages, wrong boundaries) produces bad artifact specs, which produce misaligned gates, which produce feedback loops that can't correct the actual problems. Error amplification across phases is the primary risk.

**Edit workflow — graph-aware cascade detection**: When a design artifact changes, the impact is not limited to downstream artifacts in the linear phase sequence. A new feedback loop or gate failure route can connect to a previously unconnected stage, requiring that stage to handle feedback input it wasn't designed for. Cascade detection must trace the full connection graph — forward through stage dependencies, backward through feedback loops and gate failure routes — and flag everything reachable from the change as potentially stale. The user then decides how far to cascade re-execution.

**Configurable interaction levels**: The pipeline must support varying degrees of human involvement, from fully automated to interactive at every stage. This means gates must be parameterizable — some as human gates, some as automated, depending on the interaction level setting.

**Review as final validation**: Anti-pattern detection (Kitchen Sink, Echo Chamber, History Avalanche, Phantom Feedback, etc.) runs as a final stage, not as inline gates. This catches cross-cutting issues that no individual phase gate would detect.

## Complexity Signals

- **No external sources**: Works entirely from user input and existing workspace artifacts
- **No external sinks**: Writes to local filesystem only
- **Iterative refinement needed**: Review may identify issues requiring re-execution of earlier phases
- **Error reinforcement risk**: Each phase amplifies upstream quality — bad decomposition → bad everything downstream
- **Graph-aware cascade**: Edit workflow requires tracing connection graphs, not just linear dependencies
- **Configurable human interaction**: Gates must be parameterizable between human and automated modes
