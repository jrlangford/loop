---
description: "Workflow: extract a rich pipeline description from an existing implementation, then run it through the design and implement pipeline to produce a clean Loop plugin. Use on any multi-stage pipeline to rebuild it properly."
argument-hint: "[path-or-description]"
---

# Loop: Reverse-Engineer and Rebuild

Take an existing multi-stage pipeline implementation, extract a rich transformation description in Loop vocabulary, then feed it through the standard design and implementation pipeline to produce a clean, properly structured Loop plugin.

## Workflow Sequence

```
Extract description → Classify & reconcile → /loop:design → /loop:implement → /loop:audit-implementation → Fix issues
```

## How to Run

### Step 1: Identify the implementation

`$ARGUMENTS` should identify the implementation. Accepts:
- A directory path (e.g., `skills/` or `src/pipeline/`)
- A description of what to reverse-engineer (e.g., "the DDD skills in this project")
- Nothing — ask the user what to analyze

### Step 2: Extract the transformation description

Read `loop/vocabulary.md` for the full definitions of stages, artifacts, gates, loops, sources, sinks, and stage classification. Use these definitions to map what you find in the implementation to Loop concepts.

Read the implementation files thoroughly. Adapt to the implementation type:
- **Claude Code plugin**: Look for `.claude-plugin/plugin.json`, `skills/<prefix>/stages/`, `skills/<prefix>/contracts/`, orchestrator skills.
- **Claude Code skills (one per stage)**: Each stage is an independent skill with its own `SKILL.md`.
- **Scripts/code**: Read orchestration logic, function signatures, data flow.
- **Mixed**: Read both skill definitions and code.

Use subagents for parallel discovery when the implementation has many files.

Produce a rich transformation description that captures everything from the source implementation. The extraction must be **lossless** — every stage, document, skill, and behavioral rule in the source must appear in the extraction output. What the extraction misses cannot be recovered.

The description must cover:

**Overall transformation:**
- What the pipeline takes as input (format, variability)
- What it produces as output (format, quality criteria)
- The gap between input and output — what work bridges them

**Stages discovered** (mapped to Loop vocabulary):
- Each stage's intent, mapped to a Loop category (Extract, Enrich, Transform, Evaluate, Synthesise, Refine, Emit)
- What each stage actually does — the transformation logic, not just a label
- Dependencies between stages — what feeds what
- Stages that violate the one-verb heuristic (flag, but still capture what they do)
- **Every stage found in the source must appear here.** If a stage seems optional, additive, or secondary, include it and tag it `<!-- Optional: [rationale] -->`. Never silently omit a stage.

**Sources and sinks:**
- External resources stages read from (web, APIs, MCP servers, databases, filesystem)
- External targets stages write to (APIs, git, Slack, databases, notification services)
- How the implementation handles source unavailability
- Idempotency strategies for sinks (if any)

**Artifacts between stages:**
- What data passes between stages (structure, key fields)
- Which fields use enums/closed vocabularies vs free text
- Which fields carry source references vs paraphrased interpretations
- Identity fields that pass through unchanged

**Validation and feedback:**
- Gates or checks between stages (type, criteria, what happens on failure)
- Retry or revision loops (what triggers them, what gets fed back, iteration bounds)
- Human review points
- Missing validation — boundaries with no checks

**Context management:**
- What each stage loads into context
- Whether stages run in isolated contexts (subagents) or share context
- Whether semantic gates run in clean contexts
- History policy (explicit or implied)

**Domain constraints and complexity signals:**
- Error reinforcement risks
- Variable input sizes
- External dependency reliability concerns
- Anything that makes this pipeline harder than a simple linear chain

**Domain knowledge assets** (supporting documents, schemas, templates, decision rules):

For every file in the source implementation that is NOT a stage/skill behavioral specification, catalog it in a `## Domain Knowledge Assets` section with:

| Source File | Content Type | Summary | Consuming Stage(s) |
|---|---|---|---|
| path | `schema` / `template` / `decision-rules` / `formatting` / `protocol` / `reference` | What rules or structures it defines | Which stage(s) need this knowledge to operate correctly |

Content types:
- **schema** — structural definitions (field lists, section specifications, JSON schemas, manifest formats)
- **template** — fill-in-the-blank documents with placeholder text and guidance
- **decision-rules** — criteria for inclusion/exclusion, classification, or scoring decisions
- **formatting** — output rendering conventions (Markdown syntax, diagram conventions, table styles)
- **protocol** — multi-step interaction workflows (review presentation, editing sequences, validation phases)
- **reference** — domain knowledge needed to perform a transformation correctly (mapping rules, architecture patterns, alignment guidance)

For each document, note whether its content is fully captured in the stage descriptions above, partially captured, or not captured. This classification drives Step 3.

