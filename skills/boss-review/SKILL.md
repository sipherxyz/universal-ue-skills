---
name: boss-review
description: Comprehensive boss implementation review for playtest and EP readiness
---

# Boss Implementation Review Skill

**Role:** Boss Content Auditor
**Scope:** `Content/S2/Core_Boss/{boss_folder}/`
**Platform:** Windows (PowerShell for uasset extraction)
**Output:** Markdown report for team action items

## Objective

Perform a comprehensive audit of a boss implementation to determine:
1. **What has been implemented** - Complete inventory of assets
2. **What is correct** - Assets meeting standardization checklist
3. **What is missing** - Gaps in implementation
4. **Action points** - Tasks required for playtest/EP readiness

## When to Use This Skill

- Before scheduling a boss for playtest
- Before Executive Producer milestone review
- When onboarding a new boss to production pipeline
- Periodic quality audits during development

---

## Boss Standardization Checklist

### Required Folder Structure

```
Content/S2/Core_Boss/{boss_id}/
├── Animation/
│   ├── Attack/           # Attack animation sequences
│   ├── HitReact/         # Boss-specific hit reactions (NOT borrowed)
│   ├── Dodge/            # Dodge/evade animations
│   ├── Death/            # Death animations (REQUIRED)
│   ├── Idle/             # Idle animations
│   ├── Contextual/       # Contextual/cinematic animations
│   └── Movement/         # Locomotion animations
├── Montage/
│   ├── Phase1/           # Phase 1 attack montages
│   ├── Phase2/           # Phase 2 attack montages (if multi-phase)
│   └── [PhaseN]/         # Additional phases as needed
├── Abilities/
│   └── GA/               # Gameplay Abilities
├── VFX/                  # Boss-specific Niagara systems
├── Audio/                # Boss-specific audio (optional, can use shared)
├── Projectile/           # Projectile blueprints (if ranged attacks)
├── Mesh/                 # Character mesh and skeleton
│   └── Assemble/         # Assembled character BP
└── BP_*.uasset           # Character blueprints (Phase1, Phase2, Clones)
```

### Required Assets Per Boss

#### Blueprints (REQUIRED)
| Asset | Naming Convention | Required |
|-------|-------------------|----------|
| Phase 1 Character | `BP_S2_boss_{Name}_Phase_01` | ✅ Yes |
| Phase 2 Character | `BP_S2_boss_{Name}_Phase_02` | If multi-phase |
| Clone Characters | `BP_S2_boss_{Name}_Clone_*` | If clone mechanic |

#### Animation Montages (REQUIRED)
| Category | Minimum Count | Naming Convention |
|----------|---------------|-------------------|
| Attack Combos | 3-5 per phase | `*_combo*_Montage`, `AMT_*` |
| HitReact Light | 4 (F/B/L/R) | `AMT_{BossName}_HitReact_*_Light` |
| HitReact Heavy | 4 (F/B/L/R) | `AMT_{BossName}_HitReact_*_Heavy` |
| HitReact Stun | 1 | `AMT_{BossName}_Stun` |
| Dodge | 3-4 (B/L/R/F) | `AMT_{BossName}_Dodge_*` |
| Death | 1-2 | `AMT_{BossName}_Death*` |
| Block/Parry | 2-4 | `AMT_{BossName}_Block*`, `*Parry*` |

#### Audio (REQUIRED)
| Category | Minimum Count | Notes |
|----------|---------------|-------|
| Attack Whoosh SFX | 2-3 variants | Per weapon type |
| Impact SFX | 2-3 variants | Light/Heavy/Special |
| Voice - Attack Grunts | 3-5 | Randomized selection |
| Voice - Pain/HitReact | 3-5 | Randomized selection |
| Voice - Death | 1-2 | |
| Voice - Phase Transition | 1-2 | If multi-phase |
| Voice - Special Moves | 1 per special | Ultimate, summons, etc. |

#### VFX (REQUIRED)
| Category | Required | Notes |
|----------|----------|-------|
| Weapon Trail | ✅ Yes | Boss-specific color/style |
| Hit Impact Spark | ✅ Yes | On successful hit |
| Special Attack VFX | Per attack | Unique attacks need unique VFX |
| Phase Transition | If multi-phase | Transformation effect |
| Death VFX | Recommended | Dissolution, explosion, etc. |
| Clone Spawn/Despawn | If clone mechanic | |

#### Gameplay Cue Notifies (RECOMMENDED)
| GCN | Purpose |
|-----|---------|
| `GCN_Boss_{Name}_PhaseTransition` | Phase change feedback |
| `GCN_Boss_{Name}_Enrage` | Enrage state visual |
| `GCN_Boss_{Name}_SpecialCharge` | Charging special attack |

---

## Review Workflow

### Phase 1: Asset Discovery

**Step 1.1: Locate Boss Folder**

```bash
# Find boss folder
find "Content/S2/Core_Boss" -maxdepth 1 -type d -name "*{boss_name}*"
```

