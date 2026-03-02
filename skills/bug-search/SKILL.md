---
name: bug-search
description: Search bugs, crashes, PRs, and documentation across all ACS collections
---

# Bug Wiki Search

Search across all indexed collections in the AI Context Search system — bugs, crash reports, PRs, and project documentation.

## How to Search

Use Bash curl to query the API. Make a single request searching all collections:

```bash
curl -s "https://acs.sipher.gg/query?q=URL_ENCODED_QUERY&limit=10"
```

URL-encode the ARGUMENTS (spaces become `%20`).

This searches across ALL collections (github-prs, crash, s2, community) in one request.

## Available Collections

Results will include a `collection` field per result:
- `s2` - S2 project documentation, bug reports, code
- `github-prs` - Official bug fixes from merged PRs
- `crash` - Crash reports and analysis
- `community` - Community-contributed bug reports and solutions (via `/bug-add`)

## Output Formatting

> **MANDATORY: NARROW TABLES + LINKS BELOW**
>
> The terminal renderer breaks tables into ugly list format when columns are too wide.
> To prevent this: keep ALL table columns SHORT, and put GitHub links AFTER each table.

If a section has no results, write: `No results found.`

Use this EXACT structure — copy it precisely:

```
## Results: "query"

### 1. Official Fixes (github-prs)

| # | Title | Summary | Score |
|---|-------|---------|-------|
| 1 | Fix player crash on load | Null check on PlayerState during level transition | 0.058 |
| 2 | Fix audio stutter in combat | Buffer underrun when >8 simultaneous SFX | 0.045 |

- **1.** `pulls/1234.md` — [github](https://github.com/org/repo/pull/1234)
- **2.** `pulls/1200.md` — [github](https://github.com/org/repo/pull/1200)

### 2. Crash Reports (crash)

| # | Title | Summary | Score |
|---|-------|---------|-------|
| 1 | ACCESS VIOLATION | Race condition in ControlRig during PIE teardown | 0.028 |

- **1.** `2026-02-03-abc.md` — [github](https://github.com/org/crash/blob/wiki/2026-02-03-abc.md)

### 3. Community Solutions (community)

| # | Title | Summary | Score |
|---|-------|---------|-------|
| 1 | Audio stuttering fix | Buffer underrun workaround for >8 SFX | 0.042 |

- **1.** `2026-02-04-audio-stuttering-fix.md`

### 4. Project Docs (s2)

| # | Title | Summary | Score |
|---|-------|---------|-------|
| 1 | Main Game Code | GAS interfaces, module deps, architecture | 0.065 |
| 2 | UI Architecture Review | Accessibility checklist, input switching | 0.058 |

- **1.** `Source/S2/CLAUDE.md` — [github](https://github.com/org/s2/blob/main/Source/S2/CLAUDE.md)
- **2.** `claude-agents/.../ui-review.md` — [github](https://github.com/org/s2/blob/main/claude-agents/.../ui-review.md)

---

**Summary:** Found 0 PRs, 1 crash, 1 community, 2 docs matching "query". Top hit: ACCESS_VIOLATION in ControlRig PIE teardown (editor-only, low severity). Community has an audio stuttering workaround.
```

---

**CRITICAL RULES — read every one:**

1. **NO markdown links inside tables.** Never write `[Title](url)` in a table cell. The terminal expands these to full URLs which overflows column width and breaks the table into list format.
2. **Title column: plain short text only.** Use the `title` field from JSON. Truncate to ~30 chars max.
3. **Summary column: 1-line description.** Read the `content` field and write a short phrase (~5-10 words) describing what the result is about. This is the key value-add — tell the user what each result contains.
4. **Score column:** Raw score rounded to 3 decimals.
5. **Links section below each table as a bullet list.** Format each as: `- **#.** \`filePath\` — [github](githubUrl)`. The bold number ties it to the table row. The file path is in backticks (abbreviated with `...` if long). The `[github](url)` link renders as a colored clickable link in the terminal, distinct from the backtick path.
6. **No raw content.** Never dump the `content` field directly — only use it to write the Summary column and Overall section.
7. **Total table width must stay under 80 characters.** Shorten Title or Summary text if needed.
8. **Overall section at the end.** After all 3 tables, add `---` then **Overall:** with result counts per collection and 1-2 sentences on the most actionable findings.

## Tips

- Use specific terms for better results (e.g., "Access Violation" not just "crash")
- Use function/class names for exact matches (e.g., "SipherANS_DismemberWarp")
- Use natural language for conceptual queries (e.g., "how to fix audio stuttering")

## Legacy Metadata

```yaml
skill: bug-search
```
