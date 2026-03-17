# Loop

How do we collaborate effectively with AI?

Some work requires structured engagement, while other work benefits from free exploration. For the former, effective collaboration with LLMs requires explicit workflow design — one that identifies what can be delegated to the LLM and what requires human judgement.

Loop is a design framework for structuring LLM work as pipelines: sequences of focused stages connected by explicit feedback loops, with human review at critical quality gates. It's delivered as a set of Claude Code skills that guide you through pipeline design interactively and can translate finished designs into implementable Claude skills.

## Core Ideas

**Stages.** Decompose work into stages that each do one thing well. Each stage transforms an input artifact into an output artifact. Stages are isolated — they don't know what comes before or after them.

**Gates.** Validation checkpoints between stages that catch errors before they propagate downstream. Gates range from cheap automated checks (schema validation, metric thresholds) to LLM-based quality assessment to explicit human review. When a gate fails, it routes the failure back to the right stage with actionable feedback. Every gate has a bounded retry count and an escalation path — including escalation to human review when automated checks can't make the call.

**Feedback loops.** Every feedback connection is classified as reinforcing (amplifying) or balancing (correcting), with explicit termination conditions and degradation detectors. This prevents runaway elaboration, echo chambers, and loops that never actually correct anything.

**Channel capacity.** Each stage's context window is a finite channel. Every stage gets a deliberate budget — what goes in (signal), what stays out (noise), and why. The default is no history; deviations must be justified. This prevents late stages from drowning in irrelevant upstream context.

**Two-level design.** Stages are reusable building blocks. Workflows are lightweight composition layers that wire stages together with gates and loops. The same stages can participate in multiple workflows with different configurations.

## Installation

Install from the [jrlangford-marketplace](https://github.com/jrlangford/jrlangford-marketplace):

```claude
/plugin marketplace add https://github.com/jrlangford/jrlangford-marketplace
/plugin install loop@jrlangford-marketplace
```

## Quick Start

Once installed, here's how to go from idea to runnable pipeline skills:

### 1. Design your pipeline

```
/loop:design "description of what your pipeline does"
```

This walks you through each design phase interactively: define the transformation, decompose into stages, specify artifacts, budget context, place gates, design feedback loops, and review for anti-patterns. All artifacts are written to `loop-workspace/` in your project.

### 2. Clear context

The design workflow is conversational and will fill your context window. Clear context in your Claude Code session before implementing.

```
/clear
```

### 3. Implement the design

```
/loop:implement my-pipeline
```

This reads `loop-workspace/` and generates a Claude Code plugin at your project root — `.claude-plugin/plugin.json`, stage instructions, artifact contracts, and orchestrator skills that wire everything together.

### 4. Test the plugin

Load the generated plugin locally:

```sh
claude --plugin-dir .
```

Your pipeline is now available as `/my-pipeline:run`. To share it, you can [publish it to a marketplace](https://code.claude.com/docs/en/plugin-marketplaces).

## Skills

For most workflows, `/loop:design` and `/loop:implement` are all you need. The remaining skills are available for more specific use cases.

### Design and build

| Skill | Purpose |
|-------|---------|
| `/loop:design` | Full design pipeline: define → decompose → artifacts → context → gates → feedback → review |
| `/loop:implement` | Generate a Claude Code plugin from design artifacts |
| `/loop:edit` | Edit an existing design — maps staleness, selectively re-executes affected stages |
| `/loop:describe` | Generate a readable summary with mermaid diagrams from design artifacts |

### Review and audit

| Skill | Purpose |
|-------|---------|
| `/loop:audit-design` | Check a design for anti-patterns, missing gates, unbounded loops, and context issues |
| `/loop:audit-implementation` | Audit an implementation against Loop principles; reports design-implementation drift if design artifacts exist |

### Working with existing pipelines

| Skill | Purpose |
|-------|---------|
| `/loop:reverse` | Reverse-engineer an existing implementation into Loop design artifacts, then redesign and implement as a clean plugin |

## Workspace Structure

Skills produce artifacts in `loop-workspace/`:

```
loop-workspace/
├── transformation.md       # Problem definition
├── stages.md               # Stage decomposition (reusable)
├── artifacts.md             # Inter-stage data contracts (reusable)
├── context-specs.md         # Per-stage context budgets (reusable)
└── workflows/
    ├── conservative/        # One workflow composition
    │   ├── gates.md
    │   └── loops.md
    └── exploratory/         # Different wiring, same stages
        ├── gates.md
        └── loops.md
```

## Anti-Patterns

The framework defines nine anti-patterns that the audit skills check for:

1. **Kitchen Sink Stage** — A stage doing too many things
2. **Echo Chamber Loop** — Reinforcing loop without novelty detection
3. **History Avalanche** — Unbounded context accumulation
4. **Phantom Feedback Loop** — Loop that never triggers correction
5. **Hardcoded Chain** — Stages coupled to a fixed sequence
6. **Ouroboros** — Unintentional circular dependencies
7. **Telephone Game** — Cumulative interpretation drift across stages
8. **Fire-and-Forget Emit** — External write without idempotency, pre-write gate, or tight loop caps
9. **Toll Booth Pipeline** — Mandatory human gate acting as a cut vertex, splitting workflow into two disconnected halves

## Documentation

- [framework-design.md](framework-design.md) — Full design framework: principles, anatomy, design process, patterns, anti-patterns
- [feedback-loops-in-llms.md](feedback-loops-in-llms.md) — Background: how reinforcing and balancing feedback loops operate in LLM systems
- [information-flow-and-context.md](information-flow-and-context.md) — Background: information theory applied to LLM context windows
