# Design Quality Checks

Quality dimensions for reviewing pipeline design artifacts. Each section describes what to check in stage definitions, artifact specifications, gate configurations, and loop specifications.

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

- Does the design specify what happens when a stage fails?
- Is there a resumption strategy? Can the pipeline restart from a failed stage?
- Are failure modes identified for stages with external dependencies?

## Context Window Budget

Is context managed deliberately?

- Does each stage have a context spec that budgets token usage?
- Are there stages loading large supporting documents without accounting for context limits?
- Do context specs distinguish between essential input and optional reference material?

## Source Dependencies

External read dependencies — declared and handled?

- Does the pipeline read from external resources (web, APIs, MCP servers, databases)?
- Are sources declared in stage definitions, or implicit/hidden?
- Does the design specify behavior when a source is unavailable?
- Are there stages assumed to be pure transformations that actually have undeclared external dependencies?

## Sink Dependencies

External write dependencies — safe and declared?

- Does the pipeline write to external systems (APIs, databases, git, Slack, notification services)?
- Are sinks declared in stage definitions, or hidden?
- Do Emit stages specify idempotency markers (stable IDs, checksums, transaction references)?
- Are gates placed *before* external writes to validate artifacts before they leave the pipeline?
- Does the design specify what happens if a sink write fails?
- Are notification sinks (Slack, email, webhooks) marked as fire-and-forget (non-blocking)?
- If loops pass through Emit stages, are iteration caps tight (≤3) and idempotency addressed?
- Are all sinks declared? (Hidden sinks are a traceability risk)

## Precondition Checks

Are external dependencies validated before the pipeline starts?

- Does the design specify preconditions for sources and sinks? (API tokens valid, MCP servers connected, git branch writable, Slack channel exists)
- Missing precondition checks on pipelines with external dependencies waste all prior work on mid-pipeline failures
- Are preconditions assigned to specific stages or only declared globally?

## Stage/Workflow Separation

Are transformation logic and orchestration logic properly separated?

- Are stages isolated transformations, or do they contain wiring logic (sequencing, gate checks, loop control)?
- Could the same stage be reused in a different workflow without modification?
- Is workflow-level configuration (gate criteria, iteration bounds, stage ordering) separate from stage definitions?
- Do stages invoke other stages directly, or produce an artifact and stop?

## Loop Safety

Are feedback loops bounded and monitored?

- Does every loop have both a semantic termination condition AND a hard iteration cap?
- Does every loop have a degradation detector?
- Are iteration caps reasonable? Flag: >10 for balancing, >5 for reinforcing, >3 for loops involving Emit stages
- For balancing loops: are evaluating and refining stages specified as separate inference calls?
- Does every loop with a degradation detector specify a best-iteration selection strategy?
- Do all gate retry paths have a hard cap?

## Stochastic Validation

Is pipeline reliability characterized, not just single-run tested?

- LLM stages are stochastic — a pipeline has a *success rate*, not a pass/fail result
- Does the design account for run-to-run variance? Look for: gate pass/fail expectations, loop iteration count estimates, output quality metrics
- **Severity:** WARNING if no variance consideration exists for pipelines with semantic gates or feedback loops

## Human Intervention Coverage

Are human review points placed where risk warrants them?

- Are there boundaries with human gate candidates that have no Human gate and no documented override rationale? (Unaddressed candidates suggest the designer didn't consider the risk.)
- For pipelines with `none` pipeline interaction level: are human gate candidates still documented as observations, even though they can't be promoted? (The risk exists regardless of interaction level — documenting it helps operators.)
- For pipelines with external sinks (Emit stages): is there at least one human gate candidate at or before the first Emit stage? (Irreversible writes without any human review opportunity are high-risk.)
- Are there `documented` candidates without rationale for why they weren't promoted? (A candidate that was considered and deliberately left as `documented` should explain why.)
- Do all `overridden` candidates include the designer's rationale for declining? (Overrides without reasoning are indistinguishable from oversights.)
- Does any promoted Human gate act as a **cut vertex** — a mandatory stop where all paths from pipeline input to output pass through that single gate, with no alternative automated path? If so, flag as a Toll Booth Pipeline (anti-pattern #9): the workflow is likely two independent workflows joined by a human handoff and should be split.

## Handoff Drift Resilience

Do artifacts resist interpretation drift across stages?

- Do artifacts use enums and closed vocabularies where the domain allows?
- Do artifacts carry source references (file paths, line numbers, verbatim quotes) alongside interpretation?
- Are factual observations and evaluative judgments in distinct fields?
- Are there identity fields that remain stable across stages?
- For long pipelines (5+ stages): is there a re-grounding checkpoint comparing late-stage artifacts against original input?
