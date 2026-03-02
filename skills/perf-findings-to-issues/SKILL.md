---
name: perf-findings-to-issues
description: Create GitHub issues from Performance Analyzer findings JSON export
---

# Performance Findings to GitHub Issues

**Role:** Performance Issue Automation
**Scope:** Create batched GitHub issues from Performance Analyzer exports
**Platform:** Windows + gh CLI
**Repository:** sipherxyz/s2

## Objective

Read exported Performance Analyzer findings from JSON, group by category, and create GitHub issues for each category batch. Uses existing issue creation patterns from github-create-issue skill.

## Prerequisites

1. `gh` CLI authenticated: `gh auth status`
2. Exported findings JSON file path provided as argument
3. Project scope: `gh auth refresh -s project` (if needed)

## Input Format

JSON file exported by Performance Analyzer:

```json
{
  "exportTimestamp": "2026-01-11T10:30:00Z",
  "levelName": "L_Teaser_Temp_Bamboo_02",
  "analyzerVersion": "1.0.0",
  "categories": {
    "Material_ShaderComplexity": {
      "displayName": "Material Shader Complexity",
      "severity": "High",
      "findings": [
        {
          "assetPath": "/Game/Materials/M_Complex",
          "assetName": "M_Complex",
          "summary": "Material has 450 instructions (budget: 200)",
          "currentValue": 450,
          "budgetValue": 200,
          "estimatedImpactMs": 0.5,
          "issues": ["Excessive texture samples", "Complex math nodes"],
          "recommendations": ["Reduce instruction count", "Use shared samplers"]
        }
      ]
    }
  }
}
```

## Workflow

### Step 1: Validate Input

```powershell
# Check file exists
if (!(Test-Path $JsonPath)) { throw "Findings JSON not found: $JsonPath" }

# Validate gh auth
gh auth status
```

### Step 2: Parse Findings JSON

Read and parse the exported JSON file. Extract:
- Level name (for issue context)
- Categories with findings
- Total finding count per category

### Step 3: Create Issue per Category

For each category with findings:

**Title Format:**
```
perf_S02_[Category]_[LevelName]_[Date]
Example: perf_S02_Material-Shader-Complexity_L-Teaser-Bamboo_2026-01-11
```

**Labels:**
- `task` (always)
- `performance` (always)
- `Engineering` (always)
- Category-specific: `material`, `mesh`, `texture`, `lighting`, `scene`

**Body Format:**
```markdown
**Performance Analysis Findings**<br />
Level: {LevelName}<br />
Category: {CategoryDisplayName}<br />
Severity: {Severity}<br />
Finding Count: {Count}<br />
Exported: {Timestamp}

**Findings**<br />
{For each finding:}
- **{AssetName}** ({AssetPath})<br />
  Summary: {Summary}<br />
  Current: {CurrentValue} | Budget: {BudgetValue}<br />
  Impact: {EstimatedImpactMs}ms<br />
  Issues: {Issues joined}<br />
  Recommendations: {Recommendations joined}

**Acceptance Criteria**<br />
- [ ] Review all {Count} findings in this category
- [ ] Address Critical/High severity items first
- [ ] Verify fixes meet budget thresholds
- [ ] Re-run Performance Analyzer to confirm

**Size & Effort**<br />
**T-Shirt Size:** {Based on finding count: 1-3=S, 4-8=M, 9-15=L, 16+=XL}<br />
**Estimated Hours:** {Size-based estimate}

**Due Date**<br />
{Today + 7 days for High, +14 for Medium}
```

### Step 4: Create Issues via gh CLI

```bash
gh issue create \
  --title "perf_S02_Material-Shader-Complexity_L-Teaser-Bamboo_2026-01-11" \
  --body "$(cat <<'EOF'
{Body content}
EOF
)" \
  --label "task,performance,Engineering,material" \
  --milestone 16 \
  --repo sipherxyz/s2
```

### Step 5: Add to Project Board

```bash
gh project item-add 5 --owner sipherxyz --url {issue_url}
```

### Step 6: Output Results

```json
{
  "success": true,
  "issuesCreated": [
    {"category": "Material_ShaderComplexity", "issueNumber": 16200, "url": "..."},
    {"category": "Mesh_MissingLODs", "issueNumber": 16201, "url": "..."}
  ],
  "totalIssues": 2,
  "jsonPath": "path/to/findings.json"
}
```

## Category to Label Mapping

| Category Prefix | Labels |
|-----------------|--------|
| `Material_*` | `material`, `shader` |
| `Mesh_*` | `mesh`, `asset` |
| `Texture_*` | `texture`, `asset` |
| `Scene_*` | `level-design`, `scene` |
| `Lighting_*` | `lighting` |
| `Streaming_*` | `streaming`, `memory` |

## Milestone Mapping

| Severity | Milestone |
|----------|-----------|
| Critical | COMBAT (16) - immediate |
| High | alpha (9) |
| Medium | alpha (9) |
| Info | Backlog |

## Error Handling

- Missing JSON file: Error with path
- Empty categories: Skip, don't create empty issues
- gh auth failure: Provide auth instructions
- Label validation: Remove invalid labels, warn

## Invocation

From Claude Code:
```
claude -p "Use /github-workflow:perf-findings-to-issues to create GitHub issues from the Performance Analyzer export at: {path_to_json}"
```

## Legacy Metadata

```yaml
skill: perf-findings-to-issues
invoke: /github-workflow:perf-findings-to-issues
type: workflow
category: github
scope: project-root
```