**Step 1.2: Inventory All Assets**

```bash
# Count total assets
find "{boss_folder}" -name "*.uasset" -type f | wc -l

# List folder structure
find "{boss_folder}" -type d

# Find all Blueprints
find "{boss_folder}" -name "BP_*.uasset" -type f

# Find all Montages
find "{boss_folder}" \( -name "*AMT*.uasset" -o -name "*Montage*.uasset" -o -name "*_Montage.uasset" \)

# Find all VFX
find "{boss_folder}" -name "NS_*.uasset" -type f

# Find all Projectiles
find "{boss_folder}/Projectile" -name "*.uasset" -type f
```

### Phase 2: Montage Analysis

Use the `/asset-management:read-uasset` skill to extract montage contents.

**Step 2.1: Setup Extraction Script**

Ensure PowerShell script exists at `$env:TEMP\extract_uasset_strings.ps1`:

```powershell
param([string]$FilePath)
$bytes = [System.IO.File]::ReadAllBytes($FilePath)
$currentString = ""
foreach ($byte in $bytes) {
    if ($byte -ge 32 -and $byte -le 126) {
        $currentString += [char]$byte
    } else {
        if ($currentString.Length -gt 4) {
            Write-Output $currentString
        }
        $currentString = ""
    }
}
if ($currentString.Length -gt 4) {
    Write-Output $currentString
}
```

**Step 2.2: Extract Key Montages**

