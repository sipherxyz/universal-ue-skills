---
name: vfx-project-manager
description: Manage VFX team issues on GitHub Projects - timeline scheduling, status updates, member commit checks, bulk assign. Use when managing VFX team project board, adding issues to timeline, checking member progress, or bulk-updating issue fields.
---

# VFX Project Manager

**Role:** VFX Team Project Board Automation
**Scope:** GitHub Projects V2 management for VFX team
**Platform:** Windows + gh CLI + GraphQL API
**Repository:** sipherxyz/s2
**Project:** #5 (S2 Huli Nine Tails Vengance)

## Critical Rules

1. **ALWAYS end by refreshing and opening the dashboard** — no exceptions, every action must finish with:
   ```bash
   node claude-agents/vfx-dashboard/refresh-vfx-dashboard.js
   start "" "claude-agents/vfx-dashboard/vfx-dashboard-v5.html"
   ```
2. **NEVER set future dates** — only use actual commit dates, or leave dates empty
3. **Auto-create issues for orphan commits** — if a member has commits with no matching task, create one

## Objective

Automate repetitive GitHub Projects operations for the VFX team: scheduling issues on timeline, bulk status changes, member progress checks, and issue assignment. Replaces manual GraphQL mutations with a single skill.

## Prerequisites

1. `gh` CLI authenticated: `gh auth status`
2. Reference IDs loaded from: `references/vfx-project-ids.md`

## Dynamic Context Resolution

```
{CWD} = Current Working Directory
{RepoOwner} = sipherxyz
{RepoName} = s2
{ProjectNum} = 5
{ProjectId} = PVT_kwDOBR2Dpc4Azdrn
{TempDir} = C:\Users\{user}\AppData\Local\Temp
```

Load all field IDs and member handles from `references/vfx-project-ids.md`.

## Usage

```
/github-workflow:vfx-project-manager                          # FULL SYNC: all members → update timeline → refresh dashboard
/github-workflow:vfx-project-manager timeline <member>        # Single member timeline sync
/github-workflow:vfx-project-manager check <member>           # Check commits vs tasks for member
/github-workflow:vfx-project-manager assign <issue-numbers> <member>
/github-workflow:vfx-project-manager status <issue-numbers> <status>
```

---

## Action: timeline

**Purpose:** Find all open issues assigned to a member that are missing timeline dates, then add them to the Project #5 timeline.

### Step 1: Fetch Open Issues

```bash
gh issue list -R sipherxyz/s2 --assignee {member} --state open --limit 100 --json number,title,labels,state
```

### Step 2: Check Which Issues Have Dates

For each issue, query Project #5 field values using GraphQL. Batch up to 15 issues per query using aliases:

```graphql
query {
  i0: repository(owner:"sipherxyz", name:"s2") {
    issue(number:{N}) {
      id number title
      projectItems(first:5) {
        nodes {
          id project { number }
          fieldValues(first:20) {
            nodes {
              ... on ProjectV2ItemFieldDateValue {
                date field { ... on ProjectV2Field { name } }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name field { ... on ProjectV2Field { name } }
              }
            }
          }
        }
      }
    }
  }
  i1: ...
}
```

Write query to temp file, execute via:
```bash
gh api graphql -f query="$(cat /c/Users/{user}/AppData/Local/Temp/{file}.txt)"
```

### Step 3: Identify Missing Issues

Filter for issues where:
- Not in Project #5 at all, OR
- In Project #5 but no Start date / End date values

### Step 4: Add to Project (if needed)

For issues not yet in Project #5:
```bash
gh project item-add 5 --owner sipherxyz --url https://github.com/sipherxyz/s2/issues/{number}
```

### Step 5: Get Project Item IDs

Query the newly-added items to get their project item IDs (needed for field mutations).

### Step 5.5: Check Git History for Each Issue

**CRITICAL:** Before scheduling dates, check if the member already has commits related to each issue.

```bash
git log --author="{member}" --since="1 week ago" --oneline --format="%h %ad %s" --date=short
```

