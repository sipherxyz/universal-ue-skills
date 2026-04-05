# VFX Project IDs Reference

All IDs for GitHub Projects V2 API operations on the VFX team's project board.

## Repository

All values below are read from `skills.config.json` at the repository root.

```
Owner: {github.owner}
Repo: {project.name}
```

## Project #{github.project_number} ({project.fullname})

```
Project Number: {github.project_number}
Project Node ID: {github.project_node_id}
```

## Field IDs

| Field | ID | Type |
|-------|-----|------|
| Status | `{github.fields.status_id}` | SingleSelect |
| Start date | `{github.fields.start_date_id}` | Date |
| End date | `{github.fields.end_date_id}` | Date |
| Size | `{github.fields.size_id}` | SingleSelect |

## Status Options

| Status | Option ID |
|--------|-----------|
| To Do | `{github.status_options.todo}` |
| Fixed | `{github.status_options.fixed}` |

> **Note:** "Done" status option ID is not yet captured. Query it if needed:
> ```bash
> gh api graphql -f query='{ node(id: "{github.project_node_id}") { ... on ProjectV2 { field(name: "Status") { ... on ProjectV2SingleSelectField { options { id name } } } } } }'
> ```

## Issue Type IDs

| Type | ID |
|------|-----|
| Task | `{github.issue_types.task}` |
| Bug | `{github.issue_types.bug}` |
| Feature | `{github.issue_types.feature}` |

## VFX Team Members

| GitHub Handle | Name | Specialization |
|---------------|------|----------------|
| `TienDang-VFX` | Tien Dang | VFX Lead, Niagara, FluidNinja |
| `TyVo-VFX` | Ty Vo | Cutscene VFX, Lighting, Sequencer |
| `HoaNguyen-VFX` | Hoa Nguyen | Niagara FX |
| `TuanDangVFXAther` | Tuan Dang | VFX (Ather) |
| `QuangTranLightingArtAther` | Quang Tran | Lighting Art (Ather) |
| `VuDuong-CREATIVE` | Vu Duong | Creative/VFX |

## GraphQL Query Templates

### Check if issues have dates on timeline

```graphql
query {
  repository(owner:"{github.owner}", name:"{project.name}") {
    issue(number:{NUMBER}) {
      id number title
      projectItems(first:5) {
        nodes {
          id
          project { number }
          fieldValues(first:20) {
            nodes {
              ... on ProjectV2ItemFieldDateValue {
                date
                field { ... on ProjectV2Field { name } }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2Field { name } }
              }
            }
          }
        }
      }
    }
  }
}
```

### Set status (batch with aliases)

```graphql
mutation {
  s0: updateProjectV2ItemFieldValue(input: {
    projectId: "{github.project_node_id}",
    itemId: "{ITEM_ID}",
    fieldId: "{github.fields.status_id}",
    value: { singleSelectOptionId: "{github.status_options.todo}" }
  }) { projectV2Item { id } }
}
```

### Set start and end dates (batch with aliases)

```graphql
mutation {
  d0s: updateProjectV2ItemFieldValue(input: {
    projectId: "{github.project_node_id}",
    itemId: "{ITEM_ID}",
    fieldId: "{github.fields.start_date_id}",
    value: { date: "2026-02-16" }
  }) { projectV2Item { id } }
  d0e: updateProjectV2ItemFieldValue(input: {
    projectId: "{github.project_node_id}",
    itemId: "{ITEM_ID}",
    fieldId: "{github.fields.end_date_id}",
    value: { date: "2026-02-20" }
  }) { projectV2Item { id } }
}
```

### Set Issue Type

```graphql
mutation {
  updateIssue(input: {
    id: "{ISSUE_NODE_ID}",
    issueTypeId: "{github.issue_types.task}"
  }) { issue { id } }
}
```

## Windows Shell Notes

GraphQL queries with special characters fail in bash shell escaping on Windows. Always write queries to a temp file and use `cat`:

```bash
# Write query to temp file
# (use Write tool, not echo/heredoc)

# Execute via cat
gh api graphql -f query="$(cat /c/Users/{user}/AppData/Local/Temp/{file}.txt)"
```

Batch mutations use aliases to run multiple operations in one API call:
- `s0:`, `s1:`, `s2:` for status updates
- `d0s:`, `d0e:`, `d1s:`, `d1e:` for date updates (s=start, e=end)

Keep batches under 20 mutations per call to avoid `RESOURCE_LIMITS_EXCEEDED`.
