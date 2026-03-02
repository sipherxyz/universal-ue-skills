# Engineering Health Skill

Generate engineering team performance reports based on the 2x velocity framework.

## Usage

```bash
/engineering-health              # This week
/engineering-health week         # This week
/engineering-health month        # This month
/engineering-health 2025-12      # Specific month
/engineering-health week-3       # Week 3 of current month
/engineering-health last-week    # Previous week
```

## What It Does

1. **Gathers commits** using git email patterns (most accurate method)
2. **Calculates PRs** merged in the period
3. **Analyzes** against 2x velocity framework baselines
4. **Generates report** with top performers, needs attention, trends

## Tracking Method

Uses git email patterns instead of author names for accuracy:
```bash
git log --since="2025-12-01" --no-merges --format="%ae" | grep -iE "duy.tran@|dat.leduc@|..." | wc -l
```

## Outputs

- Console summary with key metrics
- Full report saved to `claude-agents/reports/engineering-health/`

## Baselines (from 2x Framework)

| Metric | Monthly | Weekly | Per Engineer |
|--------|---------|--------|--------------|
| Commits | 850 | 212 | 71 |
| PRs | 80 | 20 | 6.6 |

## Targets

| Week | Multiplier |
|------|------------|
| Week 1-2 | 1.2x |
| Week 3-4 | 1.4x |
| Week 5-6 | 1.6x |
| Week 7-8 | 1.8x |
| Week 9-12 | 2.0x |
| Month 4+ | 3.0x |

## Files

- `SKILL.md` - Main skill definition
- `templates/weekly-report.md` - Report template
- `README.md` - This file
- `claude-agents/team/eng-team.md` - Team roster with email patterns
- `claude-agents/team/engineering-framework-v2.md` - 2x velocity framework
