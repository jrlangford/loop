# Stage: Extract Existing Design

## Intent

Index the existing pipeline's stages, artifacts, context specs, and workflow configurations.

## Category & Posture

**Extract** — Index, don't analyse. Resist adding interpretation. The input is a populated loop-workspace directory; the output is a structured inventory of what exists.

## Input

- **Artifact**: Pipeline Input Directory
- **Read from**: Provided workspace path (the `loop-workspace/` directory to extend)
- **Contract**: Read `loop/contracts/pipeline-input-directory.md` for the input schema.

## Output

- **Artifact**: Existing Design Inventory
- **Write to**: Passed downstream as an in-memory artifact (not written to disk)
- **Contract**: Read `loop/contracts/existing-design-inventory.md` for the output schema.

## Steps

1. Validate the workspace path. Confirm that `stages.md`, `artifacts.md`, `context-specs.md`, and `transformation.md` all exist in the target directory.
2. Read `stages.md`. For each stage, extract: name, category, intent, a one-line summary of input shape, a one-line summary of output shape, and key domain assumptions. Record these as the `stages[]` array.
3. Read `artifacts.md`. For each artifact, extract: name, boundary, and top-level field names. Record these as the `artifacts[]` array.
4. Read `context-specs.md`. For each context spec, extract: stage name and a one-line budget summary. Record these as the `context_specs[]` array.
5. Check for a `workflows/` subdirectory. If present, iterate each workflow directory:
   - Read `gates.md` and count gates. Collect stage names referenced in gate positions.
   - Read `loops.md` and count loops. Collect stage names referenced in loop from/to fields.
   - Record: workflow name, gate count, loop count, and the union of referenced stage names.
6. Assemble the full Existing-Design-Inventory artifact. Verify all identity field uniqueness constraints before emitting.

## Sources

- Existing `loop-workspace/` directory contents: `stages.md`, `artifacts.md`, `context-specs.md`, `transformation.md`, and `workflows/*/gates.md`, `workflows/*/loops.md`

## Sinks

None.

## Guidance

- **Summarize, don't editorialize**: Contract summaries must describe the shape of what exists, not evaluate whether it is well-designed. Save "one-line summary" slots for structural descriptions like "accepts a list of stage names and their categories" rather than judgments like "a well-structured stage list".
- **Process file-by-file**: If the existing pipeline is large, read and summarize one file at a time (stages.md, then artifacts.md, then context-specs.md, then each workflow directory). This prevents context window pressure from loading everything simultaneously.
- **Domain assumptions matter**: Capture the key domain-specific assumptions embedded in each stage. These are critical for downstream reuse analysis — a stage built for "source code" cannot be blindly reused for "legal documents" even if the contract shape matches.
- **Do not load the new workflow description**: It is not needed at this stage and would be extraneous context that risks biasing the extraction.
- **Do not infer missing information**: If a field is absent from the source file, record it as absent rather than guessing. Downstream stages need accurate data, not plausible data.
