# Stage: Verify Claims

**Intent**: Research and assess each claim's accuracy independently.

**Category**: Enrich — add information (evidence, verdicts), don't transform structure.

This stage runs as 3 parallel instances. Each instance works independently with no knowledge of other reviewers.

## Input

Read the Typed Claim List from `research-validation-workspace/typed-claim-list.md`.

Read `research-validation/contracts/reviewer-assessment.md` for the output schema.

## Steps

1. Read the Typed Claim List
2. For each claim:
   a. **If the claim has citations**: Look up the cited source. Determine whether the citation actually supports the claim (`citation_valid`). Record what the citation says vs. what the claim states (`citation_notes`).
   b. **Search for evidence**: Use web search to find supporting or contradicting evidence. Record each source found with URL, title, relevant excerpt, and whether it supports or contradicts the claim.
   c. **Render a verdict**: Based on evidence found, assign one of: `supported`, `contradicted`, `insufficient_evidence`, `unverifiable`.
   d. **Assign confidence**: `high` (strong evidence, clear conclusion), `medium` (some evidence, reasonable conclusion), `low` (weak evidence, uncertain conclusion).
   e. **Write reasoning**: Explain why you reached this verdict and confidence level.
3. Write the Reviewer Assessment to the appropriate workspace file:
   - Reviewer 1: `research-validation-workspace/reviewer-1-assessment.md`
   - Reviewer 2: `research-validation-workspace/reviewer-2-assessment.md`
   - Reviewer 3: `research-validation-workspace/reviewer-3-assessment.md`

## Sources

- **Web search**: For citation verification and factual research. Required — the pipeline cannot function without web access.

## Guidance

- **Work independently.** Do not assume other reviewers exist. Do not try to access other reviewers' outputs.
- **Vary search strategies.** Use different query formulations. Consult different source types where possible. Do not rely on a single source for any verdict.
- **Citation checking is binary.** A citation either supports the claim it's attached to, or it doesn't. Record what the citation actually says.
- **Separate evidence from judgment.** The `evidence_found` field records what was found (factual). The `verdict` and `reasoning` fields record your assessment (judgment). Keep these distinct.
- **Do not modify identity fields.** `claim_id`, `text`, and `claim_type` must match the Typed Claim List exactly.
- **Do not drop claims.** Every claim from the input must appear in the output, even if the verdict is `unverifiable`.
- **Distinguish `insufficient_evidence` from `unverifiable`.** "Insufficient evidence" means more research might help. "Unverifiable" means the claim cannot be checked by nature (e.g., predictions about the future, unfalsifiable statements).
