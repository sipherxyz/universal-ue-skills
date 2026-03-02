# Report Template

Template for generated bug screenshot reports.

---

## Template Content

```markdown
# Bug Screenshot Report

## Request Summary

| Field | Value |
|-------|-------|
| **Git Issue Code** | {issue_code} |
| **Bug It Go Code** | {bugitgo_command} |
| **Location** | {location} |
| **Branch** | {branch} |
| **Data Layer Set** | {data_layer} |
| **Device** | Local Machine |
| **Executed By** | {username} |
| **Timestamp** | {datetime} |
| **Execution Time** | {duration} |

---

## Screenshots

| # | Filename | Description | Status |
|---|----------|-------------|--------|
| 001 | Game_Epic.jpg | Game view at Epic settings | ✓ |
| 002 | Game_High.jpg | Game view at High settings | ✓ |
| ... | ... | ... | ... |
| 016 | Material_Issues.jpg | Material validation overlay | ⚠ Issues found |

---

## Material Issues Found

| Material Path | Issue Type | Details |
|---------------|------------|---------|
| /Game/Materials/M_Example | Deprecated Node | WorldAlignedTexture |

---

## Warnings & Errors

### Non-Critical Warnings
- ⚠ (List warnings here)

### Critical Errors
- None

---

## Configuration Used

- Screenshot Resolution: See screenshot_resolution.md
- LI Nesting Depth: {li_depth}
- Collision Color Scheme: See collision_colors.md
- Texture Standards: See texture_standards.md
```

---

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{issue_code}` | Bug tracking ID | `BUGFIX-1234` |
| `{bugitgo_command}` | Full BugItGo console command | `BugItGo -58230.5 5626.0 ...` |
| `{location}` | Level shortcut or full name | `loc1` |
| `{branch}` | Git branch name | `main` |
| `{data_layer}` | Selected realm set | `Default` |
| `{username}` | Windows username | `artist01` |
| `{datetime}` | ISO 8601 timestamp | `2025-01-15T14:30:00` |
| `{duration}` | Execution time | `4m 32s` |
| `{li_depth}` | Level Instance nesting depth | `3` |

---

## Notes

- Template uses markdown format for readability
- Screenshots table is auto-populated based on screenshot_naming.md
- Material issues table only appears if issues are found
- Edit this template to customize report format
