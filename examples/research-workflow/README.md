# Research Validation Pipeline — Worked Example

This example demonstrates the full Loop framework lifecycle: designing a multi-stage LLM pipeline interactively, then implementing it as Claude Code skills. The pipeline validates research claims in markdown documents through parallel independent review, agreement comparison, and iterative reconciliation.

## How This Was Built

The design was produced through a guided conversation between a designer and `/loop-wf-design`, which orchestrated the phase skills in sequence. Each phase proposed a design, the designer reviewed it, and the phase wrote its artifact only after approval.

### Step 1: Define the transformation

**Skill:** `/loop-wf-design` triggered `/loop-define`

The designer described the goal: *"a research validation workflow that launches multiple agents that review claims and then compare their findings, providing feedback to the reviewer."*

`/loop-define` asked clarifying questions about input format, output structure, number of parallel agents, feedback round limits, and external dependencies. The designer specified:
- Markdown documents as input
- 3 parallel reviewer agents with web search access
- Agreement gates with up to 3 reconciliation rounds
- Unresolvable claims explicitly marked rather than forced to consensus
- No external sinks — the validation report is the final output

After the designer confirmed the answers, `/loop-define` wrote the transformation definition.

**Produced:** `loop-workspace/transformation.md`

### Step 2: Decompose into stages

**Skill:** `/loop-decompose`

`/loop-decompose` proposed a 6-stage decomposition using the one-verb heuristic, explaining why each stage was separate (e.g., Extract and Classify split because they require different analytical postures) and why certain merges were rejected (e.g., citation checking embedded in Verify rather than split out, to avoid duplicating web lookups). The designer approved.

| Stage | Verb | Description |
|-------|------|-------------|
| Extract Claims | Extract | Identify individual claims and citations from prose |
| Classify Claims | Evaluate | Tag each claim as factual, analytical, or opinion |
| Verify Claims (×3) | Enrich | 3 independent agents research and assess each claim via web search |
| Compare Assessments | Evaluate | Identify agreement/disagreement across reviewers |
| Reconcile Disagreements | Refine | Re-examine disputed claims with additional evidence |
| Compile Report | Synthesise | Assemble final scored validation report |

**Produced:** `loop-workspace/stages.md`

### Step 3: Specify artifacts

**Skill:** `/loop-artifacts`

`/loop-artifacts` proposed the typed intermediate representations and asked the designer to confirm 5 key design decisions: claim identity fields, separation of observation from judgment in reviewer assessments, enum-based agreement status, reasoning trace policies, and the loopback artifact structure for the reconciliation cycle. The designer approved all 5.

**Produced:** `loop-workspace/artifacts.md`

### Step 4: Budget context

**Skill:** `/loop-context`

`/loop-context` produced per-stage context budgets — what goes in each stage's context window (germane load), what stays out (extraneous), and load assessments. This phase ran without requiring human input beyond approval.

**Produced:** `loop-workspace/context-specs.md`

### Step 5: Place gates

**Skill:** `/loop-gates research-validation`

The designer named the workflow "research-validation." `/loop-gates` proposed 5 gates and explained each: why it was needed, what type of check it performed, and what one ungated boundary was deliberately left open (Extract → Classify, because misclassification is low-cost). The designer approved.

**Produced:** `loop-workspace/workflows/research-validation/gates.md`

### Step 6: Design feedback loops

**Skill:** `/loop-feedback research-validation`

`/loop-feedback` identified 4 feedback loops — 1 primary consensus loop (Compare ⇄ Reconcile) and 3 gate-retry balancing loops — with termination conditions, degradation detectors, and anti-pattern risk assessments for each. The designer approved.

**Produced:** `loop-workspace/workflows/research-validation/loops.md`

### Step 7: Review

**Skill:** `/loop-review`

`/loop-review` checked the complete design against all 8 anti-patterns. Result: 0 errors, 0 warnings, 3 info items. One info item flagged the missing preconditions for web search. The designer agreed to add preconditions, and `/loop-wf-design` wrote the preconditions file.