Cross-reference commit messages with issue titles/keywords. If commits exist:
- **Use commit dates** as Start date (first commit) and End date (last commit)
- Set status to **Fixed** or **Done** (not To Do)

**NEVER set future dates.** If no matching commits → leave dates empty (user will schedule manually).

### Step 5.6: Create Issues for Orphan Commits

After cross-referencing commits with issues, identify **orphan commits** — commits that don't match any open or closed issue.

**Group orphan commits by topic** using commit message tags/keywords:
```
[Lighting] SH360, Desert SH070, Trailer C100  →  1 issue about lighting work
[VFX] Trailer Shot 050 060 090                →  1 issue about trailer VFX
```

For each orphan group, create a new issue:

```bash
gh issue create --repo sipherxyz/s2 \
  --title "task_S02_VFX_{topic_slug}" \
  --body "Auto-created from orphan commits for {member}.\n\nCommits:\n- {hash} {date} {message}\n- ..." \
  --assignee {member} \
  --label vfx
```

Then:
1. Add the new issue to Project #5: `gh project item-add 5 --owner sipherxyz --url {issue_url}`
2. Set dates from commit range (first commit date → last commit date)
3. Set status = Fixed (work already done)
4. Set Issue Type = Task via GraphQL

**Title format:** `task_S02_VFX_{area}_{short_description}` using lowercase + underscores. Derive from commit message tags:
- `[Lighting] Trailer C100` → `task_S02_VFX_lighting_trailer_c100`
- `[VFX] Shot 290 300 Trailer` → `task_S02_VFX_cine_trailer_shot_290_300`

### Step 6: Set Status and Dates

For issues **with commits** (already worked on):
```
Start date = date of first related commit
End date = date of last related commit
Status = Done or Fixed
```

For issues **without commits** (no work yet):
```
DO NOT set any dates — leave Start date and End date empty.
Status = To Do
```
The user will manually schedule future work on the GitHub Projects timeline.

Use aliases for batch mutations:
- `s0:`, `s1:` ... for status = To Do
- `d0s:`, `d0e:`, `d1s:`, `d1e:` ... for start/end dates

Keep under 20 mutations per API call to avoid rate limits.

### Step 7: Add Labels

Ensure all issues have `vfx` label:
```bash
gh issue edit {number} --add-label vfx --repo sipherxyz/s2
```

### Step 8: Report

Present a summary table:

```
Added to timeline: {count} issues for {member}

| # | Title | Status | Timeline |
|---|-------|--------|----------|
| #123 | task name | To Do | Feb 16 - Feb 20 |
| #456 | task name | To Do | Feb 23 - Feb 27 |
```

### Step 9: Refresh & Open Dashboard

**ALWAYS** refresh and open the dashboard after timeline changes:

```bash
node claude-agents/vfx-dashboard/refresh-vfx-dashboard.js
start "" "claude-agents/vfx-dashboard/vfx-dashboard-v5.html"
```

---

## Action: check

**Purpose:** Compare a member's git commits against their assigned tasks to find gaps (orphan commits without tasks, or stale open issues).

### Step 1: Fetch Commits

```bash
git log --author="{member}" --since="1 week ago" --oneline --format="%h %ad %s" --date=short
```

Also try common name variations (e.g., "TyVo" → also search "Ty Vo", "ty.vo").

### Step 2: Fetch Issues

```bash
gh issue list -R sipherxyz/s2 --assignee {member} --state open --limit 50 --json number,title,labels,state,createdAt
gh issue list -R sipherxyz/s2 --assignee {member} --state closed --limit 50 --json number,title,labels,state,closedAt
```

### Step 3: Check Project Status

Query open issues for their Project #5 status and dates (same as timeline Step 2).

### Step 4: Analyze

Group commits by work area (from commit message tags like `[VFX]`, `[Lighting]`, `[Tool]`).

Cross-reference with issues:
- **Orphan commits:** Commits with no matching open/closed issue
- **Stale issues:** Open issues marked "Done" in project but not closed
- **Missing from timeline:** Open issues without dates
- **Issues without project:** Open issues not in Project #5

