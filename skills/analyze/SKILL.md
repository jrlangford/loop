---
name: analyze
description: "Workflow: analyze an existing pipeline implementation — reverse-engineer it into Loop design artifacts and audit it for anti-patterns and structural issues. Use on any multi-stage pipeline to understand and evaluate it."
argument-hint: "[path-or-description]"
---

# Loop: Analyze Implementation Workflow

Orchestrate the implementation-backward workflow: reverse-engineer an existing pipeline into Loop vocabulary, then review and audit it.

## Workflow Sequence

```
/loop:reverse → /loop:review → /loop:audit
```

## How to Run

### Step 1: Check workspace state

Look for `loop-workspace/` in the current project directory.

- **No workspace**: Start from `/loop:reverse` (Step 2)
- **Workspace exists with design artifacts but no `review.md` or `audit.md`**: The reverse step may already be done. Confirm with the user, then proceed to review/audit.
- **Workspace exists with `review.md` and/or `audit.md`**: Previous analysis may exist. Ask the user if they want to re-analyze or review existing findings.

### Step 2: Reverse-engineer

Run `/loop:reverse` with `$ARGUMENTS` (the path or description of the implementation).

This produces design artifacts in `loop-workspace/` — the implementation described in Loop vocabulary.

After completion, ask the user to review the synthesized artifacts. Flag any synthesis notes (where the mapping required interpretation). Pay particular attention to whether the reverse step captured sink dependencies — any external writes the implementation makes (API calls, git pushes, Slack messages, database inserts).

### Step 3: Review the design

Run `/loop:review` against the reverse-engineered artifacts.

This checks the *design* for anti-patterns and structural issues. Findings here indicate problems in how the implementation is structured, expressed in Loop terms.

### Step 4: Audit the implementation

Run `/loop:audit` with the same path/description used in Step 2.

This checks the *implementation directly* and, since design artifacts now exist from Step 2, also reports design–implementation discrepancies. In a reverse-engineer-then-audit flow, discrepancies should be minimal — they indicate places where the reverse-engineering didn't fully capture the implementation's behavior.

### Step 5: Present combined findings

Combine findings from review and audit into a unified picture:
- **Design-level issues** (from `/loop:review`): structural problems visible in the pipeline's architecture
- **Implementation-level issues** (from `/loop:audit`): problems visible only by reading the actual code — including sink safety (idempotency, pre-emit gating) and missing precondition checks
- **Discrepancies** (from `/loop:audit`): gaps between the reverse-engineered model and the implementation

Suggest next steps:
- Use individual `/loop:*` design skills to address specific design-level findings
- Fix implementation issues directly in the code
- Re-run `/loop:analyze` after fixes to verify

## Guidance

- **Review and audit are complementary, not redundant.** Review checks the design abstraction; audit checks the implementation reality. The same pipeline can pass review but fail audit (good architecture, sloppy implementation) or pass audit but fail review (solid code, poor structure).
- **Pass the same target to reverse and audit.** They should analyze the same implementation files for findings to be comparable.
- **Discrepancies in this workflow are a quality signal for `/loop:reverse`.** If many discrepancies appear, the reverse-engineering was imprecise — the synthesis notes should explain why.
