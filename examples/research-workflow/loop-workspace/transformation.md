# Transformation Definition

## Task

Validate research claims in markdown documents by launching parallel reviewer agents that independently assess citation accuracy, claim grounding, and opinion/fact separation, then compare findings through agreement gates and iterative feedback to produce a scored validation report.

## Input

- **Format**: Markdown documents containing research claims with citations
- **Structure**: Prose with inline citations, reference sections, factual assertions, and analytical claims
- **Variability**: Low — stable, static source documents; the pipeline does not modify inputs
- **Volume**: Single document per run (article-length; fits comfortably in context)
- **Quality issues**:
  - Citations may be incorrect, missing, or point to non-existent sources
  - Claims may be ambiguous or imprecise
  - Opinion may be presented as fact without clear demarcation
  - Some claims may be inherently unverifiable

## Output

- **Format**: Structured validation report (markdown)
- **Structure**:
  - Per-claim entries: original claim text, claim type (factual/analytical/opinion), citation check result, confidence score, supporting/contradicting evidence found, reviewer agreement status
  - Summary statistics: total claims, verified count, unverifiable count, flagged count
  - Unverifiable claims section: claims where reviewers could not reach agreement after 3 rounds, explicitly marked as unverifiable with reasoning
- **Quality criteria**:
  - Every factual claim in the source document is identified and assessed
  - Citation accuracy is binary-checked (correct reference or not)
  - Confidence scores reflect reviewer agreement (high agreement = high confidence)
  - No claim silently dropped — each is accounted for in the report
- **Consumer**: Human researcher reviewing the validation findings

## Gap Analysis

### Where single-pass fails

A single LLM call struggles here because the task combines multiple distinct cognitive operations:
1. **Claim extraction** — identifying individual claims and their types in prose
2. **Citation verification** — checking whether citations actually support the claims they're attached to (requires external lookup)
3. **Factual validation** — independently researching whether claims are accurate (requires web search)
4. **Opinion/fact discrimination** — classifying claim types, which requires different analytical framing than verification
5. **Cross-validation** — comparing independent assessments to gauge confidence

A single call would conflate extraction with evaluation, skip external verification, and have no way to gauge its own confidence through independent agreement.

### Critical correctness vs. best-effort

- **Critical**: Citation accuracy (a citation either supports a claim or it doesn't), claim extraction completeness (missing a claim is a silent failure)
- **Best-effort**: Confidence scoring (inherently subjective), opinion/fact classification (edge cases are genuinely ambiguous)

### Domain knowledge

- Reviewers need general research literacy and access to web sources for verification
- No specialised domain expertise required beyond what's in the source document and its references

## Complexity Signals

- **Parallelisation opportunity**: YES — up to 3 independent reviewer agents can assess claims concurrently; this is a core design requirement
- **Refinement need**: YES — problematic claims trigger up to 3 rounds of feedback where reviewers re-examine with knowledge of disagreements
- **External knowledge dependency (sources)**: YES — reviewers need web access to verify citations and research claims
- **External write targets (sinks)**: None
- **Notification needs**: None
- **Error reinforcement risk**: MODERATE — multiple agents using the same search queries could converge on the same incorrect information; the agreement gate mitigates this but doesn't eliminate it (echo chamber risk when all agents find the same wrong source)