### Step 5: Auto-Create Issues for Orphan Commits

If orphan commits are found (commits with no matching issue), **automatically create issues** following the same logic as timeline Step 5.6:

1. Group orphan commits by topic
2. Create issue with `task_S02_VFX_{topic}` title
3. Assign to member, add `vfx` label
4. Add to Project #5, set dates from commit range, status = Fixed

### Step 6: Report

```
Member: {member}
Commits (last week): {count}
Open issues: {count}
Closed issues: {count}

Work Areas:
| Area | Period | Commits | Covered by Issue |
|------|--------|---------|------------------|
| Baiwuchang cutscene | Feb 3-10 | 12 | #19685 |
| Tiger OPN | Jan 22-Feb 2 | 15 | #18671 (closed) |
| Lighting SH360 | Feb 11 | 2 | ⚡ NEW #19800 (auto-created) |

Issues:
| # | Title | Project | Status | Dates | Flag |
|---|-------|---------|--------|-------|------|
| #19685 | bwc cutscene | Yes | Done | Feb 3-8 | OPEN but Done - should close? |
| #18327 | tiger lighting | No | - | - | NOT on timeline |
| #19800 | lighting_sh360 | Yes | Fixed | Feb 11 | ⚡ AUTO-CREATED |
```

---

## Action: assign

**Purpose:** Bulk assign issues to a member with labels and add to Project #5.

### Input

```
/github-workflow:vfx-project-manager assign 19620,19625,19588 TienDang-VFX
```

### Step 1: For Each Issue

```bash
gh issue edit {number} --add-assignee {member} --add-label vfx --repo sipherxyz/s2
gh project item-add 5 --owner sipherxyz --url https://github.com/sipherxyz/s2/issues/{number}
```

### Step 2: Set Issue Type

Query issue node ID, then set Issue Type = Task via GraphQL `updateIssue` mutation.

### Step 3: Report

```
Assigned {count} issues to @{member}:
- #{n1}: {title}
- #{n2}: {title}

All added to Project #5 with label: vfx
```

---

## Action: status

**Purpose:** Bulk update status for multiple issues on Project #5.

### Input

```
/github-workflow:vfx-project-manager status 19620,19625 todo
/github-workflow:vfx-project-manager status 19620,19625 fixed
```

Status values: `todo` → f75ad846, `fixed` → 7177aeee

### Step 1: Get Project Item IDs

Query each issue's project item ID via GraphQL.

### Step 2: Batch Update

Build mutation with aliases:
```graphql
mutation {
  s0: updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOBR2Dpc4Azdrn",
    itemId: "{ITEM_ID}",
    fieldId: "PVTSSF_lADOBR2Dpc4AzdrnzgpQGXw",
    value: { singleSelectOptionId: "{STATUS_ID}" }
  }) { projectV2Item { id } }
  ...
}
```

### Step 3: Report

```
Updated {count} issues to status: {status}
- #{n1}: {title}
- #{n2}: {title}
```

---

## Action: (no args) — Full Sync All Members

**Purpose:** Run the complete workflow for ALL VFX members: check commits, sync timeline, fix missing data, then refresh and open dashboard.

### Step 1: For Each VFX Member (loop)

Load member list from `references/vfx-project-ids.md`:
```
TienDang-VFX, TyVo-VFX, HoaNguyen-VFX, TuanDangVFXAther, QuangTranLightingArtAther, VuDuong-CREATIVE
```

For each member, run **timeline** action (Steps 1-9 from the timeline section above):
1. Fetch open issues for this member
2. Check which issues have dates on Project #5
3. Identify issues missing from timeline (no dates or not in project)
4. Add missing issues to Project #5
5. Check git commits to determine correct dates
6. **Create issues for orphan commits** (commits with no matching task → auto-create issue)
7. Set status and dates (past dates for done work, no dates for unstarted work)
8. Add `vfx` label

