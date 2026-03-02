# Deep Research Skill - Session Resume

**Last Updated**: 2026-01-24
**Status**: ✅ Working

---

## Quick Start

```
/deep-research
```

Then provide any topic: `boss telegraphs`, `GAS optimization`, `niagara vfx`, etc.

---

## File Locations

| Purpose | Path |
|---------|------|
| **Skill Definition** | `.claude/skills/deep-research/SKILL.md` |
| **Templates** | `.claude/skills/deep-research/templates/` |
| **References** | `.claude/skills/deep-research/references/` |
| **Output Reports** | `claude-agents/reports/deep-research/` |
| **HTML UI Work** | `claude-agents/tools/deep-research-ui/` |

---

## What Was Done (2026-01-24)

### Problem
- Created deep-research skill in `dev-workflow` plugin but couldn't invoke it
- Tried creating standalone `research-tools` plugin - also couldn't invoke
- Discovered: ALL s2-skills plugins have broken skill autocomplete (plugins load, but skills don't appear in `/` autocomplete)

### Solution
- Created skill as **direct local skill** at `.claude/skills/deep-research/`
- This bypasses the broken marketplace plugin system
- Invoke with `/deep-research` (no plugin prefix needed)

### Cleanup Done
- Removed failed `research-tools` plugin from marketplace
- Removed old `deep-research` from `dev-workflow` plugin
- Reverted `marketplace.json` and `dev-workflow/plugin.json` to original
- Deleted temp files (except launcher scripts)
- Restored `launch-claude.cmd` and `launch-claude.ps1` for Desktop shortcut

---

## Current Structure

```
.claude/skills/deep-research/
├── SKILL.md                    # Main skill definition
├── resume_session.md           # This file
├── references/
│   └── source-domains.md       # Trusted source domains by priority
└── templates/
    ├── art-report-template.md  # Visual/Art domain template
    ├── dev-report-template.md  # Developer domain template
    ├── gd-report-template.md   # Game Design domain template
    └── report-template.html    # HTML report template
```

---

## Existing Reports

```
claude-agents/reports/deep-research/
├── assassin-enemy-research.md/html
├── chinese-beast-statue-research.md/html
├── claude-code-gaming-2026-research.md/html
├── lighting-setup-action-rpg-research.md
├── shan-hai-jing-twin-boss-research.md/html
├── ue5-checkpoint-streaming-research.md/html
└── *-assets/                   # Downloaded images
```

---

## Parallel Work

**HTML UI Development** (separate session):
- Location: `claude-agents/tools/deep-research-ui/`
- Purpose: Visual HTML report generation improvements

---

## Known Issues

1. **s2-skills plugin skills don't appear in autocomplete**
   - Plugins load and show as "enabled" in `/plugin list`
   - But their skills don't appear when typing `/`
   - Workaround: Use direct local skills at `.claude/skills/`

2. **Solution for future skills**
   - Place new skills in `.claude/skills/{skill-name}/SKILL.md`
   - They will be available as `/{skill-name}` without plugin prefix

---

## Next Steps

- [ ] Continue HTML report UI improvements (other session)
- [ ] Test skill with various topics
- [ ] Consider filing bug report about s2-skills plugin skill discovery
