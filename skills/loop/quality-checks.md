# Structural Quality Checks

Quality dimensions beyond anti-patterns. Used by review (checking design artifacts) and audit (checking implementation). Each section describes what to check and why it matters. Skills apply these checks to their specific domain — review checks design specifications, audit checks implementation behavior.

## Contract Alignment

Do producers and consumers agree on artifact format?

- Does what Stage A produces actually match what Stage B expects?
- Are there implicit assumptions about format not documented in the artifact spec?
- Are there version/schema mismatches between producers and consumers?
- Does every stage boundary have an artifact spec?
- Does every artifact have at least one consumer? (No dead outputs)
- Are there artifact fields with no downstream consumer? (Over-specification)

## Error Recovery

What happens when things go wrong?

- What happens when a stage fails mid-execution?
- Is there checkpointing? Can the pipeline resume?
- Are partial artifacts left behind that could confuse re-runs?

## Context Window Budget

For LLM-based stages — is context managed deliberately?

- Estimate actual token usage per stage based on what's loaded
- Flag stages loading supporting docs exceeding reasonable budgets
- Does the implementation manage context deliberately or just load everything?

## Source Dependencies

External read dependencies — declared and handled?

- Does the pipeline read from external resources (web, APIs, MCP servers, databases)?
- Are sources declared in stage definitions, or implicit/hidden?
- What happens when a source is unavailable — graceful degradation or crash?
- Are there stages assumed to be pure transformations that actually have undeclared external dependencies?

## Sink Dependencies

External write dependencies — safe and declared?

- Does the pipeline write to external systems (APIs, databases, git, Slack, notification services)?
- Are sinks declared in stage definitions, or hidden?
- Do Emit stages have idempotency markers (stable IDs, checksums, transaction references)?
- Are gates placed *before* external writes to validate artifacts before they leave the pipeline?
- What happens if a sink write fails — safe retry, or risk of partial/duplicate writes?
- Are notification sinks (Slack, email, webhooks) fire-and-forget (non-blocking)?
- If loops pass through Emit stages, are iteration caps tight (≤3) and idempotency addressed?
- Are all sinks declared? (Hidden sinks are a traceability risk)

## Precondition Checks

Are external dependencies validated before the pipeline starts?

- Does the pipeline check that sources and sinks are reachable before starting? (API tokens valid, MCP servers connected, git branch writable, Slack channel exists)
- Missing precondition checks on pipelines with external dependencies waste all prior work on mid-pipeline failures
- If stages are delegated to subagents, do subagent prompts include relevant preconditions? Subagents run in isolated contexts and may lack tool access, network permissions, or MCP server connections that the orchestrator validated

## Context Isolation

Are stages properly isolated from each other?

- **Stage delegation**: Does each stage run in a fresh context (subagent), or does the orchestrator execute stages in its own context? Inline execution accumulates every stage's working memory — file reads, intermediate reasoning, correction attempts — defeating the purpose of staging.
- **Semantic gate isolation**: Do semantic gates run in dedicated subagents with clean context (artifact + criteria only)? A semantic gate evaluated in the same context as the producing stage inherits the production trajectory, making it unreliable.
- **Loop retry isolation**: When loops re-run a stage after gate failure, does the re-run use a fresh subagent? Re-running in the same context preserves the failed attempt's reasoning, anchoring the retry to the same errors.

## Stage/Workflow Separation

Are transformation logic and orchestration logic properly separated?

- Are stages isolated transformations, or do they contain wiring logic (sequencing, gate checks, loop control)?
- Could the same stage be reused in a different workflow without modification?
- Is workflow-level configuration (gate criteria, iteration bounds, stage ordering) separate from stage definitions?
- Do stages invoke other stages directly, or produce an artifact and stop?

## Implementation Structure

Is the pipeline structured for maintainability?

**Stages as skills (anti-pattern):** Individual pipeline stages implemented as independently invocable skills (each with its own SKILL.md and slash command). Problems:
- Contract duplication: each stage must inline input/output schemas
- No shared resources: shared concepts (enums, taxonomies) are copy-pasted
- Skill proliferation: N stages + orchestrator = N+1 slash commands
- False independence: stages appear independently invocable but rarely make sense outside their pipeline

**Recommended structure:** A Claude Code plugin with a shared resource directory (`skills/<prefix>/`) containing `stages/` (reference documents) and `contracts/` (artifact schemas), plus orchestrator skills (`skills/run/`) as the only user-facing entry points.

**Plugin packaging:** A `.claude-plugin/plugin.json` manifest enables namespaced invocation (`/<prefix>:run`), prevents skill name collisions, and makes the pipeline distributable. Check that the `name` field matches the skill prefix, `keywords` includes `"loop-pipeline"`, and all skills are under `skills/`.

## Loop Safety

Are feedback loops bounded and monitored?

- Does every loop have both a semantic termination condition AND a hard iteration cap?
- Does every loop have a degradation detector?
- Are iteration caps reasonable? Flag: >10 for balancing, >5 for reinforcing, >3 for loops involving Emit stages
- For balancing loops: are evaluating and refining stages separate inference calls with separate contexts? Same-context evaluation creates a reinforcing dynamic inside a balancing loop
- Does every loop with a degradation detector specify a best-iteration selection strategy? Using the last iteration's output means more iterations create more opportunities to end worse
- Do all gate retry paths have a hard cap? A retry without a maximum is an unbounded loop

## Stochastic Validation

Is pipeline reliability characterized, not just single-run tested?

- LLM stages are stochastic — a pipeline has a *success rate*, not a pass/fail result
- Does the pipeline track run-to-run variance? Look for: gate pass/fail logging, loop iteration count tracking, output quality metrics
- A single test run cannot capture whether the pipeline is reliable or just got lucky
- **Severity:** WARNING if no variance tracking exists for pipelines with semantic gates or feedback loops

## Handoff Drift Resilience

Do artifacts resist interpretation drift across stages?

- Do artifacts use enums and closed vocabularies where the domain allows?
- Do artifacts carry source references (file paths, line numbers, verbatim quotes) alongside interpretation?
- Are factual observations and evaluative judgments in distinct fields?
- Are there identity fields that remain stable across stages? Are they verified?
- For long pipelines (5+ stages): is there a re-grounding checkpoint comparing late-stage artifacts against original input?
- Do semantic validation steps operate in independent context, not the producing stage's context?
