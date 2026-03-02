---
name: engineering-health
description: Generate engineering team performance reports based on 2x velocity framework
---

# Engineering Health Report Skill

**Role:** Engineering Metrics Analyst
**Scope:** Team performance tracking and 2x velocity measurement (3x after Month 4+)
**Reference:** `claude-agents/team/engineering-framework-v2.md`
**Platform:** Windows (git + gh CLI)

## Objective

Generate engineering team performance reports by:
1. Gathering commits per engineer using git email patterns (most accurate method)
2. Analyzing against 2x velocity framework baselines
3. Generating a formatted report from template

## Prerequisites

1. Git repository with commit history
2. `gh` CLI authenticated (for PR data)
3. Team roster at `claude-agents/team/eng-team.md`
4. Framework at `claude-agents/team/engineering-framework-v2.md`

## Dynamic Variables

```
{CWD} = D:\s2
{TeamFile} = claude-agents/team/eng-team.md
{FrameworkFile} = claude-agents/team/engineering-framework-v2.md
{ReportsDir} = claude-agents/reports/engineering-health
{Today} = Current date (YYYY-MM-DD)
```

## Invocation

```
/engineering-health [period]

Examples:
/engineering-health              # This week
/engineering-health week         # This week
/engineering-health month        # This month
/engineering-health 2025-12      # December 2025
/engineering-health week-3       # Week 3 of current month
```

## Workflow

### Step 1: Parse Period Input

**Default:** Current week (Monday to Sunday)

| Input | Date Range |
|-------|------------|
| `week` or empty | Current Monday to today |
| `month` | First of current month to today |
| `YYYY-MM` | Full month (e.g., 2025-12 = Dec 1-31) |
| `week-N` | Week N of current month (1-5) |
| `last-week` | Previous Monday to Sunday |
| `last-month` | Previous full month |

**Calculate:**
```bash
# For "this week" (Monday start)
START_DATE=$(date -d "last monday" +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

# For "this month"
START_DATE=$(date +%Y-%m-01)
END_DATE=$(date +%Y-%m-%d)
```

### Step 2: Load Engineering Team Roster

Read team from `{TeamFile}` (claude-agents/eng-team.md):

**Engineering Team (12 members) - EMAIL PATTERNS:**

| Engineer | Git Email Pattern | GitHub Handle | Domain |
|----------|-------------------|---------------|--------|
| Duy Tran | `duy.tran@atherlabs.com` | @DuyTranSipher | Combat |
| Dat Le | `dat.leduc@atherlabs` | @DatLeDucGEAther | AI |
| Khoa Le | `khoa.le@atherlabs` | @KhoaLeAther | Enemies/Bosses |
| Long Do | `long.do@atherlabs` | @LongDoGEAther | Gameplay |
| Loc Bui | `buihuuloc` | @buihuuloc | Lead |
| An Le | `an.le@sipher.xyz` | @AnLe-Sipher | Audio |
| Nam Nguyen | `nam.nguyen@atherlabs\|ngqnam@gmail` | @namnq-sipher | Cutscene |
| Khuong Thang | `khuong.thang@sipher.xyz` | @KhuongThang-Sipher | UI |
| Thang Nguyen | `thang.trinh@atherlabs` | @ThangtrinhGEatherlabs | Rendering |
| Phuong Le | `phuong.le@sipher.vn` | @phuonglesipher | AI/Perf |
| Vi Nghiem | `nghiem.vu@sipher` | @sipher-nghiemvu | NavMesh |
| Nghia Vo | `nghia.vo@atherlabs.com` | @NghiaVoGameEngineerAther | Camera |

**IMPORTANT:** Email patterns are the most accurate method for commit counting.
**6-Month Total (Jun-Dec 2025):** 5,098 commits

### Step 3: Gather Commit Data

For each engineer, run:

```bash
# Commits count using email pattern (no merges)
git log --since="{START_DATE}" --until="{END_DATE}" --no-merges --format="%ae" | grep -iE "{EMAIL_PATTERN}" | wc -l

# C++ files touched
git log --since="{START_DATE}" --until="{END_DATE}" --no-merges --format="%ae %H" | grep -iE "{EMAIL_PATTERN}" | cut -d' ' -f2 | xargs -I{} git show --name-only --pretty=format: {} | grep -E "\.(cpp|h)$" | wc -l
```

