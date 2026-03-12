# Artifact Specifications

## Pipeline Input: Analysis Request

- **Content**: Target scope and optional reference list
- **Format**:
  ```
  target_scope:
    mode: "specified" | "full_repo"
    paths: [list of file/directory paths]  # when mode = "specified"

  references: [                            # may be empty
    { type: "file", locator: "<path>" },
    { type: "url", locator: "<url>" },
    { type: "notion", locator: "<page_id>" }
  ]
  ```
- **Variability**: `target_scope` always present. `references` frequently empty — all downstream stages must handle the empty-reference case.

---

## Artifact: Stage 1 (Gather References) → Stage 3, Stage 4

### Reference Index

- **Content**: Structured collection of reference content with source attribution. Each entry contains the extracted text and metadata about where it came from.
- **Structure**:
  ```
  entries: [
    {
      source_type: "file" | "url" | "notion"
      source_locator: <original path/URL/page_id>
      title: <document title or filename>
      content: <extracted text, cleaned of formatting noise>
      topics: [<list of domain topics covered>]
    }
  ]
  ```
- **Identity fields**: `source_type`, `source_locator` — must not be altered downstream
- **Omitted**: Original formatting, navigation elements, metadata not relevant to domain content (author, last-edited timestamps, etc.)
- **Validation**: Each entry has non-empty `content` and a valid `source_locator`. Notion entries validate that the MCP connection succeeded.
- **Reasoning trace**: None — the content speaks for itself, provenance is in `source_locator`
- **Routing**: Skips Stage 2 (Survey Codebase). Consumed by Stage 3 (Identify Boundaries) to inform heuristic sensitivity, and Stage 4 (Extract Behaviours) to inform contract extraction. When empty, downstream stages proceed without it.

---

## Artifact: Stage 2 (Survey Codebase) → Stage 3

### Codebase Structural Map

- **Content**: Skeleton of the target codebase — files, functions/methods with signatures, classes/modules, call relationships, and test file mapping. No raw source code.
- **Structure**:
  ```
  files: [
    {
      path: <file path>
      language: <detected language>
      constructs: [
        {
          type: "function" | "method" | "class" | "module"
          name: <identifier>
          signature: <parameter types and return type, language-appropriate>
          line_range: [start, end]
          calls: [<list of construct names this construct calls>]
        }
      ]
      test_file: <path to corresponding test file, if identified> | null
    }
  ]

  test_mapping_conventions: <detected test naming pattern, e.g., "*_test.go", "*.spec.ts">
  ```
- **Identity fields**: `path`, `name`, `line_range` — these are source-of-truth references that must not mutate
- **Omitted**: Raw file contents, inline comments, import statements, type definitions that aren't decision-relevant. Stage 3 re-reads source files as needed.
- **Validation**: Every file in `target_scope` is represented. Every construct has a non-empty `name` and valid `line_range`. `language` is detected, not guessed.
- **Reasoning trace**: None — the map is mechanical extraction, no judgment involved

---

## Artifact: Stage 3 (Identify Boundaries) → Stage 4

### Boundary List

- **Content**: Decision boundaries worth documenting, each with location, type, and a brief description of the decision being made.
- **Structure**:
  ```
  boundaries: [
    {
      id: <temporary sequential index for reference within this artifact>
      location: {
        file: <file path>
        function: <function/method name>
        line_range: [start, end]
      }
      type: "conditional_branch" | "error_handling" | "validation_gate"
            | "state_transition" | "integration_point" | "config_driven"
      decision_summary: <one sentence: what choice does the system make here?>
      evidence: <verbatim code snippet showing the branching point, ≤10 lines>
      reference_hints: [<source_locator values from Reference Index that informed this identification>] | []
    }
  ]
  ```
- **Identity fields**: `location` (file, function, line_range), `evidence` (verbatim snippet)
- **Omitted**: Full function body, surrounding context, call graph. Stage 4 re-reads the source file for full context during extraction.
- **Validation**:
  - Each boundary has a single `type` from the enum (no multi-type entries)
  - `decision_summary` is one sentence with a single decision verb
  - `evidence` is verbatim source code, not paraphrase
  - `location.file` exists in the Codebase Structural Map
- **Reasoning trace**: Summary — `reference_hints` records which references (if any) influenced the decision to include this boundary. This helps Stage 4 understand why a boundary was considered significant.

---

## Artifact: Stage 4 (Extract Behaviours) → Stage 5

### Behaviour Document Set

- **Content**: One behaviour document per boundary, following `behaviour-template.md` format
- **Structure**: Each document is a standalone markdown file containing:
  ```
  - id: "BHV-<4-6 hex chars>"
  - title: <behaviour title>
  - classification:
      category: "specified" | "implicit" | "undefined"
      source: "implementation"                          # always, in this workflow
      significance: "critical" | "important" | "minor"
      status: "draft"                                   # always draft on first extraction
  - description: <what the system does and why it matters>
  - trigger: <initiating event or condition>
  - actors: [<participating entities>]
  - contracts:
      preconditions: [<testable conditions, or explicitly marked non-testable with rationale>]
      postconditions: [<testable conditions, or explicitly marked non-testable with rationale>]
      invariants: [<conditions that hold throughout>]
      failure_modes: [{condition, response, postcondition}]    # best-effort
  - scenarios:
      happy_path: {given, when, then}                          # required
      edge_cases: [{given, when, then}]                        # best-effort
  - traceability:
      code_references: [<file:function or file:line>]          # at least one required
      test_references: [<test file:test function>]             # may be empty
      reference_hints: [<source_locators from Reference Index>] # carried forward from Boundary List
  ```
- **Identity fields**: `id`, `traceability.code_references`, `traceability.test_references`, `traceability.reference_hints` — Stage 5 must preserve these exactly, combining but never altering
- **Omitted**: Raw source code, structural map data, boundary list metadata. The behaviour document is self-contained.
- **Validation**:
  - Every document has at least one scenario (happy path)
  - Every document has at least one code reference
  - `id` values are unique across the set
  - Non-testable conditions are explicitly marked with rationale
  - `category` is assigned: `specified` when `reference_hints` is non-empty and the behaviour is clearly mandated by a reference; `implicit` when the behaviour is assumed by convention; `undefined` when classification is uncertain
- **Reasoning trace**: None — the behaviour document is the output, not an intermediate

---

## Pipeline Output: Deduplicated Behaviour Document Set

- **Content**: Final set of behaviour documents with duplicates merged
- **Format**: Same structure as Behaviour Document Set, plus a deduplication report
- **Deduplication report**:
  ```
  total_extracted: <count from Stage 4>
  duplicates_merged: <count of merge operations>
  final_count: <count of output documents>
  merges: [
    {
      kept: <BHV-id of preserved document>
      merged_from: [<BHV-ids of documents merged into it>]
      reason: <why these were considered duplicates>
    }
  ]
  ```
- **Quality criteria** (from transformation definition):
  1. Every behaviour has at least one scenario
  2. Pre/postconditions are testable, or explicitly marked non-testable with rationale
  3. Every behaviour traceable to at least one code reference or test
  4. No duplicate behaviours covering the same decision boundary
- **Consumer**: Developers, designers, and LLMs
