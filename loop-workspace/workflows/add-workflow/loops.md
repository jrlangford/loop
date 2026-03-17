# Loop Specifications

## Reasoning Trace

Loop identification is driven entirely by gate failure routes. Each gate with a `routes_to` pointing to a stage that has already executed defines a potential feedback loop. Gates 1 and 2 route back to Pipeline Input (an external source, not a pipeline stage), so they do not form loops. Gates 3 through 7 all route to pipeline stages, creating five correction loops. All loops are balancing — each corrects toward satisfying specific gate criteria rather than amplifying output. The Write Phase is handled inline by the orchestrator after Gate 7 passes (with Human confirmation), so no Emit stage or emission correction loop is needed — git provides rollback safety. Hard caps are set at 2 for most loops and 3 for the Validation-Report loop (which has the most complex failure surface and routes to two different upstream stages).

## Loops

### 1. Extraction-Correction-Loop

- **Type**: Balancing
- **Stages Involved**: [Extract-Existing-Design] -> [Existing-Design-Inventory-Gate] -> [Extract-Existing-Design]
- **Purpose**: Correct incomplete or structurally invalid extraction of the existing pipeline design until the inventory satisfies schema and metric criteria (unique names, complete fields, valid references).
- **Pattern**: Evaluator-optimizer — the gate evaluates structural completeness and metric constraints; the Extract stage re-extracts with attention to the specific failures identified.
- **Termination**:
  - **Semantic**: The Existing-Design-Inventory passes all schema and metric criteria: every stage entry has complete fields, all names are unique, and all workflow stage references resolve.
  - **Hard Cap**: 2
- **Degradation Detector**: Track the number of schema/metric violations reported by the gate across iterations. If violation count does not decrease between consecutive iterations, stop and use the iteration with the fewest violations.
- **Best Iteration Selection**: Select the iteration with the fewest combined schema and metric violations. On tie, prefer the later iteration (more recent attempt with corrective feedback).

### 2. Reuse-Analysis-Correction-Loop

- **Type**: Balancing
- **Stages Involved**: [Analyze-Reuse] -> [Reuse-Analysis-Report-Gate] -> [Analyze-Reuse]
- **Purpose**: Correct reuse analysis verdicts that fail schema or semantic validation — misclassified stages, uncovered requirements, or missing verdicts — until the analysis is sound.
- **Pattern**: Evaluator-optimizer — the gate evaluates both structural completeness (schema) and judgment quality (semantic check in clean context); the Analyze-Reuse stage revises verdicts based on the specific failures.
- **Termination**:
  - **Semantic**: The Reuse-Analysis-Report passes all schema and semantic criteria: every existing stage has exactly one verdict with valid rationale, capability gaps cover all unaddressed key requirements, and each reuse-as-is verdict is justified by compatible contract shapes and domain assumptions.
  - **Hard Cap**: 2
- **Degradation Detector**: Track the count of semantic and schema failures across iterations. If the total failure count does not decrease between consecutive iterations, stop and use the best iteration. Pay special attention to semantic failures — a reuse verdict flip that resolves one issue but introduces another indicates oscillation.
- **Best Iteration Selection**: Select the iteration with the fewest semantic failures (prioritize judgment quality over schema completeness). On tie in semantic failures, prefer fewer schema failures. On full tie, prefer the later iteration.

### 3. Stage-Definition-Correction-Loop

- **Type**: Balancing
- **Stages Involved**: [Define-New-Stages] -> [New-Stage-Definitions-Gate] -> [Define-New-Stages]
- **Purpose**: Correct new stage definitions that have naming collisions, invalid references, missing fields, or structural issues until all definitions conform to the contract.
- **Pattern**: Evaluator-optimizer — the gate evaluates schema conformance and metric constraints (no collisions, valid gap references); the Define stage revises definitions based on specific failures.
- **Termination**:
  - **Semantic**: All new stage definitions pass schema validation (verb-noun names, single-verb intents, complete fields) and metric validation (no name collisions, valid gap references, idempotency markers on Emit-category stages).
  - **Hard Cap**: 2
