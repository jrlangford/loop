---
name: phase-artifacts
description: "Specify the typed intermediate representations passed between pipeline stages — what each artifact carries, what it omits, and how it's validated. Use after /loop:phase-decompose has produced a stage list."
---

# Loop: Specify Artifacts

Define the artifact (intermediate representation) at each stage boundary. Artifacts are the pipeline's data contract.

## Input

Read `loop-workspace/stages.md`. If it doesn't exist, tell the user to run `/loop:phase-decompose` first.

## What You Produce

A file named `loop-workspace/artifacts.md` containing a specification for each inter-stage artifact.

## How to Run

### Step 1: Identify artifact boundaries

For N stages, there are up to N+1 artifacts: pipeline input, one between each pair of adjacent stages, and pipeline output. Some may be the same artifact passed through.

### Step 2: Walk through the artifact worksheet for each boundary

For each artifact, ask the user these questions:

| Question | Why it matters |
|----------|----------------|
| What type of content does this carry? | Sets the artifact's purpose |
| What fields or structure does the downstream stage need? | Defines the contract |
| What can be omitted from the upstream stage's full output? | Reduces noise in the downstream channel — every omitted irrelevant field is bandwidth freed for signal |
| How can this artifact be validated before passing it on? | Enables gate placement (next skill) |
| Does the downstream stage need to know *why* the artifact looks this way? | Decides whether to include a reasoning trace |

**Challenge weak answers:**
- "Everything" for what it carries → push for specific fields. An artifact should contain exactly what downstream stages need, no more.
- "Nothing" for what to omit → push back. Every upstream stage produces more than the downstream stage needs. What specifically is discarded?
- "No validation needed" → note it but flag that `/loop:phase-gates` will revisit this.

### Step 3: Reduce the interpretation surface

For each artifact field, apply these handoff drift techniques:

**Enumerate, don't describe.** For each free-text field, ask: can this be an enum, a score, or a reference instead? Push the user toward closed vocabularies wherever the domain allows. A field like `severity: critical | high | medium | low` drifts less across stages than `severity_description: "This is a serious issue that..."`.

**Reference, don't paraphrase.** Where an artifact carries information derived from source material, prefer source locations (file paths, line numbers, section IDs, verbatim quotes) over the producing stage's interpretation. If summary fields exist alongside references, they should be in distinct fields so downstream stages can verify.

**Separate observation from judgment.** If an artifact must carry both evidence and assessments, they belong in distinct fields. Challenge designs where a single `description` field mixes what was observed with what it means — the factual record should be independently readable.

### Step 4: Assess the reasoning trace question

The reasoning trace decision is per-artifact. Guide the user:

- **Include trace when**: the downstream stage might need to understand upstream decisions to handle edge cases, or when debugging pipeline failures requires understanding *why* an artifact looks the way it does.
- **Omit trace when**: the downstream stage operates purely on the artifact's content without needing provenance. Traces are noise in the downstream channel if unused.
- **Summary trace as middle ground**: a brief rationale rather than full reasoning.

### Step 5: Check for sink-consumed artifacts

If any artifact is consumed by an Emit stage (a stage that writes to an external system), note additional requirements:
- **Sink format compliance** — the artifact structure must match the external target's API contract or schema. Include format constraints in the artifact spec.
- **Idempotency markers** — the artifact should include a stable identifier (transaction ID, content hash, or reference key) that the Emit stage can use to prevent duplicate writes on retry. Add this as a required field.
- **Completeness over partial writes** — partial or incomplete artifacts sent to external systems are often worse than no write at all. Ensure the artifact spec defines a clear "complete and write-ready" validation criterion.

### Step 6: Identify identity fields

For each artifact, ask the user: which fields should pass through downstream stages unchanged? These are the artifact's **identity fields**. Common candidates:

- Source references (file paths, URLs, line numbers)
- Original input identifiers
- Constraint specifications from the transformation definition
- Verbatim quotes used as evidence

Identity fields must be mechanically checkable (exact match or hash comparison). If identity fields are present, note them in the artifact spec — gates can verify them cheaply.

### Step 7: Write the artifact

Write `loop-workspace/artifacts.md`:

```markdown
# Artifact Specifications

## Pipeline Input: [Name]
- **Content**: [What the pipeline receives]
- **Format**: [Structure/schema]
- **Variability**: [How much it varies across invocations]

## Artifact: [Stage A] → [Stage B]
- **Name**: [Descriptive name]
- **Content**: [What it carries]
- **Structure**: [Fields, schema, format]
- **Identity fields**: [Fields that must not mutate across stages — source refs, IDs, verbatim quotes]
- **Omitted**: [What the upstream stage produced but this artifact excludes]
- **Validation**: [How to check conformance — feeds into /loop:phase-gates]
- **Reasoning trace**: [None | Summary | Full] — [rationale for choice]

## Artifact: [Stage B] → [Stage C]
...

## Pipeline Output: [Name]
- **Content**: [What the pipeline delivers]
- **Format**: [Structure/schema]
- **Quality criteria**: [From transformation definition]
```

### Step 8: Summarise

Present a summary of the artifact chain. The user or a workflow skill (`/loop:design`) determines what to run next.

## Guidance

- **Artifacts are the contract, not the implementation.** Specify what crosses the boundary, not how it's stored or serialised.
- **Minimal by default.** The strongest artifact specs are ones where every field has a clear consumer. If you can't name the downstream stage that uses a field, question whether it belongs.
- **Self-describing matters.** A stage receiving an artifact should be able to determine what it contains without external documentation. Include type markers or metadata fields if the artifact's purpose isn't obvious from its structure.