**Utility skills** (non-pipeline tools):

Classify every skill or command in the source as either `pipeline-stage` or `utility`. Catalog utilities in a `## Utility Skills` section:

| Skill | Purpose | Category | Shares Logic With |
|---|---|---|---|
| name | what it does | `observability` / `validation` / `assessment` / `editing` / `other` | pipeline gate or stage, if any |

Categories:
- **observability** — inspects pipeline state, presents dashboards, shows progress. These map to Loop's execution manifest and state tracking capabilities. Note this explicitly: the designer must decide whether the utility's functionality is adequately covered by the execution manifest or whether a dedicated state-inspection skill is still needed.
- **validation** — validates artifacts outside the pipeline flow (standalone schema checks, format validation). Often shares logic with a pipeline gate.
- **assessment** — evaluates output quality independently (scoring, linting, compliance checks). Could be wired as a post-pipeline evaluation stage or preserved standalone.
- **editing** — interactive modification of pipeline artifacts outside the normal flow (ad-hoc edits, section-level changes).
- **other** — anything that doesn't fit the above categories.

Write the full extraction to `loop-workspace/extraction.md`.

Present the extraction to the user. Flag where interpretation was needed with `<!-- Synthesis note: ... -->` comments. Ask the user to review and correct before proceeding — errors here propagate through the entire design.

### Step 3: Classify and reconcile

Before feeding the extraction into `/loop:design`, classify every piece of source material and ensure nothing is lost. This step produces two outputs: a set of reference documents for the design pipeline, and an explicit reconciliation log.

#### 3a: Classify domain knowledge assets

For each document in the `## Domain Knowledge Assets` table from the extraction:

1. **Absorbed** — The document's rules are fully captured in stage descriptions or artifact contracts in the extraction. No action needed.
2. **Reference** — The document contains domain knowledge that stages need but that isn't captured in stage descriptions. Copy or adapt the document to `loop-workspace/references/` and note which stage(s) consume it.
3. **Schema/Template** — The document defines a structural specification or template that a stage must follow to produce correct output. Copy to `loop-workspace/references/` and note the consuming stage(s).

Create `loop-workspace/references/` if it does not exist. Write each migrated document with a header comment noting its origin:

```markdown
<!-- Source: [original-path] -->
<!-- Consuming stages: [stage-list] -->
```

#### 3b: Classify utility skills

For each utility in the `## Utility Skills` table:

1. **State tracking** — If the utility's purpose is observability (inspecting pipeline state, showing progress, presenting dashboards), note that Loop's execution manifest provides state tracking natively. Write a `<!-- Designer note: ... -->` comment in the extraction explaining what the legacy utility did and that the execution manifest may cover it. The designer decides whether the manifest is sufficient or a dedicated inspection skill is needed.
2. **Gate-shared validation** — If the utility shares logic with a pipeline gate, note the sharing relationship in the extraction so the designer can decide whether to expose the gate's validation as a standalone skill.
3. **Standalone** — If the utility is independent (assessment, editing, other), preserve it. Copy its specification to `loop-workspace/utilities/` for `/loop:implement` to emit alongside the pipeline.

For category 1 (state tracking), this is critical: the Loop framework's execution manifest tracks stage status, gate attempts, loop iterations, cascade budgets, and human decisions. Legacy observability tools that inspect workspace artifacts and report progress are often fully subsumed by the manifest. **Explicitly notify the designer** by adding a section to the extraction:

```markdown
## State Tracking Migration

The following legacy utilities provided observability over pipeline state:

| Utility | What It Showed | Execution Manifest Coverage |
|---|---|---|
| [name] | [description] | [which manifest fields cover this, or "gap — not covered"] |

The designer should review whether the execution manifest's stage status, gate attempts, loop iterations, and decision history are sufficient, or whether a dedicated state-inspection skill is needed for functionality the manifest does not cover.
```

#### 3c: Reconcile extraction against source

Walk through every file in the source implementation and verify it appears in the extraction — as a stage, an artifact, a domain knowledge asset, a utility skill, or an explicit exclusion. Produce a reconciliation log in the extraction:

```markdown
## Reconciliation

| Source File | Extraction Location | Status |
|---|---|---|
| path | Section or reference | `captured` / `reference` / `utility` / `dropped: [rationale]` |
```

Every file must have an entry. `dropped` status requires a rationale — the user must opt into dropping, not discover things are missing.

Present the reconciliation to the user. If any files are marked `dropped`, confirm before proceeding.

### Step 4: Run the design pipeline

Run `/loop:design` with the extracted description from `loop-workspace/extraction.md` as the task description input.

