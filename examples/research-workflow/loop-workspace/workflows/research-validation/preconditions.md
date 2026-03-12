# Preconditions

## Source Dependencies

### Web Search
- **Used by**: Verify Claims (Stage 3), Reconcile Disagreements (Stage 5)
- **Required**: Yes — the pipeline cannot produce meaningful verification without web search. Citation checking and factual validation both depend on external lookups.
- **Validation**: Execute a test web search query before pipeline start. Confirm a result is returned within a reasonable timeout (e.g., 10 seconds).
- **On failure**: Abort pipeline before Stage 1. No value in extracting and classifying claims if they cannot be verified.

## Configuration Dependencies

### Source Document
- **Used by**: Extract Claims (Stage 1), Extraction Completeness gate (semantic evaluator context)
- **Required**: Yes
- **Validation**: The input markdown file exists, is non-empty, and is valid UTF-8.
- **On failure**: Abort pipeline — no input to process.
