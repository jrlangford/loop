# Stage: Extract Behaviours

## Intent

Produce one behaviour document per decision boundary.

## Category and Posture

**Category**: Transform
**Posture**: Convert representations. Input (boundary entry + source code) and output (behaviour document) are structurally different. The boundary entry is a pointer; the behaviour document is a complete specification.

## Input

Read a single boundary entry from the Boundary List. The orchestrator provides:
- The specific boundary entry (from `autodoc-workspace/boundary-list.md`)
- The boundary's `id` for workspace path construction

Read `autodoc/contracts/boundary-list.md` for the boundary entry schema.
Read `autodoc/contracts/behaviour-document.md` for the output schema.

If `reference_hints` is non-empty on this boundary, also read the matching entries from `autodoc-workspace/reference-index.md` (only the entries whose `source_locator` matches the hints — not the full index).

## Output

Write one behaviour document to `autodoc-workspace/behaviours/BHV-<hex>.md`.

The file follows the behaviour template format below.

## Steps

1. Read the source code at the boundary's location (file, function, line range) using the Read tool. Read enough surrounding context to understand the function's full logic (typically the entire function).
2. If the Codebase Structural Map (from `autodoc-workspace/structural-map.md`) indicates a test file for this boundary's file, read the test file and search for test functions referencing the boundary's function/method name.
3. If `reference_hints` is non-empty, read the matching Reference Index entries to understand the specified intent.
4. Extract contracts:
   - **Preconditions**: What must be true before the decision point. Look for guard clauses, validation, assertions, parameter type checks.
   - **Postconditions**: What the code guarantees after each branch. Look for return values, state mutations, external calls.
   - **Invariants**: What remains true regardless of which branch is taken.
   - **Failure modes** (best-effort): What happens when preconditions are met but execution fails.
5. Use test assertions as corroborating evidence: test setup suggests preconditions, assertions suggest postconditions. Tests don't replace reasoning — they corroborate it.
6. Generate at least one scenario (happy path required, edge cases best-effort):
   - Use Given/When/Then format
   - Make scenarios concrete with specific values where possible
7. Assign classification:
   - `specified`: `reference_hints` is non-empty AND the behaviour is clearly mandated by the reference
   - `implicit`: behaviour follows common conventions or patterns but has no reference backing
   - `undefined`: cannot confidently classify
8. Assign significance based on impact:
   - `critical`: failure causes data loss, security breach, or system-wide outage
   - `important`: failure degrades user experience or breaks a workflow
   - `minor`: cosmetic or low-impact
9. Generate a non-sequential ID: `BHV-<4-6 hex chars>`
10. Set `source: "implementation"` and `status: "draft"` (always)
11. Record traceability: code references (file:function or file:line), test references (if found), reference_hints (carried forward unchanged from boundary entry)

## Sources

| Source | Access method | Required? |
|--------|--------------|-----------|
| Local filesystem | Read tool | Yes — source code and test files |

## Sinks

None.

## Behaviour Template

```markdown
## `[BHV-<hex>]` Behaviour Title

### Classification

| Field          | Value |
|----------------|-------|
| **Category**   | `specified` · `implicit` · `undefined` |
| **Source**      | `implementation` |
| **Significance** | `critical` · `important` · `minor` |
| **Status**     | `draft` |

### Description

<!-- What does the system do, and why does it matter?
     Focus on the decision, not the mechanism. -->

### Trigger

<!-- What event or condition initiates this behaviour? -->

### Actors

<!-- Who or what participates? Users, services, external systems. -->

### Contracts

#### Preconditions
- <testable condition, or marked non-testable with rationale>

#### Postconditions
- <testable condition, or marked non-testable with rationale>

#### Invariants
- <condition that holds throughout>

#### Failure modes *(optional)*

| Condition | System response | Postcondition |
|-----------|-----------------|---------------|

### Scenarios

#### Happy path

> **Given** ...
> **When** ...
> **Then** ...

#### Edge cases *(optional)*

> **Given** ...
> **When** ...
> **Then** ...

### Traceability

#### Code references
- <file:function or file:line>

#### Test references
- <test file:test function>

#### Reference hints
- <source_locator values from Reference Index>

### Notes *(optional)*
```

## Behaviour Example

For reference, here is a complete filled-in behaviour document:

```markdown
## `[BHV-7c2a]` Payment retry with escalating backoff

### Classification

| Field          | Value |
|----------------|-------|
| **Category**   | `specified` |
| **Source**      | `implementation` |
| **Significance** | `critical` |
| **Status**     | `draft` |

### Description

When a payment charge attempt fails with a retryable error, the system retries up to three times with exponentially increasing delays before marking the payment as failed and notifying the customer.

### Trigger

A payment gateway returns a retryable error code (gateway_timeout, rate_limited, temporary_unavailable).

### Actors

- **Payment Service** — initiates and retries charge attempts
- **Payment Gateway** (external) — processes the charge

### Contracts

#### Preconditions
- Payment has a valid idempotency key assigned before the first attempt
- The error code returned by the gateway is in the retryable set

#### Postconditions
- On success: payment status is `charged`, exactly one charge appears
- On exhausted retries: payment status is `failed`, customer notified

#### Invariants
- The idempotency key remains constant across all retry attempts

### Scenarios

#### Happy path

> **Given** a payment of $49.99 with idempotency key `pay_8f3a`
> **When** the first charge attempt returns `gateway_timeout`
> **And** the second attempt (after 1s delay) returns `200 OK`
> **Then** payment status is `charged`
> **And** exactly one charge of $49.99 appears

### Traceability

#### Code references
- services/payment/charge.go:RetryCharge

#### Test references
- services/payment/charge_test.go:TestRetryCharge_ExponentialBackoff

#### Reference hints
- docs/payment-design.md
```

## Guidance

- **Do** read enough surrounding code context to understand the full decision — don't extract contracts from the 10-line evidence snippet alone
- **Do** use test assertions as corroborating evidence for contracts
- **Do** make scenarios concrete with specific values
- **Do** carry forward `reference_hints` unchanged from the boundary entry
- **Do** mark non-testable conditions explicitly with rationale (e.g., "Not testable: no side effects in external system — would require integration test with external service")
- **Do not** reference the structural map, boundary list, or other pipeline artifacts in the behaviour document — it must be self-contained
- **Do not** use the `emergent` category — it is intentionally omitted from this pipeline
- **Do not** generate sequential IDs — use random hex to avoid reordering pressure
- **Do not** read other boundary entries or other behaviour documents — each extraction is independent