**Collect for each engineer:**
- `commits`: Total commit count
- `cpp_files`: C++ files touched
- `domain`: Primary domain from roster

**Calculate totals:**
```bash
# Total team commits using all email patterns
git log --since="{START_DATE}" --until="{END_DATE}" --no-merges --format="%ae" | grep -iE "duy.tran@|dat.leduc@|khoa.le@|long.do@|buihuuloc|an.le@sipher|nam.nguyen@|ngqnam@|khuong.thang@|thang.trinh@|phuong.le@sipher|nghiem.vu@|nghia.vo@" | wc -l
```

### Step 4: Gather PR Data

```bash
# Team PRs merged in period
gh pr list --state merged --limit 500 --json author,mergedAt --jq "[.[] | select(.mergedAt >= \"{START_DATE}\" and .mergedAt <= \"{END_DATE}\")] | group_by(.author.login) | map({author: .[0].author.login, count: length})"
```

**Filter to engineering team handles only.**

### Step 5: Calculate Metrics

**Baseline (from framework):**
- Monthly commits baseline: 850 (engineering team, email-based)
- Monthly PRs baseline: 80
- Weekly commits baseline: 212 (850/4)
- Weekly PRs baseline: 20 (80/4)
- Per-engineer monthly: 71 commits, 6.6 PRs

**Calculate:**
```
period_days = END_DATE - START_DATE
baseline_commits = (850 / 30) * period_days
baseline_prs = (80 / 30) * period_days

velocity_multiplier = actual_commits / baseline_commits
pr_multiplier = actual_prs / baseline_prs
```

**Target thresholds:**
| Week | Commits Multiplier | Notes |
|------|-------------------|-------|
| Week 1-2 | 1.2x | Accelerating |
| Week 3-4 | 1.4x | Momentum building |
| Week 5-6 | 1.6x | Mid-point |
| Week 7-8 | 1.8x | Approaching target |
| Week 9-12 | 2.0x | Full velocity |
| Month 4+ | 3.0x | Sustained |

### Step 6: Analyze Performance

**Per-engineer analysis:**
```
For each engineer:
  expected = baseline_per_engineer * (period_days / 30)
  actual = engineer.commits
  performance = actual / expected

  status:
    >= 1.5x: "Exceeding"
    >= 1.0x: "On Track"
    >= 0.7x: "Below Target"
    < 0.7x: "Needs Attention"
```

**Team analysis:**
```
top_performers = engineers sorted by commits DESC, take 3
needs_attention = engineers with performance < 0.7x
cpp_ratio = total_cpp_files / total_commits
```

### Step 7: Generate Report

Use template at `./templates/weekly-report.md`

**Output location:** `{ReportsDir}/{PERIOD}-report.md`

Example: `claude-agents/reports/engineering-health/2025-12-week4-report.md`

### Step 8: Display Summary

```
+----------------------------------------------------------------+
| ENGINEERING HEALTH REPORT                                      |
| Period: {START_DATE} to {END_DATE}                             |
+----------------------------------------------------------------+
| Team Commits: {TOTAL} / Baseline: {BASELINE} = {MULTIPLIER}x   |
| Team PRs: {PR_TOTAL} / Baseline: {PR_BASELINE} = {PR_MULT}x    |
| Status: {ON_TRACK | AHEAD | BEHIND}                            |
+----------------------------------------------------------------+
| TOP PERFORMERS                                                 |
| 1. {NAME}: {COMMITS} commits ({MULT}x)                         |
| 2. {NAME}: {COMMITS} commits ({MULT}x)                         |
| 3. {NAME}: {COMMITS} commits ({MULT}x)                         |
+----------------------------------------------------------------+
| NEEDS ATTENTION                                                |
| - {NAME}: {COMMITS} commits ({MULT}x) - {REASON}               |
+----------------------------------------------------------------+

Report saved to: {OUTPUT_PATH}
```

