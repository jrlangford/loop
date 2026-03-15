---
description: "Workflow: reverse-engineer an existing pipeline into Loop design artifacts, validate the design, generate a clean plugin, audit it, and fix issues. Use on any multi-stage pipeline to rebuild it with proper structure."
argument-hint: "[path-or-description]"
---

# Loop: Reverse-Engineer and Rebuild

Take an existing multi-stage pipeline implementation and rebuild it as a properly structured Loop plugin. Reverse-engineers the implementation into design artifacts, validates the design, generates a clean plugin, audits the result, and fixes issues.

## Workflow Sequence

```
Reverse-engineer → Audit design → Fix design issues → Implement → Audit implementation → Fix implementation issues
```

## How to Run

### Step 1: Check workspace state

Look for `loop-workspace/` in the current project directory.

- **No workspace**: Start from Step 2
- **Workspace exists with design artifacts**: Previous reverse-engineering may be done. Present what exists and ask the user whether to resume from the next incomplete step or start fresh.
- **Workspace exists with `audit.md` or generated plugin**: Later steps may be complete. Present current state and offer resumption.

### Step 2: Reverse-engineer the implementation

`$ARGUMENTS` should identify the implementation. Accepts:
- A directory path (e.g., `skills/` or `src/pipeline/`)
- A description of what to reverse-engineer (e.g., "the DDD skills in this project")
- Nothing — ask the user what to analyze

Read `loop/vocabulary.md` for the full definitions of stages, artifacts, gates, loops, sources, sinks, and stage classification. These definitions guide what to look for.

Read implementation files to understand the pipeline structure. Look for:
- **Stage boundaries** — where one unit of work ends and another begins
- **Artifacts** — what data passes between stages (files, messages, structured objects)
- **Control flow** — what triggers each stage, what order they run
- **Validation** — any checks, gates, or quality assurance between stages
- **Feedback paths** — retries, revision loops, re-runs
- **Context management** — what each stage reads, what it ignores
- **Context isolation** — whether each stage runs in a fresh context (subagent) or shares context with other stages. Also check whether semantic gates run in dedicated clean contexts.
- **External writes** — what data each stage pushes to external systems. These are sinks.

Adapt discovery to the implementation type:
- **Claude Code plugin (Loop structure)**: Look for `.claude-plugin/plugin.json`. Inside, look for `skills/<prefix>/` containing `stages/` and `contracts/`.
- **Claude Code skills (shared resource structure, no plugin)**: Look for a `<prefix>/` directory containing `stages/` and `contracts/` without plugin packaging.
- **Claude Code skills (one skill per stage)**: Each stage is an independent skill with its own `SKILL.md`. Flag schema duplication in synthesis notes.
- **Scripts/code**: Read orchestration logic, function signatures, data flow.
- **Mixed**: Read both skill definitions and code.

Use subagents for parallel discovery when the implementation has many files.

Write design artifacts to `loop-workspace/` in this order:

**`transformation.md`** — Derive from the implementation's overall purpose:
- Input: what the pipeline receives (first stage's input)
- Output: what the pipeline produces (last stage's output)
- Gap: what transformations bridge input to output
- Complexity signals: what the implementation reveals about difficulty

**`stages.md`** — One stage per meaningful unit of work:
- Map each implementation unit to a stage
- Apply the one-verb heuristic: flag stages whose implementation does multiple things
- Note the stage category (Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit)
- Identify source and sink dependencies
- Classify each stage: pure, enriched, emitting, or enriched emitting

**`artifacts.md`** — One artifact per stage boundary:
- Document what actually passes between stages
- Note fields using enums/closed vocabularies versus free text
- Identify candidate identity fields
- Flag fields mixing observation and judgment

**`context-specs.md`** — One spec per stage:
- Document what each stage actually loads into context
- Note the history policy (explicit or implied)
- Document the isolation model: subagent delegation vs shared context

**`workflows/<name>/gates.md`** — One gate per validation checkpoint found.

**`workflows/<name>/loops.md`** — One loop per feedback path.

For each artifact, add `<!-- Synthesis note: ... -->` comments where interpretation was needed.

Present what was reverse-engineered: stage count, artifact count, loops found, flags raised.

### Step 3: Audit the design (shift-left)

Run `/loop:audit-design` against the `loop-workspace/` artifacts produced in Step 2.

This catches design-level problems early — Kitchen Sink stages faithfully reverse-engineered from the original, missing gates, unbounded loops, Telephone Game drift. Fixing these in the design is cheaper than fixing them after implementation.

Present findings to the user. Group by severity (errors first).

### Step 4: Fix design issues

For each ERROR and WARNING from the audit:
- Identify which design artifact needs updating
- Apply the fix to the appropriate `loop-workspace/` file
- For structural issues (Kitchen Sink, Hardcoded Chain): update `stages.md` and cascade to `artifacts.md`, `context-specs.md`
- For loop/gate issues: update the relevant `workflows/<name>/` files
- For drift issues (Telephone Game): update `artifacts.md` to add identity fields, closed vocabularies, source references

After fixes, re-run `/loop:audit-design` to verify. Max 2 audit-fix cycles. If issues persist after 2 cycles, present remaining issues and ask the user whether to proceed to implementation or continue fixing.

### Step 5: Implement

Run `/loop:implement` to generate a clean Loop plugin from the validated design artifacts.

If `$ARGUMENTS` included a prefix or the original implementation suggests one, pass it to implement. Otherwise, let implement derive it from `transformation.md`.

After implementation completes, present the generated plugin structure.

### Step 6: Audit the implementation

Run `/loop:audit-implementation` against the generated plugin directory.

This verifies that the generated plugin correctly reflects the design — contract alignment, context isolation, gate coverage, sink safety.

Present findings to the user.

### Step 7: Fix implementation issues

For each ERROR and WARNING from the audit:
- Determine whether the fix belongs in the generated plugin or back in the design artifacts
- **Implementation fixes**: edit the generated skill files directly
- **Design fixes**: update `loop-workspace/` artifacts and re-run `/loop:implement` for the affected files

After fixes, re-run `/loop:audit-implementation` to verify. Max 2 audit-fix cycles.

### Step 8: Present results

Summarise the rebuild:
- Original implementation: what was analyzed (file count, type)
- Design artifacts: stage count, artifact count, workflow count
- Design audit: issues found and fixed
- Generated plugin: file count, invocation format (`/<prefix>:run`)
- Implementation audit: issues found and fixed
- Any remaining warnings the user should be aware of

## Guidance

- **Describe what is, not what should be** — during reverse-engineering (Step 2). Capture the original implementation faithfully. Improvements happen in Steps 4 and 7.
- **Flag the synthesis gap.** When the implementation doesn't map cleanly to Loop concepts, say so in synthesis notes. Don't force the fit.
- **Implementation units are not always stages.** A helper function called by three stages isn't a stage. A config file read by every stage isn't an artifact. Use judgment.
- **Shift-left.** Design audit (Step 3) is cheap. Fix problems there before spending inference budget on implementation.
- **Don't over-fix.** The goal is a working, properly structured plugin — not a perfect one. Address errors and clear warnings. Leave minor style issues for later iteration.
- **Preserve the original.** This workflow generates a new plugin alongside the original implementation. It does not modify the original.
