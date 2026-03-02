---
name: bug-add
description: Add a bug and solution to the community collection
---

# Bug Wiki Add

Add a bug report and solution to the community collection for others to discover via `/bug-search`.

## API Key

Use this key for all community write requests:

```
ACS_COMMUNITY_WRITE_KEY=cs_community_2026
```

## How to Submit

Use WebFetch to POST directly to the API. **NEVER use curl/Bash.**

```
POST https://acs.sipher.gg/webhook/community
Authorization: Bearer cs_community_2026
Content-Type: application/json

{
  "title": "Brief bug title",
  "content": "Full markdown content (see template below)",
  "component": "Audio System",
  "severity": "medium",
  "tags": ["audio", "performance"],
  "source": "https://github.com/sipherxyz/s2/issues/123"
}
```

**Required fields:** `title`, `content`
**Optional fields:** `component`, `severity`, `tags`, `source`

## Workflow Selection

Check if the user provided a file path or content in their request.

### Option 1: File Import (Fastest)
If the user mentions a file (e.g., "import from bug.md") or pastes full content:
1. **Read/Parse**: Read the file using `Read` or analyze the pasted text.
2. **Extract Fields**: detailed `title`, `content` (markdown), `component`, `severity`, `tags`.
   - If the file is JSON, parse directly.
   - If the file is text/markdown, use your judgment to extract fields.
3. **Confirm**: Show the extracted summary to the user.
4. **Submit**: POST to the API.

### Option 2: Interactive Mode (Step-by-step)
If no file is provided and the user wants to enter details manually:
1. **Ask for required information** (one question at a time):
   - Brief title for the bug
   - Component name (e.g., "Audio System", "Physics", "UI", "Networking")
   - Severity level: low / medium / high / critical
   - Symptoms — what does the user observe?
   - Root cause — what's actually wrong?
   - Solution / fix steps
   - Prevention tips (optional)
   - Source URL — link to GitHub issue or PR (optional)

2. **Build the content** using the markdown template below.

3. **POST to the API** using WebFetch with the key above.

4. **Confirm success** — show the `file_path` and `chunks_created` from the response.

## Content Template

Build the `content` field as markdown:

```markdown
## Bug Description

<Brief description of the bug>

## Symptoms

- <symptom 1>
- <symptom 2>

## Root Cause

<Explanation of what causes the bug>

## Solution

### Step-by-step fix

1. <step 1>
2. <step 2>

### Code changes (if applicable)

```cpp
// Before:
<problematic code>

// After:
<fixed code>
```

## Prevention

<How to avoid this bug in the future>

## References

- <Link to related PR>
- <Link to documentation>
```

## Field Reference

| Field | JSON key | Required | Example |
|-------|----------|----------|---------|
| Title | `title` | Yes | "Audio stuttering in combat" |
| Content | `content` | Yes | Full markdown (template above) |
| Component | `component` | No | "Audio System" |
| Severity | `severity` | No | low, medium, high, critical |
| Tags | `tags` | No | ["audio", "performance"] |
| Source | `source` | No | URL to issue or PR |

## Tips

- Keep titles short and descriptive (~40 chars)
- Include code snippets in the Solution section when possible
- Tag with function/class names for better search matches
- Link to the original GitHub issue or PR in `source`

## Legacy Metadata

```yaml
skill: bug-add
```
