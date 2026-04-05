# Output Location Settings

Defines where screenshot reports are saved.

---

## Primary Storage

| Setting | Value |
|---------|-------|
| Type | Network Share |
| Path | `{network.artteam_share}` (from `skills.config.json`) |
| Access | Read/Write for Art Team |

---

## Fallback Storage

Used when network share is unavailable.

| Setting | Value |
|---------|-------|
| Type | Local |
| Path | `{Project}/Saved/BugScreenshots/` |
| Note | Sync to network manually later |

---

## Folder Structure

```
{output_path}/
└── {issue_code}_{branch}_{location}/
    ├── report.md
    ├── 001_Game_Epic.jpg
    ├── 002_Game_High.jpg
    ├── ...
    └── 016_Material_Issues.jpg
```

---

## Cleanup Policy

| Setting | Value |
|---------|-------|
| Auto-delete after | 90 days |
| Archive location | `{network.archive_share}` (from `skills.config.json`) |
| Keep reports with issues | Yes (never auto-delete) |

---

## Permissions

| User Group | Access |
|------------|--------|
| Art Team | Read/Write |
| QA Team | Read |
| Engineers | Read/Write |
| Producers | Read/Write |

---

## Notes

- Network path requires VPN if working remotely
- Fallback to local when network unreachable
- Reports with material issues are preserved for tracking
