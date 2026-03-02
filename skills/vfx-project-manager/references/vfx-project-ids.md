# VFX Project IDs Reference

All IDs for GitHub Projects V2 API operations on the VFX team's project board.

## Repository

```
Owner: sipherxyz
Repo: s2
```

## Project #5 (S2 Huli Nine Tails Vengance)

```
Project Number: 5
Project Node ID: PVT_kwDOBR2Dpc4Azdrn
```

## Field IDs

| Field | ID | Type |
|-------|-----|------|
| Status | `PVTSSF_lADOBR2Dpc4AzdrnzgpQGXw` | SingleSelect |
| Start date | `PVTF_lADOBR2Dpc4AzdrnzgpQGdY` | Date |
| End date | `PVTF_lADOBR2Dpc4AzdrnzgpQGdc` | Date |
| Size | `PVTSSF_lADOBR2Dpc4AzdrnzgpQGdM` | SingleSelect |

## Status Options

| Status | Option ID |
|--------|-----------|
| To Do | `f75ad846` |
| Fixed | `7177aeee` |

> **Note:** "Done" status option ID is not yet captured. Query it if needed:
> ```bash
> gh api graphql -f query='{ node(id: "PVT_kwDOBR2Dpc4Azdrn") { ... on ProjectV2 { field(name: "Status") { ... on ProjectV2SingleSelectField { options { id name } } } } } }'
> ```

## Issue Type IDs

| Type | ID |
|------|-----|
| Task | `IT_kwDOBR2Dpc4A5bA_` |
| Bug | `IT_kwDOBR2Dpc4A5bBD` |
| Feature | `IT_kwDOBR2Dpc4A5bBE` |

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
  repository(owner:"sipherxyz", name:"s2") {
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
    projectId: "PVT_kwDOBR2Dpc4Azdrn",
    itemId: "{ITEM_ID}",
    fieldId: "PVTSSF_lADOBR2Dpc4AzdrnzgpQGXw",
    value: { singleSelectOptionId: "f75ad846" }
  }) { projectV2Item { id } }
}
```

### Set start and end dates (batch with aliases)

```graphql
mutation {
  d0s: updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOBR2Dpc4Azdrn",
    itemId: "{ITEM_ID}",
    fieldId: "PVTF_lADOBR2Dpc4AzdrnzgpQGdY",
    value: { date: "2026-02-16" }
  }) { projectV2Item { id } }
  d0e: updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOBR2Dpc4Azdrn",
    itemId: "{ITEM_ID}",
    fieldId: "PVTF_lADOBR2Dpc4AzdrnzgpQGdc",
    value: { date: "2026-02-20" }
  }) { projectV2Item { id } }
}
```

### Set Issue Type

```graphql
mutation {
  updateIssue(input: {
    id: "{ISSUE_NODE_ID}",
    issueTypeId: "IT_kwDOBR2Dpc4A5bA_"
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
