# Anti-Pattern Catalogue

Eight anti-patterns that indicate structural problems in LLM pipelines. Used by review (checking design artifacts) and audit (checking implementation). Each check must be addressed by name — a missing check means it wasn't performed, not that the pipeline is clean.

## 1. Kitchen Sink Stage

A stage that does too many things.

**What to look for:**
- Intent contains multiple verbs or conjunctions ("extract and evaluate", "classify then route")
- Stage spans multiple categories (e.g., Extract + Evaluate)
- Complexity notes are extensive (3+ sentences) or describe internal phasing
- Implementation unit has complex sub-phases that could be independent stages

**Severity:** WARNING if 2 verbs, ERROR if 3+

## 2. Echo Chamber Loop

A reinforcing loop that runs without convergence or novelty checks.

**What to look for:**
- Reinforcing loops without a novelty gate or delta check
- Loops that could run autonomously without progress tracking
- Missing degradation detector on reinforcing loops
- Revision/retry paths that don't track whether they're making progress

**Severity:** ERROR if no convergence check on autonomous loops; WARNING if human-gated loops lack progress tracking

## 3. History Avalanche

Unbounded context accumulation across stages.

**What to look for:**
- Late-pipeline stages reading early-pipeline artifacts they don't need
- Stages loading full upstream history rather than specific fields
- Context accumulating within stages across sub-phases
- History included without justification (default should be "none")
- Stages sharing context with the orchestrator or other stages instead of running in isolated subagents

**Severity:** WARNING if unjustified history, ERROR if full history in 3+ stages

## 4. Phantom Feedback Loop

A loop that exists but never triggers meaningful correction.

**What to look for:**
- Validation gates unlikely to ever fail (criteria too loose)
- Retry paths that make only cosmetic changes
- Human review gates not specific enough to catch real problems
- Loops where the corrective path doesn't address the failure mode the gate checks for

**Severity:** WARNING

## 5. Hardcoded Chain

Stages coupled to a fixed sequence rather than producing artifacts and stopping.

**What to look for:**
- Stages that invoke their successor directly instead of producing an artifact
- Stage descriptions referencing a specific successor by name
- Stages that couldn't be reused in a different workflow without modification
- Implementation units that contain wiring logic (sequencing, gate checks, loop control)

**Severity:** WARNING

## 6. Ouroboros

Unintentional circular dependencies between stages.

**What to look for:**
- Circular dependencies spanning 3+ stages that aren't declared as intentional loops
- Loops without termination conditions
- Stage A → Stage B → Stage C → Stage A patterns without explicit loop declaration

**Severity:** ERROR

## 7. Telephone Game

Cumulative interpretation drift across stages.

**What to look for:**
- Artifacts relying on free-text interpretations where enums or source references would work
- Long pipelines (5+ stages) with no mechanism to compare late-stage output against original input
- Artifacts mixing observed facts with evaluative conclusions in single fields
- Stages passing forward their summary/paraphrase without source references (file paths, line numbers, verbatim quotes)
- No identity fields defined where the domain has stable identifiers
- No re-grounding checkpoint in long pipelines

**Severity:** WARNING if free-text fields dominate without source references; ERROR if 5+ stages with no identity verification and no re-grounding

## 8. Fire-and-Forget Emit

External writes without safety controls.

**What to look for:**
- Emit stages without idempotency markers (stable IDs, transaction references, checksums)
- Gates placed *after* external writes instead of *before* (writes can't be undone)
- Loop or retry paths that re-enter through an Emit stage without tight iteration caps (≤3)
- Notification sinks that incorrectly block the pipeline on failure (should be fire-and-forget)
- Undeclared sinks — external writes hidden in stages not classified as Emit

**Severity:** ERROR if emit stage has no idempotency strategy or no upstream gate; WARNING if loop re-entry through emit stage without tight cap

## Coverage Requirement

Every review or audit report must address all 8 anti-patterns by name. For clean anti-patterns, include an INFO-level note confirming the check passed (e.g., "INFO: Ouroboros — no circular dependencies found").
