# Stage: Survey Codebase

## Intent

Build a structural map of the target code.

## Category and Posture

**Category**: Extract
**Posture**: Index, don't analyse. Resist adding interpretation — that's downstream. Record what exists (files, functions, signatures, calls, test mappings) without judging what's important.

## Input

Read the Analysis Request from `autodoc-workspace/analysis-request.md`. Use only the `target_scope` — ignore `references` (not needed for this stage).

- If `mode: "specified"`, scan only the listed paths
- If `mode: "full_repo"`, scan from the repository root

## Output

Write the Codebase Structural Map to `autodoc-workspace/structural-map.md`.

Read `autodoc/contracts/codebase-structural-map.md` for the output schema.

## Steps

1. Determine the target scope from the Analysis Request
2. List all source files in scope (excluding build artifacts, dependencies, generated files)
3. For each file:
   a. Detect the programming language from extension and syntax
   b. Extract all constructs: functions, methods, classes, modules
   c. For each construct, record: name, type, signature (parameter types + return type), line range
   d. Identify call relationships between constructs (which constructs call which)
   e. Identify the corresponding test file using language-specific conventions
4. Detect the test mapping convention used in the project
5. Assemble the structural map

## Sources

| Source | Access method | Required? |
|--------|--------------|-----------|
| Local filesystem | Read tool, Glob tool | Yes — source code files |

## Sinks

None.

## Guidance

- **Do** produce a compressed representation — signatures and structure, not raw file contents
- **Do** detect language from file extensions and syntax, not guesswork
- **Do** identify test files using language-specific conventions:
  - Go: `*_test.go` in same directory
  - Python: `test_*.py` or `*_test.py`, `tests/` directory
  - TypeScript/JavaScript: `*.spec.ts`, `*.test.ts`, `__tests__/` directory
  - Java: `*Test.java` in `src/test/`
  - Rust: `#[cfg(test)]` modules, `tests/` directory
- **Do** record call relationships — these help Stage 3 identify integration points
- **Do not** include raw file contents in the map — Stage 3 re-reads files as needed
- **Do not** include import statements, inline comments, or type definitions that aren't constructs
- **Do not** judge which constructs are "important" — index everything

### Large Codebases

If the target scope contains more than ~50 files, process files iteratively rather than loading all at once. Scan the directory tree first, then read files individually to build the map incrementally. The structural map is a compressed representation (signatures, not bodies), so it should remain manageable even for larger codebases.

### Test Mapping

Test file detection is a precondition for downstream stages. If no test naming convention is detected:
- Still populate `test_mapping_conventions` with a note that no convention was found
- Set `test_file: null` for all files
- Do not fail — some codebases have no tests
