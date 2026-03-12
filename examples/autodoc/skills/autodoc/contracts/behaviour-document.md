# Contract: Behaviour Document

**Produced by**: Extract Behaviours (Stage 4) — one document per boundary
**Consumed by**: Deduplicate Behaviours (Stage 5)
**Workspace path**: `autodoc-workspace/behaviours/BHV-<hex>.md`

## Structure

Each document is a standalone markdown file following the behaviour template format:

```yaml
id: "BHV-<4-6 hex chars>"
title: <behaviour title>

classification:
  category: "specified" | "implicit" | "undefined"
  source: "implementation"                           # always
  significance: "critical" | "important" | "minor"
  status: "draft"                                    # always on first extraction

description: <what the system does and why it matters>
trigger: <initiating event or condition>
actors: [<participating entities>]

contracts:
  preconditions:
    - <testable condition, OR explicitly marked non-testable with rationale>
  postconditions:
    - <testable condition, OR explicitly marked non-testable with rationale>
  invariants:
    - <conditions that hold throughout>
  failure_modes:                                     # best-effort
    - condition: <what goes wrong>
      response: <system reaction>
      postcondition: <resulting state>

scenarios:
  happy_path:                                        # required
    given: <setup>
    when: <action>
    then: <outcome>
  edge_cases:                                        # best-effort
    - given: <setup>
      when: <action>
      then: <outcome>

traceability:
  code_references:
    - <file:function or file:line>                   # at least one required
  test_references:
    - <test file:test function>                      # may be empty
  reference_hints:
    - <source_locators from Reference Index>         # carried forward from Boundary List
```

## Identity Fields

These must be preserved exactly by Stage 5 (combining but never altering):
- `id`
- `traceability.code_references`
- `traceability.test_references`
- `traceability.reference_hints`

## Omitted

- Raw source code
- Structural map data
- Boundary list metadata

The behaviour document is self-contained.

## Validation Rules

1. Every document has at least one scenario (happy path with Given/When/Then)
2. Every document has at least one code reference in traceability
3. `id` values are unique across the set (BHV-<4-6 hex chars> format)
4. Non-testable conditions are explicitly marked with rationale
5. `category` assignment follows these rules:
   - `specified`: `reference_hints` is non-empty AND the behaviour is clearly mandated by a reference
   - `implicit`: behaviour is assumed by convention (common patterns, language idioms)
   - `undefined`: classification is uncertain
6. `source` is always `implementation`
7. `status` is always `draft`

## Reasoning Trace

None. The behaviour document is the output, not an intermediate.
