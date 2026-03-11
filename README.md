# Loop

A design framework for structuring LLM-based information processing as pipelines of stages, with explicit feedback loops, channel capacity budgets, and anti-pattern detection.

Loop is not a runtime framework — it has no scheduler, no orchestrator library, no SDK. It is a design framework for pipelines — a lens that can be applied before, during, and after building. Designs can be translated into Claude Code skills (prompt documents) via `/loop-implement`, which Claude Code then executes directly.

## Core Ideas

**Staged transformation.** Decompose tasks into stages that each do one thing well. Each stage transforms an input artifact into an output artifact. Stages are isolated — they don't know what comes before or after them.

**Two-level design.** Stages are reusable transformation units. Workflows are lightweight composition layers that wire stages together with gates (validation checkpoints) and loops (feedback connections). The same stages can participate in multiple workflows with different configurations.

**Feedback loops as first-class elements.** Every feedback connection is classified as reinforcing (amplifying) or balancing (correcting), with explicit termination conditions and degradation detectors. This prevents runaway elaboration, echo chambers, and phantom feedback.

**Channel capacity budgets.** Each stage's context window is a finite-capacity channel. Each stage gets a deliberate context specification — what goes in (signal), what stays out (noise), and why. The default is no history; deviations must be justified. This prevents the History Avalanche where late-pipeline stages drown in irrelevant upstream context.

**Sources.** Stages that access external resources (web, APIs, MCP servers, databases) declare their dependencies explicitly, distinguishing pure transformations from enriched transformations and enabling traceability, failure handling, and testability.

## Documentation

- [framework-design.md](framework-design.md) — Full design framework: principles, anatomy, design process, patterns, anti-patterns
- [feedback-loops-in-llms.md](feedback-loops-in-llms.md) — Background: how reinforcing and balancing feedback loops operate in LLM systems
- [information-flow-and-context.md](information-flow-and-context.md) — Background: information theory applied to LLM context windows

## Skills

Loop is delivered as a set of Claude Code skills that guide pipeline design interactively.

### Phase Skills (produce one artifact each)

| Skill | Purpose |
|-------|---------|
| `/loop-define` | Define the transformation: input, output, gap, complexity signals |
| `/loop-decompose` | Break into stages using the one-verb heuristic |
| `/loop-artifacts` | Specify inter-stage data contracts |
| `/loop-context` | Budget channel capacity per stage |
| `/loop-gates` | Place validation checkpoints (workflow-scoped) |
| `/loop-feedback` | Design feedback loops (workflow-scoped) |
| `/loop-review` | Check design for anti-patterns |
| `/loop-reverse` | Reverse-engineer implementation into Loop vocabulary |
| `/loop-audit` | Audit implementation against Loop principles |

### Implementation Skills (translate design to code)

| Skill | Purpose |
|-------|---------|
| `/loop-implement` | Generate shared resource directory (stages + contracts) and orchestrator skills from design artifacts |

### Workflow Skills (orchestrate phase skills)

| Skill | Path |
|-------|------|
| `/loop-wf-design` | Greenfield: define → decompose → artifacts → context → gates → feedback → review |
| `/loop-wf-analyze` | Existing code: reverse → review → audit |
| `/loop-wf-align` | Drift check: audit → resolve → re-audit |

## Installation

Requires [just](https://github.com/casey/just).

```sh
just install    # Symlink skills to ~/.claude/skills/
just uninstall  # Remove symlinks
just status     # Show installed skills
```

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

The framework defines seven anti-patterns that the review and audit skills check for:

1. **Kitchen Sink Stage** — A stage doing too many things
2. **Echo Chamber Loop** — Reinforcing loop without novelty detection
3. **History Avalanche** — Unbounded context accumulation
4. **Phantom Feedback Loop** — Loop that never triggers correction
5. **Hardcoded Chain** — Stages coupled to a fixed sequence
6. **Ouroboros** — Unintentional circular dependencies
7. **Telephone Game** — Cumulative interpretation drift across stages due to free-text paraphrasing, mixed observation/judgment, and no re-grounding
