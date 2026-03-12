# Transformation Definition

## Task

Extract structured behaviour documents from source code by identifying decision boundaries, then producing one behaviour document per boundary following a standardised template.

## Input

### Source code
- **Scope**: User-specified files/directories by default; option to analyze the entire repository
- **Language**: Language-agnostic — the pipeline adapts to whatever language(s) the codebase uses
- **Volume**: Microservice-scale repository (typically dozens of files, one bounded domain)
- **Quality issues**: Code may lack comments, have inconsistent naming, or contain dead code that looks like active decision points

### Reference documents (optional)
- Design docs, user stories, PRDs, API specs — any document that provides intent context for the code
- Formats: local files (markdown, text, HTML), URLs, Notion pages
- **Notion integration requires the Notion MCP server installed and correctly configured**
- When references are absent, the pipeline still extracts behaviours but cannot classify any as `specified` — all will be `implicit` or `undefined`

## Output

- **Format**: One markdown file per behaviour, following `behaviour-template.md`
- **Expected volume**: ~30 behaviour documents per microservice
- **Consumer**: Developers, designers, and LLMs (must be both human-readable and machine-parseable)
- **Quality criteria**:
  1. Every behaviour has at least one scenario (Given/When/Then)
  2. Pre/postconditions are testable; when a relevant condition is not testable, this is explicitly stated with rationale
  3. Every behaviour is traceable to at least one code reference (file:function or file:line) or existing test
  4. No duplicate behaviours covering the same decision boundary
  5. Classification is `specified` (traceable to a provided reference), `implicit` (assumed by convention), or `undefined` (cannot be confidently classified). The `emergent` category is omitted — cross-component interaction behaviours are too difficult to reliably extract via static analysis

## Gap Analysis

### Why a single call fails
- **Volume**: A microservice repo exceeds a single context window when combined with template instructions and reference documents
- **Two distinct cognitive operations**: (1) scanning code to identify decision boundaries, and (2) writing structured behaviour documents with contracts and scenarios. These require different context — code exploration vs. template conformance
- **Cross-referencing for classification**: Determining `specified` vs `implicit` requires comparing code against reference documents — a different attention mode than reading code

### Decision boundary identification — heuristics
This is the core hard problem. Not every function is a behaviour. Heuristics for identifying decision boundaries worth documenting:

1. **Conditional branching with side effects** — `if/else`, `switch/match` blocks that change system state, call external services, or return different response types
2. **Error handling boundaries** — try/catch, error return patterns where the system chooses between recovery, retry, propagation, or fallback
3. **Validation gates** — input validation, authorization checks, precondition assertions that accept or reject
4. **State transitions** — code that moves an entity from one status to another (e.g., `pending` → `charged`, `draft` → `published`)
5. **Integration points** — calls to external services, databases, message queues where the system must handle success/failure/timeout
6. **Configuration-driven behaviour** — feature flags, environment-dependent logic, strategy patterns

### What's best-effort
- **Classification accuracy**: When the pipeline can't confidently classify a behaviour, it marks it `undefined` rather than guessing
- **Scenario completeness**: Happy path scenarios are required; edge case scenarios are best-effort
- **Postcondition testability**: Some postconditions may be stated as non-testable (e.g., "no side effects in external system") — this is acceptable when explicitly noted

### Domain knowledge
- None required beyond what the code and optional references provide — the pipeline infers domain from the codebase itself

## Complexity Signals

- **Parallelisation opportunity**: Once decision boundaries are identified, individual behaviour documents can be extracted independently — natural fan-out point
- **External knowledge dependency (sources)**: Reference documents (optional), Notion pages via MCP (optional)
- **No external write targets**: Output is local markdown files only
- **Error reinforcement risk**: LOW — each behaviour document is extracted independently, no iterative refinement across documents
- **Refinement need**: MODERATE — the decision boundary identification stage may surface false positives (trivial conditionals) that need filtering before document generation
