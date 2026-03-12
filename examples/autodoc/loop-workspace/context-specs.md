# Context Specifications

## Isolation Model

Each stage runs in a **fresh, isolated context** (subagent delegation). No stage sees prior stages' reasoning, working memory, or conversation history. The only information crossing stage boundaries is the explicitly specified artifacts.

Semantic gates run in **dedicated clean contexts** containing only the artifact under evaluation and the validation criteria. Gates do not share the producing stage's context.

## Stage 1: Gather References

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Analysis Request — `references` list only (target scope not needed) |
| System prompt | Yes | Role: document loader. Extract text content from each reference source. Produce structured entries with source attribution. |
| Examples | No | Source types are self-explanatory |
| Domain reference | No | No domain knowledge needed — this is mechanical extraction |
| Upstream history | No | First stage |
| Reasoning trace | No | |

### Channel Assessment
- **Signal**: Reference locators + retrieval instructions per source type (file read, URL fetch, Notion MCP call)
- **Noise**: Target scope (irrelevant to reference loading), any formatting/template guidance
- **Information rate**: Low. One retrieval operation per reference. Well within single-inference capacity even with many references, since retrieval is tool-based (each fetch is a tool call, not context).

### Scaffolding
- Instructions for each source type: filesystem read, URL fetch, Notion MCP `notion-fetch` call
- Notion MCP availability check: if references include `type: "notion"`, verify MCP connection before attempting retrieval. If unavailable, report which references could not be loaded rather than failing the stage.
- Output format: Reference Index schema from artifacts.md
- Topic extraction guidance: identify 3-5 domain topics per reference for downstream keying

---

## Stage 2: Survey Codebase

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Analysis Request — `target_scope` only (references not needed) |
| System prompt | Yes | Role: code surveyor. Build structural map: files, constructs (functions/methods/classes), signatures, call relationships, test file mapping. |
| Examples | Yes | One example showing structural map output for a small code sample (language-appropriate to detected language) |
| Domain reference | No | Language detection is implicit from file extensions and syntax |
| Upstream history | No | |
| Reasoning trace | No | |

### Channel Assessment
- **Signal**: Source code files (read via tools), test naming conventions
- **Noise**: Reference documents, behaviour template, anything about what constitutes a "decision boundary"
- **Information rate**: Moderate. A microservice (5-20k lines) fits in context. For larger codebases with "full repo" scope, the stage should process files iteratively rather than loading all at once — scan directory tree, then read files individually to build the map incrementally.
- **Capacity concern**: If the target codebase exceeds ~50 files, the structural map itself could become large. The map is a compressed representation (signatures, not bodies), so this is unlikely to be a bottleneck at microservice scale.

### Scaffolding
- Test file convention patterns by language:
  - Go: `*_test.go` in same directory
  - Python: `test_*.py` or `*_test.py`, `tests/` directory
  - TypeScript/JavaScript: `*.spec.ts`, `*.test.ts`, `__tests__/` directory
  - Java: `*Test.java` in `src/test/`
  - Rust: `#[cfg(test)]` modules, `tests/` directory
- Output format: Codebase Structural Map schema from artifacts.md

---

## Stage 3: Identify Boundaries

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Codebase Structural Map (from Stage 2) |
| Passthrough artifact | Yes | Reference Index (from Stage 1) — used to sensitize heuristics. When empty, stage proceeds with heuristics alone. |
| System prompt | Yes | Role: decision boundary identifier. Scan structural map, re-read source files at candidate locations, apply heuristics to select boundaries worth documenting. |
| Examples | Yes | 2-3 examples showing a code region and the boundary identification judgment (one include, one exclude) |
| Domain reference | Yes | The 6 heuristics and 4 exclusion criteria (inlined from stages.md) |
| Upstream history | No | |
| Reasoning trace | No | |

