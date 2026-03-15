---
description: "Audit an existing implementation against Loop framework principles — anti-pattern checks, structural analysis, and contract alignment. Reads implementation files directly. If loop-workspace design artifacts exist, also reports design-implementation discrepancies. Use on any multi-stage pipeline."
argument-hint: "[path-or-description]"
---

# Loop: Audit Implementation

Check an existing multi-stage pipeline implementation against Loop framework principles and anti-patterns. Unlike `/loop:audit-design` (which checks design artifacts), this skill reads the implementation directly.

If `loop-workspace/` design artifacts exist, the audit also compares implementation behavior against design intent and reports discrepancies.

## Input

`$ARGUMENTS` should identify the implementation to audit. Accepts:
- A directory path (e.g., `skills/` or `src/pipeline/`)
- A description of what to audit (e.g., "the DDD skills in this project")
- Nothing — ask the user what to audit

## What You Produce

A single file: `loop-workspace/audit.md` — findings from anti-pattern checks, structural analysis, and (if design artifacts exist) design-implementation discrepancies.

This skill does not create design artifacts. To get an implementation into Loop vocabulary first, run `/loop:reverse`.

## How to Run

### Step 1: Read the implementation

Read implementation files to understand what the pipeline actually does. Adapt to the implementation type:
- **Claude Code skills**: Read each `SKILL.md` and supporting docs.
- **Scripts/code**: Read orchestration logic, function signatures, data flow.
- **Mixed**: Read both skill definitions and code.

Use subagents for parallel discovery when the implementation has many files.

Build a working understanding at both levels:

**Stage level**: What transformation units exist, what artifacts pass between them, what each stage loads into context, what external sources each stage reads from, what external sinks each stage writes to.

**Workflow level**: How stages are sequenced, where gates are placed, what feedback loops exist, what iteration bounds and termination conditions are configured.

### Step 2: Check for design artifacts

Look for `loop-workspace/` in the current project directory. Check for:

**Stage-level artifacts**: `transformation.md`, `stages.md`, `artifacts.md`, `context-specs.md`

**Workflow-level artifacts**: `workflows/<name>/gates.md`, `workflows/<name>/loops.md`

If design artifacts exist, note them — they'll be used for discrepancy analysis in Step 5.

### Step 3: Run anti-pattern checks

Read `loop/anti-patterns.md` for the full anti-pattern catalogue (8 anti-patterns with definitions, check criteria, and severity guidelines).

Apply each anti-pattern check to the **implementation directly**. Implementation-level checks catch things design review misses — a design might specify clean stage boundaries while the implementation has them coupled, or a design might specify gates that the implementation doesn't enforce.

For each anti-pattern, examine the actual code, skills, or scripts. Report findings with the severity levels specified in the catalogue.

The coverage requirement applies: address all 8 anti-patterns by name in the report.

### Step 4: Run structural quality checks

Read `loop/quality-checks.md` for the full list of structural quality dimensions.

Apply each quality check to the **implementation**. For each dimension, examine how the implementation actually behaves:

**Contract alignment**: Does what Stage A produces actually match what Stage B expects? Are there implicit format assumptions?

**Error recovery**: What happens when a stage fails mid-execution? Is there checkpointing?

**Context window budget**: Estimate actual token usage per stage based on files loaded.

**Source dependencies**, **sink dependencies**, **precondition checks**, **context isolation**, **stage/workflow separation**, **implementation structure**, **loop safety**, **stochastic validation**, **handoff drift resilience** — apply the check criteria from `loop/quality-checks.md` to the implementation.

### Step 5: Compare against design (if artifacts exist)

If `loop-workspace/` contains design artifacts, compare each against what the implementation actually does. Check both levels:

- **Stage-level**: Do the implemented stages match `stages.md`? Do the actual data contracts match `artifacts.md`? Do context loads match `context-specs.md`?
- **Workflow-level**: Do the implemented gates match `workflows/<name>/gates.md`? Do the actual feedback loops match `workflows/<name>/loops.md`?

For each discrepancy, classify it:

| Type | Meaning | Resolution direction |
|------|---------|---------------------|
| **Design drift** | Implementation evolved past the design | Update the design artifact |
| **Implementation gap** | Design specifies something the implementation doesn't do | Implement it, or remove from design |
| **Structural mismatch** | Same thing modeled differently | Decide which is correct, align the other |
| **Undesigned behavior** | Implementation does something design doesn't mention | Add to design if intentional, remove if accidental |

Skip this section entirely if no design artifacts exist.

### Step 6: Write the audit report

Write `loop-workspace/audit.md`:

```markdown
# Pipeline Implementation Audit

## Summary
- **Implementation type**: [Skills | Agent framework | Scripts | Mixed]
- **Files examined**: [count and key files]
- **Stages identified**: [count]
- **Issues found**: [count by severity]
- **Design artifacts found**: [Yes — list files | No]

## Issues

### [ERROR | WARNING | INFO]: [Issue title]
- **Location**: [Implementation file and section]
- **Anti-pattern**: [Name, if applicable]
- **Finding**: [What's wrong — reference the actual implementation]
- **Suggested fix**: [How to address it]
- **Loop skill**: [Which /loop:* skill's output would guide the fix, if any]

### [Next issue]
...

## Design–Implementation Discrepancies
<!-- Only if design artifacts exist. Omit section entirely otherwise. -->

### [DRIFT | GAP | MISMATCH | UNDESIGNED]: [Title]
- **Design says**: [What the design artifact specifies]
- **Implementation does**: [What the implementation actually does]
- **Artifact**: [Which loop-workspace file]
- **Resolution**: [Update design | Implement | Align | Add or remove]

### [Next discrepancy]
...

## Implementation Health
<!-- Overall assessment. Strengths and risks. Be direct. -->
```

### Step 7: Present findings

Walk the user through issues by severity (errors first). For each, reference the specific implementation file.

If discrepancies were found, present them grouped by resolution direction.

## Guidance

- **Read the implementation, not just the structure.** Pay attention to edge cases, error paths, and implicit behavior.
- **Don't penalize non-Loop implementations for not being Loop.** Focus on whether the *underlying patterns* are sound, not whether Loop vocabulary was used.
- **Implementation context matters.** A human-gated pipeline has different risks than a fully autonomous one. Calibrate severity accordingly.
- **Be direct about strengths too.** If the implementation handles something well, say so.