**Produced:** `loop-workspace/workflows/research-validation/review.md`, `loop-workspace/workflows/research-validation/preconditions.md`

### Step 8: Implement

**Skill:** `/loop-implement`

The designer invoked `/loop-implement`. It proposed the prefix "claim-val" — the designer overrode this to "research-validation" to match the workflow name. `/loop-implement` then generated:

- **Shared resources** (`skills/research-validation/`) — 6 stage instruction files and 8 artifact contract files
- **Orchestrator skill** (`skills/research-validation-run/SKILL.md`) — the single entry point that sequences stages via subagents, enforces gates, and manages the consensus feedback loop

**Produced:** everything under `skills/`

## Directory Structure

```
research-workflow/
│
├── dodgy-product-development-best-practices.md   # Test input — intentionally flawed research document
│
├── loop-workspace/                               # Design artifacts (produced by Loop design skills)
│   ├── transformation.md                         #   Transformation definition (input/output/gap)
│   ├── stages.md                                 #   6-stage decomposition
│   ├── artifacts.md                              #   Typed intermediate representations
│   ├── context-specs.md                          #   Per-stage context budgets
│   └── workflows/
│       └── research-validation/
│           ├── gates.md                          #   Validation checkpoints between stages
│           ├── loops.md                          #   Feedback loop definitions (consensus loop)
│           ├── preconditions.md                  #   Pre-run checks (web search availability)
│           └── review.md                         #   Design review — passed all anti-pattern checks
│
├── skills/                                       # Implemented Claude Code skills (produced by /loop-implement)
│   ├── research-validation/                      #   Shared resources (stages + contracts)
│   │   ├── stages/                               #   Per-stage prompt instructions
│   │   │   ├── extract-claims.md
│   │   │   ├── classify-claims.md
│   │   │   ├── verify-claims.md
│   │   │   ├── compare-assessments.md
│   │   │   ├── reconcile-disagreements.md
│   │   │   └── compile-report.md
│   │   └── contracts/                            #   Artifact schemas (input/output specs)
│   │       ├── _pipeline.md
│   │       ├── source-document.md
│   │       ├── claim-list.md
│   │       ├── typed-claim-list.md
│   │       ├── reviewer-assessment.md
│   │       ├── agreement-report.md
│   │       ├── reconciled-assessments.md
│   │       └── validation-report.md
│   └── research-validation-run/                  #   Orchestrator skill (the runnable entry point)
│       └── SKILL.md
│
└── research-validation-workspace/                # Runtime artifacts (not checked in — generated per run)
```

## Pipeline Flow

```
Source Document → Extract Claims → Classify Claims → Verify Claims (×3 parallel)
    → Compare Assessments ⇄ Reconcile Disagreements (up to 3 rounds)
    → Compile Report → Validation Report
```

## Running It Yourself

### 1. Install the skills

From the `examples/research-workflow/` directory, symlink the generated skills so Claude Code discovers them:

```sh
cd examples/research-workflow
mkdir -p .claude/skills
ln -sfn "$(pwd)/skills/research-validation" .claude/skills/research-validation
ln -sfn "$(pwd)/skills/research-validation-run" .claude/skills/research-validation-run
```

Claude Code walks up parent directories when discovering skills, so the example's `.claude/skills/` coexists with the parent project's.

### 2. Make Claude Code discover the new skills

Claude Code monitors `.claude/skills/` for changes via live detection, so newly symlinked skills should appear automatically. If the skill doesn't show up, type `/` and check the skills list — if it's missing, restart Claude Code (`Ctrl+C` then `claude`).

### 3. Run the pipeline

```
/research-validation-run
```

When prompted, point it at a markdown document to validate. The included `dodgy-product-development-best-practices.md` is a good test — it's deliberately full of overstated claims and miscited sources.

### Prerequisites

- **Web search access** — the pipeline uses web search for claim verification. The orchestrator checks this as a precondition before starting.
- **Loop framework skills are not required** — the generated pipeline skills are self-contained. You only need the Loop framework skills (`just install` from the project root) if you want to modify the pipeline design.