### Step 2: Summary Report

After processing all members, show combined report:

```
═══════════════════════════════════════
VFX PROJECT SYNC COMPLETE
═══════════════════════════════════════

| Member | Open | Synced | Added | Already OK |
|--------|------|--------|-------|------------|
| TienDang-VFX | 40 | 40 | 2 new | 38 |
| TyVo-VFX | 6 | 6 | 3 new | 3 |
| HoaNguyen-VFX | 3 | 3 | 1 new | 2 |
| TuanDangVFXAther | 5 | 5 | 0 | 5 |
| QuangTranLightingArtAther | 2 | 2 | 0 | 2 |
| VuDuong-CREATIVE | 1 | 1 | 0 | 1 |

Total: {N} issues synced, {M} newly added to timeline
```

### Step 3: Refresh & Open Dashboard (MANDATORY)

**ALWAYS** run these two commands at the end — do NOT skip:

```bash
node claude-agents/vfx-dashboard/refresh-vfx-dashboard.js
```

Then open in browser:

```bash
start "" "claude-agents/vfx-dashboard/vfx-dashboard-v5.html"
```

### Step 4: Final Output

```
Dashboard refreshed and opened!
File: claude-agents/vfx-dashboard/vfx-dashboard-v5.html
```

---

## Error Handling

### Rate Limit (RESOURCE_LIMITS_EXCEEDED)

Split batch mutations into smaller chunks (max 15-18 mutations per call). Wait 2 seconds between calls.

### Issue Not in Project

If an issue is not in Project #5 when trying to set fields:
1. Add it first: `gh project item-add 5 --owner sipherxyz --url {url}`
2. Re-query to get the new project item ID
3. Retry the field mutation

### Shell Escaping on Windows

Never pass GraphQL queries as inline strings in bash. Always:
1. Write query to temp file using Write tool
2. Execute: `gh api graphql -f query="$(cat /c/Users/{user}/AppData/Local/Temp/{file}.txt)"`
3. Clean up temp file after

### Missing Label

If `gh issue edit --add-label` fails because label doesn't exist, log warning and continue. Don't block the workflow.

---

## Success Criteria

- [ ] Parses action and args from invocation
- [ ] Loads reference IDs from bundled references/vfx-project-ids.md
- [ ] `timeline`: Finds issues without dates, schedules across weeks
- [ ] `timeline`: Adds missing issues to Project #5
- [ ] `timeline`: Sets status=To Do and start/end dates via batch GraphQL
- [ ] `timeline`: Adds `vfx` label to all issues
- [ ] `check`: Fetches commits and issues for a member
- [ ] `check`: Identifies orphan commits, stale issues, timeline gaps
- [ ] `assign`: Bulk assigns with labels and project membership
- [ ] `assign`: Sets Issue Type = Task
- [ ] `status`: Bulk updates status via batch GraphQL
- [ ] `overview`: Shows team-wide summary
- [ ] Handles rate limits by splitting batches
- [ ] Uses temp files for GraphQL on Windows

---

## Notes

- All `gh` commands target `--repo sipherxyz/s2` explicitly
- GraphQL mutations must use temp files on Windows (shell escaping)
- Batch mutations max 18 per call to avoid rate limits
- NEVER set future dates — only use actual commit dates or leave empty
- VFX member list maintained in references/vfx-project-ids.md
- Git author names differ from GitHub handles — always try multiple search terms:

| GitHub Handle | Git Author(s) |
|--------------|---------------|
| TienDang-VFX | TienDang-VFX, Cinematic, miinhtien, DANG MINH TIEN |
| TyVo-VFX | Ty Vo |
| HoaNguyen-VFX | HoaNguyen-VFX |
| TuanDangVFXAther | TuanDang |
| QuangTranLightingArtAther | Tran Duy Quang |
| VuDuong-CREATIVE | yuduong |

## Legacy Metadata

```yaml
skill: vfx-project-manager
invoke: /github-workflow:vfx-project-manager
type: workflow
category: github
scope: project-root
```