- **Degradation Detector**: Track the number of schema and metric violations across iterations. If violation count does not decrease between consecutive iterations, stop and use the iteration with the fewest violations.
- **Best Iteration Selection**: Select the iteration with the fewest total violations. On tie, prefer the later iteration.

### 4. Workflow-Configuration-Correction-Loop

- **Type**: Balancing
- **Stages Involved**: [Compose-Workflow] -> [New-Workflow-Configuration-Gate] -> [Compose-Workflow]
- **Purpose**: Correct workflow gate and loop definitions that reference non-existent stages, have name collisions, or fail semantic checks (untestable criteria, reinforcing loops without balancing mechanisms).
- **Pattern**: Evaluator-optimizer — the gate evaluates schema validity and semantic soundness (in clean context); the Compose stage revises configuration based on specific failures.
- **Termination**:
  - **Semantic**: The workflow configuration passes all schema and semantic criteria: all stage references resolve, no gate name collisions with existing workflows, gate criteria are testable, loop triggers describe observable conditions, and no reinforcing loop lacks a balancing mechanism.
  - **Hard Cap**: 2
- **Degradation Detector**: Track the count of schema and semantic failures across iterations. If the total count does not decrease between consecutive iterations, stop and use the best iteration.
- **Best Iteration Selection**: Select the iteration with the fewest combined schema and semantic failures. On tie, prefer the later iteration.

### 5. Validation-Correction-Loop

- **Type**: Balancing
- **Stages Involved**: [Validate-Consistency] -> [Validation-Report-Gate] -> [Compose-Workflow] or [Define-New-Stages] (route depends on inconsistency type)
- **Purpose**: Resolve cross-workflow inconsistencies detected by the validation stage. Gate/loop inconsistencies route to Compose-Workflow; naming collisions and artifact structure issues route to Define-New-Stages. After upstream correction, the pipeline re-executes through to Validate-Consistency.
- **Pattern**: Evaluator-optimizer — the validation stage evaluates cross-workflow consistency; the upstream stage (Compose-Workflow or Define-New-Stages) optimizes based on the specific inconsistencies reported.
- **Termination**:
  - **Semantic**: The Validation-Report's `overall_status` is `pass` — all cross-workflow consistency checks succeed with no error-severity inconsistencies.
  - **Hard Cap**: 3
- **Degradation Detector**: Track the total number of inconsistencies (both error and warning severity) across iterations. If the error-severity count does not decrease between consecutive iterations, stop and use the iteration with the fewest error-severity inconsistencies. Also monitor for oscillation: if an inconsistency is resolved but a new one of the same scope appears, flag potential circular correction.
- **Best Iteration Selection**: Select the iteration with zero error-severity inconsistencies if one exists. Otherwise select the iteration with the fewest error-severity inconsistencies. On tie, prefer the iteration with fewer warning-severity inconsistencies, then prefer the later iteration.

## Anti-Pattern Check

- **Echo Chamber**: Not applicable. All loops are balancing (correcting toward gate criteria), not reinforcing. No loop amplifies output across iterations.
- **Phantom Feedback**: Low risk. All gate criteria are specific and testable (schema checks, metric checks, semantic checks with clean-context evaluation). The Reuse-Analysis-Report-Gate's semantic check is the most subjective, but it runs in an isolated context with explicit evaluation criteria, reducing the chance of rubber-stamping.
- **Ouroboros**: The Validation-Correction-Loop (Loop 5) routes to either Compose-Workflow or Define-New-Stages, which could trigger their own correction loops (Loops 3 and 4) before re-entering validation. This creates nested loops but not circular dependencies — Loop 5 always routes upstream, and Loops 3/4 always route to themselves. The hard caps (Loop 3: 2, Loop 4: 2, Loop 5: 3) bound the worst case to 3 x (1 + 2) = 9 iterations through the validation path, which is within acceptable limits.
