# Loop Vocabulary

Definitions of core Loop framework concepts. Skills reference this document when they need to identify or classify pipeline elements.

## Stages

Isolated transformation units. Each stage transforms an input artifact into an output artifact. A well-designed stage does one thing (the one-verb heuristic).

| Category | Intent | Example |
|----------|--------|---------|
| **Extract** | Pull structure from unstructured input | Raw text → structured entities |
| **Enrich** | Add information to an existing artifact | Entities → entities with context |
| **Transform** | Convert between representations | Domain model → implementation plan |
| **Evaluate** | Assess quality against criteria | Draft → scored draft with issues |
| **Synthesise** | Combine multiple artifacts into one | Multiple analyses → unified report |
| **Refine** | Improve an artifact based on feedback | Draft + critique → improved draft |
| **Emit** | Push an artifact to an external target | Report → published report (via API, git, Slack) |

## Artifacts

Typed, structured intermediate representations passed between stages. They should be self-describing, validatable, serialisable, and minimal.

Key design properties:
- *Enumerate, don't describe* — prefer closed vocabularies (enums, scores) over free text to reduce interpretation drift
- *Reference, don't paraphrase* — carry source locations rather than the producing stage's interpretation
- *Separate observation from judgment* — distinct fields for evidence vs. assessment
- *Identity fields* — a stable subset of fields that should pass through stages unchanged (source refs, IDs, verbatim quotes)

## Gates

Validation checkpoints between stages. Workflow-scoped — the same stage boundary can have different gates in different workflows.

| Type | Nature | Cost |
|------|--------|------|
| **Schema** | Structural presence of required fields/sections | Deterministic, zero inference |
| **Metric** | Quantitative threshold check | Deterministic, zero inference |
| **Identity** | Verify immutable fields haven't mutated | Deterministic, zero inference |
| **Semantic** | LLM-based quality assessment | Probabilistic, one inference call |
| **Consensus** | Multi-evaluator agreement | Probabilistic, N inference calls |
| **Human** | Human review and decision | Zero inference, requires human time |

Each gate specifies: pass criteria, failure route, feedback carried, max retries, escalation.

## Loops

Explicit feedback connections between stages. Workflow-scoped.

- **Reinforcing (R)** — amplify, deepen, elaborate. Risk: echo chamber (unbounded elaboration without novelty). Requires novelty gate + iteration cap.
- **Balancing (B)** — correct, constrain, converge. Risk: phantom feedback (loop that never triggers correction). Requires convergence criteria + degradation detector.

Every loop must have: declared type (R or B), semantic termination condition, hard iteration cap, degradation detector.

## Sources

External resources a stage reads from to bring new information into the pipeline: web, API, MCP server, database, filesystem. Sources are distinct from input artifacts — an input artifact flows through the pipeline from an upstream stage; a source enters from outside.

## Sinks

External targets a stage writes to, pushing data out of the pipeline: APIs, databases, git, notification services (Slack, email, webhooks), filesystem. Sinks are distinct from output artifacts — an output artifact flows to a downstream stage; a sink receives data from the pipeline into an external system.

Stages with sinks are **emitting transformations** and carry special concerns: idempotency (preventing duplicate writes on retry), gate failure recovery (writes can't be undone), and testability (need sink mocks).

**Notifications** are a sink subtype that is fire-and-forget by default — failure doesn't block the pipeline.

## Stage Classification

| Classification | Sources | Sinks | Characteristics |
|---------------|---------|-------|-----------------|
| **Pure** | None | None | Deterministic retry, easy to test |
| **Enriched** | Yes | None | External read dependency, may need source mocks |
| **Emitting** | None | Yes | Idempotency required, gate before write |
| **Enriched emitting** | Yes | Yes | Both concerns apply |

## Workflows

Compose stages into specific pipelines — which stages, in what order, with which gates and loops. Same stages can participate in multiple workflows with different wiring. Workflows are lightweight orchestration, not transformation logic.
