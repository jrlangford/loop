# Contract: Reference Index

**Produced by**: Gather References (Stage 1)
**Consumed by**: Identify Boundaries (Stage 3), Extract Behaviours (Stage 4)
**Workspace path**: `autodoc-workspace/reference-index.md`

## Structure

```yaml
entries:
  - source_type: "file" | "url" | "notion"
    source_locator: <original path/URL/page_id>
    title: <document title or filename>
    content: <extracted text, cleaned of formatting noise>
    topics: [<list of 3-5 domain topics covered>]
```

When no references are provided, produce an empty index:

```yaml
entries: []
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source_type` | enum | Yes | One of: `file`, `url`, `notion` |
| `source_locator` | string | Yes | Original path, URL, or Notion page ID |
| `title` | string | Yes | Document title or filename |
| `content` | string | Yes | Extracted text content, cleaned of navigation elements and formatting noise |
| `topics` | list[string] | Yes | 3-5 domain topics covered by this reference |

## Identity Fields

`source_type` and `source_locator` must not be altered by any downstream stage. These are the provenance record.

## Omitted

- Original formatting (HTML tags, Notion blocks, markdown styling beyond structure)
- Navigation elements (sidebars, headers, footers, breadcrumbs)
- Metadata not relevant to domain content (author, last-edited timestamps, version history)

## Validation Rules

1. Each entry has non-empty `content`
2. Each entry has a valid `source_locator` (path exists for files, well-formed URL for urls, non-empty page ID for Notion)
3. Notion entries validate that the MCP connection succeeded — if it failed, the entry records the failure rather than being silently omitted
4. `topics` contains 3-5 entries per reference

## Routing

- Skips Stage 2 (Survey Codebase) — Stage 2 does not consume this artifact
- Consumed by Stage 3: reference topics sensitize boundary identification heuristics
- Consumed by Stage 4: matching reference entries inform contract extraction and category assignment (`specified` vs `implicit`)
- When empty, downstream stages proceed without it — all behaviours will be classified `implicit` or `undefined`

## Reasoning Trace

None. Content speaks for itself; provenance is recorded in `source_locator`.
