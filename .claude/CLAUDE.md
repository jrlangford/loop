# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Loop is a design framework (not a runtime framework — no scheduler, no orchestrator library, no SDK) for structuring LLM-based information processing as pipelines of stages with explicit feedback loops, channel capacity budgets, and anti-pattern detection. It is delivered as a set of Claude Code skills that guide pipeline design interactively. Completed designs can be translated into implementable Claude Code skills via `/loop:implement`.

## Commands

Requires [just](https://github.com/casey/just).

```sh
just install    # Symlink all skills to ~/.claude/skills/
just uninstall  # Remove symlinks
just status     # Show which skills are installed
```

No build, lint, or test commands — this is a pure documentation/skills project.

## Two-Level Architecture

1. **Framework documentation** (root `.md` files) — design framework, theory, and rationale. Read by humans learning the framework. Can reference anything.
   - `framework-design.md` — Full design framework: principles, anatomy, design process, patterns, anti-patterns
   - `feedback-loops-in-llms.md` — Background on reinforcing/balancing feedback loops in LLM systems
   - `information-flow-and-context.md` — Information theory applied to LLM context windows (channel capacity, rate-distortion, error detection)
2. **Skills** (`skills/*/SKILL.md`) — operational tools used by Claude Code in arbitrary project directories. Must be self-contained.

Changes to the framework should flow into skills where relevant. Changes to skills must not introduce dependencies on the framework docs.

### Skill Categories

**Workflow entrypoints** (orchestrate phase skills): `design` (greenfield), `analyze` (existing code), `align` (drift check)

**Phase skills** (each produces one artifact): `phase-define`, `phase-decompose`, `phase-artifacts`, `phase-context`, `phase-gates`, `phase-feedback`

**Standalone skills**: `review` (check design artifacts), `reverse` (reverse-engineer implementation), `audit` (check implementation against principles), `implement` (generate Claude Code skills from design), `describe` (generate readable markdown with mermaid diagrams)

### Pipeline Two-Level Split

Stages, artifacts, and context-specs are **reusable and workflow-independent**. Gates and loops are **workflow-scoped** — they live under `loop-workspace/workflows/<name>/`. The same stages can participate in multiple workflows with different gate/loop configurations.

## Skill Self-Containment

Skills in `skills/` are installed into other projects via symlinks. They execute in directories that have **no access** to the framework documentation.

**Rules:**
- Skills must be fully self-contained. A skill must work correctly when the only file available is its own `SKILL.md`.
- Do not add references to `framework-design.md` or any other file outside the skill's own directory. No `**Reference**: Read [framework-design.md](...)`, no `(see Section X.Y)`, no `Cite Section X.Y:` patterns.
- When a skill needs a concept from the framework, **inline the relevant content directly into the skill**.
- Keep inlined content concise — enough for the skill to function, not the full framework discussion.
- When updating the framework design, check whether any skill references the changed concept and update the skill's inline content to match.

## Anti-Patterns

The framework defines eight anti-patterns that review/audit skills check for:
1. **Kitchen Sink Stage** — stage doing too many things
2. **Echo Chamber Loop** — reinforcing loop without novelty detection
3. **History Avalanche** — unbounded context accumulation
4. **Phantom Feedback Loop** — loop that never triggers correction
5. **Hardcoded Chain** — stages coupled to a fixed sequence
6. **Ouroboros** — unintentional circular dependencies
7. **Telephone Game** — cumulative interpretation drift across stages
8. **Fire-and-Forget Emit** — external write without idempotency, pre-write gate, or tight loop caps