For each montage in `Montage/Phase*/`:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "{montage_path}" 2>&1
```

**Step 2.3: Parse Montage Data**

Look for these patterns in extraction output:

| Pattern | Meaning | Status Check |
|---------|---------|--------------|
| `AnimNotify_PlaySound` | Has SFX | ✅ if present |
| `AnimNotify_PlayNiagaraEffect` | Has VFX | ✅ if present |
| `TimedNiagaraEffect` | Has timed VFX | ✅ if present |
| `SipherAbilityNotifyData_Hitbox` | Has hitbox | ✅ if present |
| `BP_NotifyState_MotionWarping` | Has motion warp | ✅ if present |
| `BP_CameraShake_*` | Has camera shake | ✅ if present |
| `DamageShape_*` | Damage shape type | Note type |
| `EDamageImpact::*` | Damage impact level | Note level |
| `/Game/S2/Assets/Audio*` | SFX reference | Note path |
| `/Game/S2/Core_VFX/*` | VFX reference | Note path |
| `Skeleton` line | Skeleton reference | Verify correct boss skeleton |

### Phase 3: Cross-Reference Validation

**Step 3.1: Check for Borrowed Assets**

Extract BP references to find borrowed animations:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\extract_uasset_strings.ps1" -FilePath "{BP_Phase01_path}" 2>&1 | grep -iE "/Game/S2/Core_Boss|/Game/S2/Core_Ene" | sort -u
```

**Red Flags - Borrowed Assets:**
- References to other boss folders (e.g., `s2_boss_tiger` in Gao Lan Ying)
- References to enemy folders (e.g., `s2_eli_GiantRock`)
- Montages with wrong character names in filename

**Step 3.2: Verify Skeleton Compatibility**

For each montage, verify skeleton matches boss:

```bash
# Extract skeleton reference
powershell ... | grep -i "Skeleton"
```

Expected: `/Game/S2/Core_Boss/{this_boss}/Mesh/.../SK_{boss_skeleton}`

### Phase 4: Completeness Scoring

Score each category:

| Category | Weight | Scoring |
|----------|--------|---------|
| Attack Montages | 20% | (implemented / required) × 100 |
| HitReact Coverage | 15% | (directions covered / 8) × 100 |
| SFX Coverage | 15% | (montages with SFX / total attack montages) × 100 |
| VFX Coverage | 15% | (montages with VFX / total attack montages) × 100 |
| Voice Lines | 10% | (categories covered / 6) × 100 |
| Dodge Coverage | 10% | (directions / 4) × 100 |
| Death Animation | 10% | 100 if present, 0 if missing |
| GCN Implementation | 5% | (GCNs / recommended) × 100 |

**Overall Readiness Score:** Weighted average of all categories

| Score | Status |
|-------|--------|
| 90-100% | ✅ Ready for EP Review |
| 75-89% | 🟡 Ready for Internal Playtest |
| 50-74% | 🟠 Needs Work Before Playtest |
| <50% | 🔴 Not Ready |

---

## Report Template

Generate report at: `claude-agents/reports/boss-review/{boss_id}-status-report.md`

```markdown
# Boss Status Report: {Boss Name}

**Report Date:** YYYY-MM-DD
**Boss ID:** `{boss_id}`
**Location:** `Content/S2/Core_Boss/{boss_id}/`
**Status:** {Ready for EP Review | Ready for Playtest | Needs Work | Not Ready}
**Readiness Score:** {X}%

---

## Executive Summary

{2-3 sentence overview of boss state and critical blockers}

### Critical Issues ({count})
{Bullet list of P0 issues}

### Key Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Total Assets | {N} | - |
| Attack Montages | {N} | {✅/⚠️/❌} |
| HitReact Coverage | {N}/8 directions | {✅/⚠️/❌} |
| SFX Coverage | {X}% | {✅/⚠️/❌} |
| VFX Coverage | {X}% | {✅/⚠️/❌} |
| Voice Lines | {X}/6 categories | {✅/⚠️/❌} |
| Death Animation | {Yes/No} | {✅/❌} |

---

## Asset Inventory

### Blueprints

| Asset | Purpose | Status |
|-------|---------|--------|
| {BP_name} | {purpose} | {✅/❌} |

### Attack Montages

#### Phase 1 ({count} montages)

| Montage | Duration | SFX | VFX | Hitbox | Motion Warp | Camera Shake |
|---------|----------|:---:|:---:|:------:|:-----------:|:------------:|
| {name} | {Xs} | {✅/❌} | {✅/❌} | {✅/❌} | {✅/❌} | {✅/❌} |

#### Phase 2 ({count} montages)

| Montage | Duration | SFX | VFX | Hitbox | Projectile | Clone |
|---------|----------|:---:|:---:|:------:|:----------:|:-----:|
| {name} | {Xs} | {✅/❌} | {✅/❌} | {✅/❌} | {✅/❌} | {✅/❌} |

### Defensive Montages

| Category | Direction | Montage | Status |
|----------|-----------|---------|--------|
| HitReact Light | Front | {name or MISSING} | {✅/❌} |
| HitReact Light | Back | {name or MISSING} | {✅/❌} |
| ... | ... | ... | ... |

### Movement Montages

| Category | Direction | Montage | Borrowed From | Status |
|----------|-----------|---------|---------------|--------|
| Dodge | Back | {name} | {None/Other Boss} | {✅/⚠️} |
| ... | ... | ... | ... | ... |

---

## Critical Issues (P0)

### Issue #{N}: {Title}

**Problem:** {Description}

**Evidence:**
```
{Relevant extracted data or file paths}
```

**Impact:** {Why this is blocking}

**Required Fix:** {Specific action}

**Owner:** {Animation/Audio/VFX/Engineering}

---

## High Priority Issues (P1)

{Same format as P0}

---

## Missing Assets Checklist

### Required But Missing

- [ ] {Asset type}: {Specific asset needed}
- [ ] {Asset type}: {Specific asset needed}

### Recommended But Missing

- [ ] {Asset type}: {Specific asset needed}

---

## Action Items by Team

### Animation Team

| Priority | Task | Details |
|----------|------|---------|
| P0 | {Task} | {Details} |
| P1 | {Task} | {Details} |

### Audio Team

| Priority | Task | Details |
|----------|------|---------|
| P0 | {Task} | {Details} |
| P1 | {Task} | {Details} |

### VFX Team

| Priority | Task | Details |
|----------|------|---------|
| P0 | {Task} | {Details} |
| P1 | {Task} | {Details} |

### Engineering Team

| Priority | Task | Details |
|----------|------|---------|
| P0 | {Task} | {Details} |
| P1 | {Task} | {Details} |

---

## Appendix: Full Asset List

### Folder Structure
```
{Tree output of boss folder}
```

### All Montages
```
{List of all montage files}
```

### All VFX
```
{List of all VFX files}
```

---

**Report Generated By:** Claude Code - Boss Review Skill
**Next Review Date:** {Recommended based on severity}
```

---

## Example Invocation

```
User: Review the Gao Lan Ying boss for EP readiness

Agent:
1. Locates boss folder: Content/S2/Core_Boss/s2_boss_gaolanying
2. Inventories all assets (549 total)
3. Extracts and analyzes key montages
4. Identifies borrowed assets (GiantRock HitReacts, Tiger Dodges)
5. Scores completeness (estimated 65%)
6. Generates report with action items
```

---

## Success Criteria

Review is complete when:

- [ ] Boss folder located and validated
- [ ] All assets inventoried by category
- [ ] Key montages extracted and analyzed for SFX/VFX/Hitbox
- [ ] Borrowed/mismatched assets identified
- [ ] Completeness score calculated
- [ ] Critical issues (P0) clearly documented
- [ ] Action items assigned to teams
- [ ] Report saved to `claude-agents/reports/boss-review/`

---

## Integration with Other Skills

### /asset-management:read-uasset
Used for montage content extraction.

### /combat-systems:combat-ai-review
Can be run after `boss-review` to audit AI behavior trees.

### /dev-workflow:open-editor
For visual verification of flagged issues.

---

## Performance Notes

- Asset discovery: ~30 seconds
- Montage extraction: ~2-3 seconds per montage
- Full boss review: ~5-10 minutes depending on asset count
- Parallel extraction recommended for montages

## Legacy Metadata

```yaml
skill: boss-review
invoke: /qa-testing:boss-review
type: qa-review
category: content-review
scope: Content/S2/Core_Boss/**
```
