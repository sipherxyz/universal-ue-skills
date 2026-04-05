---
name: github-assign-issue
description: Recommend and auto-assign GitHub issues to engineers based on domain expertise matrix
---

## Configuration
This skill reads project-specific values from `skills.config.json` at the repository root.
Required keys: `github.repo`, `github.owner`, `github.project_number`, `milestones.*`, `team.*`
If not found, prompt the user for repository and project details.

# GitHub Issue Auto-Assignment Skill

**Role:** Issue Assignment Automation
**Scope:** Project-wide issue routing and assignment
**Platform:** Windows + gh CLI
**Repository:** {github.repo}

## Objective

Analyze GitHub issues and recommend (or auto-assign) appropriate engineers based on domain expertise matrix, issue labels, title keywords, and referenced file paths.

## Prerequisites

1. `gh` CLI authenticated: `gh auth status`
2. Engineer matrix file exists at `{project-root}/claude-agents/team/engineer-matrix.md`
3. Issue must be in the {github.repo} repository

## Dynamic Context Resolution

```
{CWD} = Current Working Directory
{ProjectRoot} = {project.root}
{MatrixPath} = {ProjectRoot}/claude-agents/team/engineer-matrix.md
{RepoOwner} = {github.owner}
{RepoName} = s2
{FallbackAssignee} = {team.principal.handle}
```

## Workflow

### Step 1: Parse Input

Accept GitHub issue URL or issue number:

```
Input formats:
- Full URL: https://github.com/{github.repo}/issues/123
- Short URL: {github.repo}#123
- Number only: 123 (assumes current repo)
```

**Extract issue number** using regex: `issues/(\d+)` or `#(\d+)` or `^(\d+)$`

### Step 2: Fetch Issue Details

```bash
gh issue view {number} --json number,title,body,labels,assignees --repo {github.repo}
```

**Extract:**
- Issue number, title, body text
- Current labels (array of label names)
- Current assignees (may be empty)

**Validate:**
- If issue not found → Error: "Issue #{number} not found"
- If issue already assigned → Warning: "Issue already assigned to @{user}. Override? [y/N]"
- If `--force` flag → Skip warning, proceed with reassignment

### Step 3: Load Engineer Matrix

Read matrix file from: `{ProjectRoot}/claude-agents/team/engineer-matrix.md`

Parse into data structures:
- **Engineers**: Map of username → {name, role, availability}
- **Domains**: Map of label → {primary, backup, keywords}
- **FilePatterns**: Map of pattern → domain

**Validate:**
- If matrix file missing → Error: "Engineer matrix not found at {path}. Run with --init-matrix to create template."
- If matrix malformed → Error: "Matrix parse error: {details}"

### Step 4: Detect Issue Domain

Multi-signal domain detection with weighted scoring:

**Signal 1: Labels (weight: 10)**
```
For each issue label:
  If label exists in Domains map:
    Add domain with weight = 10
```

**Signal 2: Title Keywords (weight: 5)**
```
For each domain in Domains map:
  For each keyword in domain.keywords:
    If keyword in issue.title (case-insensitive):
      Add domain with weight = 5
```

**Signal 3: File Path Patterns (weight: 3)**
```
Extract file paths from issue body using pattern: `/[A-Za-z_]+/[^\s]+\.(cpp|h|uasset)`
For each path:
  For each pattern in FilePatterns:
    If path matches pattern:
      Add domain with weight = 3
```

**Signal 4: Body Keywords (weight: 2)**
```
For each domain in Domains map:
  For each keyword in domain.keywords:
    If keyword in issue.body (case-insensitive, first 1000 chars):
      Add domain with weight = 2
```

**Aggregate:**
```
Sum weights per domain
Sort by weight descending
Primary domain = highest weight
```

### Step 5: Match Engineers

