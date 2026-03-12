# Gate Specifications

## Gate: Structural Map Validity (after Stage 2: Survey Codebase)

- **Position**: Between Stage 2 (Survey Codebase) and Stage 3 (Identify Boundaries)
- **Artifact checked**: Codebase Structural Map
- **Type**: Schema + Metric
- **Criteria**:
  - Schema:
    - Every file in `target_scope` is represented in the map
    - Every construct has non-empty `name`, `signature`, and valid `line_range`
    - `language` is detected for each file (not null or "unknown")
  - Metric:
    - At least one construct found across all files (catches total parse failure)
    - `test_mapping_conventions` is populated (test file detection was attempted)
- **On failure**:
  - **Routes to**: Stage 2 (Survey Codebase)
  - **Carries**: List of specific failures — which files failed to parse, which constructs have missing fields, whether test mapping was skipped entirely
  - **Max retries**: 2
  - **Escalation**: Report unparseable files to user; proceed with partial map if at least 80% of files parsed successfully. Abort if <80%.

---

## Gate: Boundary Quality (after Stage 3: Identify Boundaries)

- **Position**: Between Stage 3 (Identify Boundaries) and Stage 4 (Extract Behaviours)
- **Artifact checked**: Boundary List
- **Type**: Schema + Semantic
- **Criteria**:
  - Schema:
    - Every boundary has a single `type` from the enum (`conditional_branch` | `error_handling` | `validation_gate` | `state_transition` | `integration_point` | `config_driven`)
    - `decision_summary` is one sentence with a single decision verb
    - `evidence` is non-empty (verbatim code snippet)
    - `location.file` exists in the Codebase Structural Map
  - Semantic (runs in clean context with Boundary List + Structural Map):
    - **Accuracy spot-check**: For a sample of 3-5 boundaries, does the `decision_summary` accurately describe the decision shown in `evidence`?
    - **Coverage reconciliation**: Compare Boundary List against Structural Map. For constructs containing obvious decision patterns (error handling blocks, state transition methods, integration calls visible from signatures), check whether they were evaluated. Flag constructs that appear to contain decision boundaries but have no corresponding entry in the Boundary List.
    - **Exclusion validation**: For a sample of 2-3 constructs that were implicitly excluded (present in structural map, absent from boundary list, and appear to contain branching logic), verify the exclusion is justified (trivial getter, boilerplate, language idiom).
- **On failure**:
  - **Routes to**: Stage 3 (Identify Boundaries)
  - **Carries**: Specific issues — false positives (boundaries that shouldn't be there), missed boundaries (constructs with decision patterns not evaluated), inaccurate summaries (which boundary, what's wrong)
  - **Max retries**: 2
  - **Escalation**: Present boundary list and flagged issues to user for manual review. User decides which boundaries to keep, add, or remove. Proceed with user-approved list.

---

## Gate: Document Conformance (after Stage 4: Extract Behaviours)

- **Position**: Between Stage 4 (Extract Behaviours) and Stage 5 (Deduplicate Behaviours)
- **Artifact checked**: Each Behaviour Document individually (per-document gate, runs in fan-out)
- **Type**: Schema + Metric + Identity
- **Criteria**:
  - Schema:
    - Document follows `behaviour-template.md` structure
    - All required sections present: classification, description, trigger, actors, contracts, scenarios, traceability
    - `id` is valid `BHV-<hex>` format (4-6 hex characters)
    - `category` is one of: `specified`, `implicit`, `undefined`
    - `status` is `draft`
    - `source` is `implementation`
  - Metric:
    - At least one scenario (happy path with Given/When/Then)
    - At least one code reference in traceability
    - Every non-testable precondition or postcondition has explicit rationale
  - Identity:
    - Code references in the document match the boundary's `location` from the Boundary List (file and function must correspond)
    - `reference_hints` carried forward unchanged from the Boundary List entry
- **On failure**:
  - **Routes to**: Stage 4 (Extract Behaviours) — re-extract only the failing document's boundary, not the entire set
  - **Carries**: Specific validation failures — missing sections, invalid ID format, missing scenario, code reference mismatch with boundary location
  - **Max retries**: 2
  - **Escalation**: Include the malformed document in the output set with `status: draft` and a validation warning appended to its Notes section. The user can manually fix or discard it.

---

## Gate: Deduplication Consistency (after Stage 5: Deduplicate Behaviours)

- **Position**: Between Stage 5 (Deduplicate Behaviours) and Post-Pipeline Consistency Gate
- **Artifact checked**: Deduplicated Behaviour Document Set + Deduplication Report
- **Type**: Schema
- **Criteria**:
  - `total_extracted - duplicates_merged = final_count` (arithmetic consistency)
  - Every `BHV-id` from the input set appears either in the output set or in a merge record's `merged_from` list (no documents silently lost)
  - For each merge: the kept document contains all `code_references` and `test_references` from both the kept and merged documents (traceability links combined)
  - No `BHV-id` appears in both the output set and a `merged_from` list (merged documents are removed, not duplicated)
- **On failure**:
  - **Routes to**: Stage 5 (Deduplicate Behaviours)
  - **Carries**: Specific inconsistencies — count mismatch, missing IDs, lost traceability links, or duplicate IDs
  - **Max retries**: 1
  - **Escalation**: Skip deduplication — pass the full unmerged set from Stage 4 as the pipeline output. Report the deduplication failure to the user.

---

## Gate: Post-Pipeline Consistency (after Deduplication Consistency passes)

- **Position**: After Stage 5, before pipeline output is finalized
- **Artifact checked**: Deduplicated Behaviour Document Set (code references and traceability only) against Codebase Structural Map (from Stage 2)
- **Type**: Semantic (runs in dedicated clean context with behaviour traceability + structural map only)
- **Criteria**:
  - **Stale references**: Every `code_reference` (file:function, file:line) in every behaviour document corresponds to a construct in the Codebase Structural Map. Fail if any reference points to a non-existent construct.
  - **Orphaned behaviours**: Every behaviour document's code references point to files present in the Structural Map. Fail if any reference points to a file not in the map.
  - **Coverage gaps** (advisory, non-blocking): Constructs in the Structural Map that contain decision-boundary patterns (conditional branches, error handling, state transitions visible from signatures and call relationships) but are not referenced by any behaviour document. Reported for user awareness — Stage 3 may have correctly excluded them.
- **On failure (stale or orphaned)**:
  - **Routes to**: Stage 4 (Extract Behaviours) — re-extract only the affected boundaries using corrected locations from the Structural Map
  - **Carries**: List of affected behaviour documents with the invalid references and the closest matching construct from the Structural Map (if any)
  - **Max retries**: 1
  - **Escalation**: Flag affected documents with a traceability warning in their Notes section. Include in output. Report to user.
- **On advisory (coverage gaps)**:
  - Report coverage gap list to user at pipeline completion
  - Do not block output

---

## Ungated Boundaries

### Stage 1 (Gather References) → Stage 2 (Survey Codebase)
No gate. The Reference Index is optional — an empty index is valid. Stage 2 does not consume the Reference Index (it routes to Stages 3 and 4). If individual references fail to load, Stage 1 reports the failure within the index entry rather than producing a malformed artifact. The pipeline degrades gracefully without references.
