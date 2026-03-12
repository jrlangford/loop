# Stage: Gather References

## Intent

Load optional reference documents into a structured reference index.

## Category and Posture

**Category**: Enrich
**Posture**: Add information, don't transform structure. New fields supplement, not replace. Each reference is loaded as-is with source attribution — do not interpret, summarize, or restructure the content.

## Input

Read the Analysis Request from `autodoc-workspace/analysis-request.md`. Use only the `references` list — ignore `target_scope` (not needed for this stage).

If `references` is empty or absent, produce an empty Reference Index and stop.

## Output

Write the Reference Index to `autodoc-workspace/reference-index.md`.

Read `autodoc/contracts/reference-index.md` for the output schema.

## Steps

1. Parse the `references` list from the Analysis Request
2. For each reference, load content based on `type`:
   - **`file`**: Read the file at the specified path. Extract text content. Use the filename as the title.
   - **`url`**: Fetch the URL content. Extract text from HTML (strip navigation, headers, footers, scripts, styles). Use the page title or URL as the title.
   - **`notion`**: Call the Notion MCP server's `notion-fetch` tool with the page ID. Extract text content from the response. Use the page title.
3. For each loaded reference, identify 3-5 domain topics covered by the content
4. Assemble all entries into the Reference Index format
5. If any reference fails to load, include an entry with empty `content` and a note about the failure in the `topics` field — do not silently omit failed references

## Sources

| Source | Access method | Required? |
|--------|--------------|-----------|
| Local filesystem | Read tool | When `type: "file"` references exist |
| Web URLs | WebFetch tool | When `type: "url"` references exist |
| Notion pages | Notion MCP `notion-fetch` | When `type: "notion"` references exist |

## Sinks

None.

## Guidance

- **Do** extract clean text content — strip formatting noise, navigation elements, metadata not relevant to domain content
- **Do** preserve the structure of the original document (headings, lists, sections) as plain text
- **Do** record source provenance accurately — `source_locator` must be the exact path/URL/page_id provided
- **Do not** interpret or summarize the reference content — that's downstream work
- **Do not** filter or rank references — load everything the user specified
- **Do not** fail the stage if a single reference fails to load — report the failure and continue with the rest

### Notion MCP Precondition

If any references have `type: "notion"`, verify that the Notion MCP server is connected before attempting retrieval. If the MCP server is unavailable:
1. Report which Notion references could not be loaded
2. Continue with non-Notion references
3. Do not fail the stage — an incomplete Reference Index is better than no index

### Topic Extraction

For each reference, identify 3-5 domain topics. These are used downstream to sensitize boundary identification heuristics. Topics should be:
- Domain-specific terms (e.g., "payment processing", "user authentication")
- Not generic labels (e.g., not "error handling" or "data flow")
- Derived from section headings and key concepts in the content