```
If total_weight >= 5:
  domain_mapping = Domains[primary_domain]
  primary_engineer = domain_mapping.primary
  backup_engineer = domain_mapping.backup

  If Engineers[primary_engineer].availability != 'U':
    recommended = primary_engineer
    reasoning = "Primary owner of '{domain}'"
    confidence = "HIGH" if weight >= 15 else "MEDIUM" if weight >= 10 else "LOW"
  Else If backup_engineer AND Engineers[backup_engineer].availability != 'U':
    recommended = backup_engineer
    reasoning = "Backup for '{domain}' (primary unavailable)"
    confidence = "MEDIUM"
  Else:
    recommended = {FallbackAssignee}
    reasoning = "Fallback owner (no available engineer for domain)"
    confidence = "LOW"
Else:
  recommended = {FallbackAssignee}
  reasoning = "Default owner (no domain match)"
  confidence = "DEFAULT"
```

### Step 6: Present Recommendation

```
═══════════════════════════════════════════════════════════════
ISSUE ASSIGNMENT RECOMMENDATION
═══════════════════════════════════════════════════════════════

Issue #123: Fix combo system animation desync
URL: https://github.com/{github.repo}/issues/123

Current Assignees: (none)
Labels: combat, Engineering, bug

═══════════════════════════════════════════════════════════════
ANALYSIS
═══════════════════════════════════════════════════════════════

Detected Domains:
  1. combat      (weight: 15) - Label + keyword "combo"
  2. system      (weight: 2)  - Body keyword "framework"

Signal Breakdown:
  - Label "combat"     → combat (+10)
  - Title "combo"      → combat (+5)
  - Body "framework"   → system (+2)

═══════════════════════════════════════════════════════════════
RECOMMENDATION
═══════════════════════════════════════════════════════════════

Assignee:   @DuyTranSipher (Duy Tran) - Game Engineer
Reasoning:  Primary owner of 'combat' domain
Confidence: HIGH

Backup:     @{team.principal.handle} (Loc Bui) - Principal Engineer

═══════════════════════════════════════════════════════════════

Options:
  1. Assign to @DuyTranSipher
  2. Assign to @{team.principal.handle} (backup)
  3. Select different assignee
  4. Skip assignment

Your choice (1/2/3/4): _
```

**If `--quick` flag:** Skip prompt, auto-assign to recommended.

### Step 7: Execute Assignment

If user selects option 1 or 2 (or `--quick` mode):

```bash
gh issue edit {number} --add-assignee {username} --repo {github.repo}
```

**Validate response:**
- Success → Proceed to Step 8
- Failure → Error: "Assignment failed: {error}"

### Step 8: Return Result

```
Assignment complete!

Issue #123: Fix combo system animation desync
Assigned to: @DuyTranSipher (Duy Tran)
Domain: combat
Confidence: HIGH

View issue: https://github.com/{github.repo}/issues/123
```

**Return Values (for programmatic use):**
```
IssueNumber: 123
AssignedTo: DuyTranSipher
Domain: combat
Confidence: HIGH
```

---

## Error Handling

### Error: Issue Not Found

```
Error: Issue #9999 not found in {github.repo}

Verify issue exists: gh issue view 9999 --web --repo {github.repo}
```

### Error: Matrix Not Found

```
Error: Engineer matrix not found

Expected: {project.root}\claude-agents\team\engineer-matrix.md

Run: /github-assign-issue --init-matrix
```

### Error: Already Assigned

```
Warning: Issue #123 already assigned to @existinguser

Options:
  1. Add @DuyTranSipher as additional assignee
  2. Replace with @DuyTranSipher
  3. Keep current assignment
  4. Cancel

Your choice: _
```

### Error: Engineer Unavailable

```
Warning: Primary engineer @DuyTranSipher is unavailable (U)

Falling back to backup: @{team.principal.handle}

Continue with backup assignment? (y/N): _
```

---

## Advanced Usage

### Dry Run Mode

Preview without executing:

```bash
/github-assign-issue 123 --dry-run
```

Shows recommendation but does not modify issue.

### Quick Mode

Auto-assign without confirmation:

```bash
/github-assign-issue 123 --quick
```

Immediately assigns to recommended engineer.

### Force Mode

Override existing assignment:

```bash
/github-assign-issue 123 --force
```

