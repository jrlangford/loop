# Behaviour Document Template

## Usage

Each file documents **one behaviour** — an observable, testable decision the system makes that a stakeholder would notice if it broke. Copy this template and fill in the sections. Fields marked *(optional)* can be omitted when not applicable.

---

## `[BHV-<short-hash>]` Behaviour Title

<!-- ID format: BHV- followed by 4-6 hex chars (e.g., BHV-a3f7, BHV-0c91e2).
     Generate with: printf 'BHV-%04x' $((RANDOM % 65536))
     Non-sequential to avoid reordering pressure. -->

### Classification

| Field          | Value |
|----------------|-------|
| **Category**   | `specified` · `emergent` · `implicit` |
| **Source**      | `design` · `implementation` |
| **Significance** | `critical` · `important` · `minor` |
| **Status**     | `draft` · `validated` · `implemented` · `deprecated` |

<!-- Category definitions:
  - specified:  directly traceable to a requirement or user story
  - emergent:   arises from interaction between components, not owned by any single one
  - implicit:   assumed by convention but never formally specified (high documentation-gap risk)

  Source:
  - design:         derived from requirements/user stories → informs test creation
  - implementation: reverse-engineered from code/tests → surfaces undocumented decisions

  Significance (granularity filter):
  - critical:  failure causes data loss, security breach, or system-wide outage
  - important: failure degrades user experience or breaks a workflow
  - minor:     cosmetic or low-impact; document only if non-obvious
-->

### Description

<!-- One or two paragraphs. What does the system do, and why does it matter?
     Focus on the *decision* the system makes, not the mechanism. -->

### Trigger

<!-- What event or condition initiates this behaviour? -->

### Actors

<!-- Who or what participates? Users, services, external systems. -->

### Contracts

#### Preconditions
<!-- What must be true *before* the behaviour executes? -->

-

#### Postconditions
<!-- What must be true *after* the behaviour completes (success case)? -->

-

#### Invariants
<!-- What must remain true *throughout* execution? -->

-

#### Failure modes *(optional)*
<!-- What happens when preconditions are met but execution fails?
     Each failure mode is a postcondition of the error path. -->

| Condition | System response | Postcondition |
|-----------|-----------------|---------------|
|           |                 |               |

### Scenarios

<!-- Concrete examples that illustrate the behaviour. These map directly to test cases. -->

#### Happy path

> **Given** ...
> **When** ...
> **Then** ...

#### Edge cases *(optional)*

> **Given** ...
> **When** ...
> **Then** ...

### Traceability

#### Requirements *(when source = design)*
<!-- Links to user stories, requirements, or product specs that mandate this behaviour. -->

-

#### Code references *(when source = implementation)*
<!-- Where in the codebase is this behaviour implemented?
     Use file:line or file:function format. -->

-

#### Test references
<!-- Existing tests that verify this behaviour, or test IDs to be created. -->

-

### Notes *(optional)*

<!-- Design rationale, known debt, relationship to other behaviours,
     or anything that wouldn't survive as a code comment. -->

---

## Template guidance

### When to create a behaviour document

Create one when the system makes a **decision at a boundary** that:
1. A user, operator, or downstream service would notice if it changed
2. Involves choosing between two or more outcomes
3. Is not obvious from reading a single function signature

**Do not create one for**: pure data transformations, getters/setters, formatting, or anything where the function signature fully describes the behaviour.

### Emergent behaviours — when to document

Emergent behaviours are worth documenting when:
- They cross service or module boundaries
- No single component "owns" the outcome
- The behaviour has failed before (or plausibly could) due to a change in one component that didn't account for the interaction

Examples: retry × timeout = circuit breaker; cache + write = stale read window; auth + rate-limit = lockout amplification.

### Two-way bridge workflow

```
Design → Behaviour doc → Tests → Implementation
                ↑                       |
                └───────────────────────┘
          (reverse-engineer from code)
```

**Design-first**: fill requirements traceability, write scenarios as acceptance criteria, derive test cases, then implement. Mark `source: design`.

**Code-first**: inspect implementation, extract the decision being made, document pre/post/invariants, note missing tests. Mark `source: implementation`. These documents surface **documentation gaps** — implicit behaviours that were never specified but exist in code.