### Channel Assessment
- **Signal**: Structural map (index for scanning), source code regions (read via tools at candidate locations), reference index (context for what the code is supposed to do)
- **Noise**: Behaviour template (not needed yet), deduplication rules, test file contents (Stage 4's concern)
- **Information rate**: This is the highest-judgment stage. The structural map is scanned as an index, then individual source files are re-read via tools for evaluation. The LLM makes one include/exclude decision per candidate. Information rate is moderate per decision but the stage may evaluate many candidates. At microservice scale (~100-200 functions), this is within single-inference capacity if the structural map is compact.
- **Reference index usage**: The stage uses reference topics to adjust heuristic sensitivity — e.g., if references discuss "retry policy", the stage should be more attentive to retry-related conditional branches. This is a bias signal, not a matching operation.

### Scaffolding
- Heuristics (inlined):
  1. Conditional branching with side effects
  2. Error handling boundaries
  3. Validation gates
  4. State transitions
  5. Integration points
  6. Configuration-driven behaviour
- Exclusion criteria (inlined):
  1. Pure data access with no branching
  2. Pass-through wrappers
  3. Framework-generated boilerplate
  4. Trivial null/nil checks that are language idioms
- Output format: Boundary List schema from artifacts.md

---

## Stage 4: Extract Behaviours

### Context Window Contents (per boundary — fan-out)
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Single boundary entry from Boundary List |
| Source code | Yes | Code region around the decision boundary (re-read from file via tools) |
| Test code | Yes | Corresponding test file, if mapped (re-read from file via tools) |
| Passthrough artifact | Partial | Reference Index entries matching this boundary's `reference_hints` only — not the full index |
| System prompt | Yes | Role: behaviour extractor. Produce one behaviour document following the template. |
| Examples | Yes | One complete filled-in behaviour document (use `behaviour-example-specified.md` as the example, adapted to show the template being populated) |
| Domain reference | Yes | `behaviour-template.md` — the full template with field definitions |
| Upstream history | No | |
| Reasoning trace | No | |

### Channel Assessment
- **Signal**: The boundary entry (location, type, evidence snippet), the surrounding source code, test assertions (evidence for contracts), relevant reference entries, the template
- **Noise**: Other boundaries (each extraction is independent), structural map (already consumed), full reference index (only matching entries included)
- **Information rate**: Low per boundary. Each extraction is a focused, single-inference task: read code, identify contracts, write one document. The template provides strong structural guidance. The fan-out keeps each context small and independent.
- **Fan-out strategy**: Each boundary is extracted in a separate subagent context. The orchestrator distributes boundary entries and collects completed behaviour documents. Boundaries can be processed in parallel since they are independent.

### Scaffolding
- Behaviour template: full `behaviour-template.md` content including field definitions, classification guidance, and scenario format
- Contract extraction guidance:
  - Preconditions: what must be true before the decision point (look for guard clauses, validation, assertions)
  - Postconditions: what the code guarantees after each branch (look for return values, state mutations, external calls)
  - Invariants: what remains true regardless of which branch is taken
  - When a condition is relevant but not testable, state this explicitly with rationale
- Test-informed extraction: use test setup as precondition evidence, assertions as postcondition evidence. Tests don't replace reasoning — they corroborate it.
- ID generation: `BHV-<4-6 hex chars>`, non-sequential
- Category assignment: `specified` when reference_hints are non-empty and the behaviour is clearly mandated; `implicit` when assumed by convention; `undefined` when uncertain
- Output format: single behaviour document per artifacts.md schema

---

## Stage 5: Deduplicate Behaviours

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Input artifact | Yes | Full Behaviour Document Set (from Stage 4) |
| System prompt | Yes | Role: deduplication evaluator. Identify behaviour documents covering the same decision. Merge true duplicates, preserve similar-but-distinct. |
| Examples | Yes | One example showing a merge decision (two documents covering the same validation in handler + middleware → merged with combined traceability) |
| Domain reference | No | |
| Upstream history | No | |
| Reasoning trace | No | |

### Channel Assessment
- **Signal**: The full set of behaviour documents — titles, descriptions, code references, and contracts are the comparison fields
- **Noise**: Scenario details and failure modes (useful for the final output but not for deduplication comparison)
- **Information rate**: Moderate. At ~30 documents of ~200 lines each (~6k lines), the full set fits in one context. The comparison task is well-structured: group by code location proximity and decision similarity, then evaluate each group. Within single-inference capacity.

### Scaffolding
- Merge rules:
  - **True duplicate**: same logical decision implemented in multiple code paths → merge into one document, combine all traceability links (code refs, test refs, reference hints)
  - **Similar but distinct**: same pattern (e.g., validation) but different domain meaning (e.g., validating payment amount vs. validating shipping address) → keep both
  - When merging, preserve the richer document (more complete contracts, more scenarios) and add traceability from the thinner one
- Deduplication report format per artifacts.md schema
- Output format: Deduplicated Behaviour Document Set per artifacts.md schema

---

## Passthrough Artifact Summary

Two artifacts are consumed by stages they don't directly follow:

| Artifact | Produced by | Consumed by | Rationale |
|----------|-------------|-------------|-----------|
| Reference Index | Stage 1 | Stage 3, Stage 4 | Sensitizes boundary heuristics (Stage 3); informs contract extraction and category assignment (Stage 4, filtered to matching entries only) |
| Codebase Structural Map | Stage 2 | Stage 3, post-pipeline validation gate | Primary input for Stage 3; used by the consistency gate after Stage 5 to verify coverage and reference validity |

The orchestrator is responsible for routing passthrough artifacts to consuming stages.

---

## Post-Pipeline Validation Gate Context

A consistency gate after Stage 5 compares the deduplicated behaviour set against the Codebase Structural Map. This gate runs in a dedicated clean context.

### Context Window Contents
| Component | Include? | Content |
|-----------|----------|---------|
| Artifact under evaluation | Yes | Deduplicated Behaviour Document Set (code references and traceability only — not full documents) |
| Reference artifact | Yes | Codebase Structural Map (from Stage 2) |
| Validation criteria | Yes | Three checks (see below) |
| Upstream history | No | |
| Producing stage context | No | Gate must evaluate independently |

### Validation Checks
1. **Coverage gaps**: Constructs in the structural map that contain decision-boundary patterns (conditional branches, error handling, state transitions) but are not referenced by any behaviour document. Report as potential misses — not automatic failures, since Stage 3 may have correctly excluded them.
2. **Stale references**: Behaviour documents with code references (file:function, file:line) that don't match any construct in the structural map. These indicate extraction errors.
3. **Orphaned behaviours**: Behaviour documents whose code references point to files not present in the structural map at all. These may indicate hallucinated locations.

### Gate outcome
- **Pass**: No stale references, no orphaned behaviours, coverage gaps below a threshold (reported but not blocking)
- **Fail (stale/orphaned)**: Quality failure — flag affected documents for correction
- **Advisory (coverage gaps)**: Report gaps for user review; do not block pipeline completion