Skips "already assigned" warning.

### Batch Mode

Process multiple issues:

```bash
/github-assign-issue --batch 100,101,102,103
```

**Workflow:**
1. Fetch all issues in parallel
2. Generate recommendations for each
3. Present summary table:

```
═══════════════════════════════════════════════════════════════
BATCH ASSIGNMENT PREVIEW
═══════════════════════════════════════════════════════════════

| Issue | Title                    | Domain  | Assignee         | Confidence |
|-------|--------------------------|---------|------------------|------------|
| #100  | Fix combo animation      | combat  | @DuyTranSipher   | HIGH       |
| #101  | UI menu flicker          | UXUI    | @HungLeSipher    | MEDIUM     |
| #102  | AI pathing stuck         | ai      | @KhoaLeSipher    | HIGH       |
| #103  | General cleanup          | -       | @{team.principal.handle}       | DEFAULT    |

═══════════════════════════════════════════════════════════════

Options:
  1. Assign all as shown
  2. Review individually
  3. Cancel

Your choice: _
```

### Initialize Matrix

Create template matrix file:

```bash
/github-assign-issue --init-matrix
```

Creates `claude-agents/team/engineer-matrix.md` with default template if not exists.

### Update Availability

Quick availability update:

```bash
/github-assign-issue --set-availability @DuyTranSipher U
```

Updates engineer's status to Unavailable in matrix file.

---

## Matching Algorithm Details

### Weight Calculation

```
Domain Score = (Label Matches × 10) + (Title Keywords × 5) + (File Paths × 3) + (Body Keywords × 2)
```

### Confidence Levels

| Score | Confidence | Description |
|-------|------------|-------------|
| >= 15 | HIGH | Strong signal (label + keyword) |
| 10-14 | MEDIUM | Single strong signal (label only) |
| 5-9 | LOW | Weak signals (keywords/paths only) |
| < 5 | DEFAULT | Fallback to @{team.principal.handle} |

### Tie-Breaking Rules

1. If two domains have equal weight, prefer the one with label match
2. If still tied, prefer alphabetically first domain
3. If engineer is Primary for multiple matched domains, boost confidence

---

## Integration with Other Skills

### Called After github-create-issue

After creating an issue, optionally invoke this skill:

```
After issue creation:
  If user wants assignment:
    Invoke /github-assign-issue {IssueNumber} --quick
```

### Called by Agentic Bug Fix System

When processing bugs, auto-assign for tracking:

```
After bug analysis:
  Invoke /github-assign-issue {IssueNumber}
  Log assignment for sprint tracking
```

---

## Success Criteria

- [ ] Parses GitHub issue URL or number
- [ ] Fetches issue details via gh CLI
- [ ] Loads and parses engineer matrix
- [ ] Detects domain from labels (weight: 10)
- [ ] Detects domain from title keywords (weight: 5)
- [ ] Detects domain from file path patterns (weight: 3)
- [ ] Detects domain from body keywords (weight: 2)
- [ ] Aggregates signals with correct weights
- [ ] Matches engineer based on domain ownership
- [ ] Checks engineer availability
- [ ] Falls back to backup or @{team.principal.handle}
- [ ] Presents recommendation with confidence level
- [ ] Executes assignment via gh CLI
- [ ] Handles missing matrix file (--init-matrix)
- [ ] Handles no domain match (fallback to @{team.principal.handle})
- [ ] Handles all engineers unavailable
- [ ] Handles already assigned issues
- [ ] Supports --dry-run mode
- [ ] Supports --quick mode
- [ ] Supports --force mode
- [ ] Supports --batch mode

---

## Notes

- All `gh` commands target `--repo {github.repo}` explicitly
- Matrix file is plain markdown for easy manual editing
- Availability must be manually updated by team leads
- Fallback owner is @{team.principal.handle} for all unmatched issues
- No Claude attribution footer per CLAUDE.md guidelines

## Legacy Metadata

```yaml
skill: github-assign-issue
invoke: /github-workflow:github-assign-issue
type: workflow
category: github
scope: project-root
```
