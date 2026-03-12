# Contract: Source Document

Pipeline input — the markdown document to validate.

## Format

Raw markdown with prose, inline citations, and reference sections.

## Variability

Low — stable, static documents. The pipeline does not modify the input.

## Volume

Single document per run, article-length. Fits comfortably in a single context window.

## Quality Issues to Expect

- Citations may be incorrect, missing, or point to non-existent sources
- Claims may be ambiguous or imprecise
- Opinion may be presented as fact without clear demarcation
- Some claims may be inherently unverifiable

## Workspace Path

`research-validation-workspace/source-document.md`