## Git Commands Reference

```bash
# All team commits using email patterns (recommended)
git log --since="2025-12-01" --until="2025-12-31" --no-merges --format="%ae" | grep -iE "duy.tran@|dat.leduc@|khoa.le@|long.do@|buihuuloc|an.le@sipher|nam.nguyen@|ngqnam@|khuong.thang@|thang.trinh@|phuong.le@sipher|nghiem.vu@|nghia.vo@" | wc -l

# Single engineer commits
git log --since="2025-12-01" --no-merges --format="%ae" | grep -iE "duy.tran@atherlabs" | wc -l

# Breakdown by engineer
git log --since="2025-12-01" --no-merges --format="%ae" | grep -iE "duy.tran@|dat.leduc@|khoa.le@|long.do@|buihuuloc|an.le@sipher|nam.nguyen@|ngqnam@|khuong.thang@|thang.trinh@|phuong.le@sipher|nghiem.vu@|nghia.vo@" | sort | uniq -c | sort -rn

# PRs merged by team
gh pr list --state merged --limit 500 --json author,mergedAt --jq "[.[] | select(.mergedAt >= \"2025-12-01\")] | group_by(.author.login) | map({author: .[0].author.login, count: length}) | sort_by(-.count)"
```

## Error Handling

### No commits found
```
Warning: No commits found for {ENGINEER} in period {START} to {END}
Possible reasons:
- Engineer on PTO
- Working on non-code tasks
- Using different email address (check git log --format="%ae" | grep -i "{name}")
```

### gh CLI not authenticated
```
Error: GitHub CLI not authenticated
Solution: Run `gh auth login` and try again
```

### Invalid period format
```
Error: Invalid period format "{INPUT}"
Valid formats:
- week, month
- YYYY-MM (e.g., 2025-12)
- week-N (e.g., week-3)
- last-week, last-month
```

## Example Session

```
User: /engineering-health

Analyzing engineering team performance...
Period: 2025-12-23 to 2025-12-30 (7 days)

Gathering commits by email pattern...
- duy.tran@atherlabs.com: 45 commits
- dat.leduc@atherlabs: 38 commits
- khoa.le@atherlabs: 25 commits
- long.do@atherlabs: 22 commits
- buihuuloc: 20 commits
- an.le@sipher.xyz: 18 commits
- nam.nguyen@atherlabs: 15 commits
- khuong.thang@sipher.xyz: 12 commits
- thang.trinh@atherlabs: 10 commits
- phuong.le@sipher.vn: 8 commits
- nghiem.vu@sipher: 5 commits
- nghia.vo@atherlabs: 4 commits

Team Total: 222 commits
Baseline (7 days): 198 commits
Velocity: 1.12x

+----------------------------------------------------------------+
| ENGINEERING HEALTH REPORT                                      |
| Period: 2025-12-23 to 2025-12-30                               |
+----------------------------------------------------------------+
| Team Commits: 222 / Baseline: 198 = 1.12x                      |
| Status: ON TRACK (Month 1 target: 1.4x)                        |
+----------------------------------------------------------------+
| TOP PERFORMERS                                                 |
| 1. Duy Tran: 45 commits (1.88x)                                |
| 2. Dat Le: 38 commits (1.58x)                                  |
| 3. Khoa Le: 25 commits (1.04x)                                 |
+----------------------------------------------------------------+
| NEEDS ATTENTION                                                |
| - Nghia Vo: 4 commits (0.33x) - Below baseline                 |
| - Vi Nghiem: 5 commits (0.42x) - Below baseline                |
+----------------------------------------------------------------+

Report saved to: claude-agents/reports/engineering-health/2025-12-week4-report.md
```

## Related Files

| File | Purpose |
|------|---------|
| `claude-agents/team/eng-team.md` | Engineering team roster with email patterns |
| `claude-agents/team/engineering-framework-v2.md` | 2x velocity framework and baselines |
| `claude-agents/reports/engineering-health/` | Generated reports |
| `./templates/` | Report templates |

## Legacy Metadata

```yaml
skill: engineering-health
type: metrics
category: engineering
scope: project-root
```
