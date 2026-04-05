---
name: enemy-status-track
description: Track and audit enemy content implementation status across Core_Ene and Core_Boss folders. Update tracking spreadsheet with asset completeness.
---

## Configuration
This skill reads project-specific values from `skills.config.json` at the repository root.
If not found, auto-detect using `ue-detect-engine` skill or prompt the user.

# Enemy Status Tracking Skill

**Role:** Enemy Content Auditor
**Scope:** `{project.content_path}/Core_Ene/` and `{project.content_path}/Core_Boss/`
**Tracker:** `enemy_status_tracker.md`
**Platform:** Windows (PowerShell for asset discovery)

## When to Use This Skill

- Track content implementation status for enemies
- Audit specific enemy folders for missing assets
- Update the enemy status tracker spreadsheet
- Generate missing asset reports
- Before milestone reviews to check enemy readiness

## Instructions

Follow the detailed workflow in [ENEMY_STATUS_TRACK_INSTRUCTION.md](ENEMY_STATUS_TRACK_INSTRUCTION.md).

## Quick Reference

### Tracked Categories

| Column | Asset Type | Detection Method |
|--------|-----------|------------------|
| Death | Death animation montage | `*Death*` in Anim folder |
| HitReact | Hit reaction montages | `*HitReact*`, `*Stagger*` |
| Attack | Attack montages | `*Attack*`, `*Combo*`, `AMT_*` |
| Loco | Locomotion blendspaces | `*Loco*`, `*Walk*`, `*Run*`, `BS_*` |
| BP | Blueprint actor | `BP_*.uasset` in root |
| AI | Behavior/State Tree | `BT_*`, `ST_*` in AI folder |
| VFX | Niagara systems | `NS_*`, `NE_*` in VFX folder |
| SFX | Audio assets | `*Sound*`, `*Audio*`, `*.uasset` in Audio folder |

### Status Values

- ✅ = Has its own content
- ⚠️ = Has content, but is referencing to assets in another enemy's folder, except folders in excluded list
- ❌ = Missing/Not found
- ❓ = Needs review

## Categorise enemies
- BOSS = has `boss` the folder name
- ELITE = has `eli` OR `elite` in the folder name
- NORMAL = doesn't have `boss`, `eli` or `elite` in the folder name

## Example Usage

```
User: Update the status for s2_eli_beast_01A

Agent:
1. Scans {project.content_path}/Core_Ene/s2_eli_beast_01A/
2. Checks each category folder
3. Updates enemy_status_tracker.md
4. Reports findings
```

```
User: Which enemies are missing death animations?

Agent:
1. Reads enemy_status_tracker.md
2. Filters for Death = "-"
3. Lists affected enemies
```

## Legacy Metadata

```yaml
skill: enemy-status-track
invoke: /qa-testing:enemy-status-track
type: qa-review
category: content-tracking
scope: {project.content_path}/Core_Ene/**, {project.content_path}/Core_Boss/**
```