Before invoking `/loop:design`, tell the designer:
- Reference documents in `loop-workspace/references/` contain domain knowledge that stages depend on. Stage instructions must reference these documents — a stage that says "produce a 17-section PRD" must point to the reference that defines the 17 sections.
- If the extraction includes a `## State Tracking Migration` section, the designer must address each entry — either confirming the execution manifest covers it or designing a dedicated inspection mechanism.
- Stages marked `<!-- Optional: [rationale] -->` in the extraction must appear in the design. They may be marked as optional in the design with an explicit rationale, but they must not be silently dropped.

The design pipeline will produce proper artifacts — potentially restructuring stages, adding missing gates, designing feedback loops with proper termination conditions. It is not constrained to mirror the original implementation's structure; it designs from the transformation intent.

### Step 5: Implement

Run `/loop:implement` to generate a clean Loop plugin from the design artifacts.

If `loop-workspace/references/` contains documents, instruct `/loop:implement` to:
- Copy reference documents to `skills/<prefix>/references/` in the generated plugin
- Ensure every stage file that consumes a reference includes a `## References` section pointing to the reference document path

If `loop-workspace/utilities/` contains utility skill specifications, instruct `/loop:implement` to:
- Generate utility skills as separate skill directories alongside the pipeline orchestrator
- Note any sharing relationships between utility validation and pipeline gates

### Step 6: Audit the implementation

Run `/loop:audit-implementation` against the generated plugin directory.

Present findings to the user.

### Step 7: Fix issues

For each ERROR and WARNING from the audit:
- **Implementation fixes**: edit the generated skill files directly
- **Design fixes**: update `loop-workspace/` artifacts and re-run `/loop:implement` for affected files

After fixes, re-run `/loop:audit-implementation` to verify. Max 2 audit-fix cycles.

### Step 8: Reference audit

After the implementation passes audit, verify reference completeness:

For each domain knowledge asset in the extraction's `## Domain Knowledge Assets` table with status `reference` or `schema/template`:
- [ ] The document exists in `skills/<prefix>/references/`
- [ ] At least one stage file contains a `## References` section pointing to it
- [ ] The rules in the reference document are not contradicted by stage instructions

For each utility skill in `loop-workspace/utilities/`:
- [ ] A corresponding skill directory exists in the generated plugin
- [ ] The skill's supporting documents are included

Report any gaps to the user.

### Step 9: Present results

Summarise the rebuild:
- Original implementation: what was analyzed (file count, type)
- Key elements preserved from the original (stages, sources, sinks, domain logic)
- Domain knowledge assets: how many migrated to references, how many absorbed into stages
- Utility skills: how many preserved, how many subsumed by execution manifest
- Elements restructured by the design pipeline (merged stages, added gates, new feedback loops)
- Generated plugin: file count, invocation format (`/<prefix>:run`)
- Audit results: issues found and fixed
- Any remaining warnings

## Guidance

- **Lossless by default.** Everything in the source must appear somewhere in the output — as a stage, a gate, a contract, a reference document, a utility skill, or an explicit "dropped with rationale" entry in the reconciliation. Silent information loss is the primary failure mode of reverse engineering. The user opts into dropping things; they should never discover something is missing.
- **The extraction is the critical step.** Capture everything valuable from the original implementation — domain logic, external dependencies, validation criteria, complexity constraints, supporting documents, utility tools. What the extraction misses, the design pipeline can't recover.
- **Domain knowledge is a design concern.** Supporting documents (schemas, templates, decision rules, formatting conventions) are design-level assets, not implementation details. They must be classified and migrated to references during Step 3, before the design pipeline runs. A stage instruction that says "produce a 17-section PRD" without a reference defining the 17 sections is an incomplete design.
- **State tracking has a home.** The Loop framework's execution manifest provides native state tracking — stage status, gate attempts, loop iterations, cascade budgets, human decisions. Legacy observability utilities that inspect workspace state are often subsumed by the manifest. Explicitly surface this to the designer so they can make an informed decision rather than blindly preserving a utility that duplicates built-in functionality.
- **Map to vocabulary, don't just summarize.** "This skill calls an API" is a summary. "This stage is an Enriched Extract with a web API source, producing a structured entity list with closed-vocabulary classification fields" is a vocabulary mapping.
- **Flag interpretation.** When the implementation is ambiguous (is this one stage or two? is this a gate or just an if-statement?), use synthesis notes so the user can correct.
- **Never silently drop stages.** If a stage seems optional, additive, or secondary, include it in the extraction with an `<!-- Optional: ... -->` tag. The design pipeline may mark it as optional in the design, but it must appear. Dropping is the user's decision.
- **The design pipeline may restructure.** The original implementation might have Kitchen Sink stages, missing gates, or no feedback loops. The design pipeline will fix these. This is a feature — the point is to produce a properly structured pipeline, not to replicate the original's flaws.
- **Preserve the original.** This workflow generates a new plugin alongside the original implementation. It does not modify the original.
