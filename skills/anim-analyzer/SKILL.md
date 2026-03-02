---
name: anim-analyzer
description: Analyze animation assets (AMT_, CHT_, BS_, RTG_, ABP_) for structure, dependencies, notifies, and quality issues
---

# Animation Asset Analyzer

Analyze Unreal Engine animation assets (AMT_, CHT_, BS_, RTG_, ABP_) for structure, dependencies, notifies, and quality issues.

## Supported Asset Types

| Prefix | Type | Status | Analysis Focus |
|--------|------|--------|----------------|
| **AMT_** | AnimMontage | ✅ Implemented | Notifies, sections, slots, dependencies |
| **BS_** | BlendSpace | ✅ Implemented | Sample count, skeleton, directional coverage |
| **CHT_** | ChooserTable | ✅ Implemented | Selection logic, parameter bindings |
| **RTG_** | IK Retargeter | ✅ Implemented | Bone mappings, source/target skeletons |
| **ABP_** | AnimBlueprint | ✅ Implemented | State machines, blend nodes |

---

## Workflow Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                    ANIMATION ASSET ANALYZER                          │
├──────────────────────────────────────────────────────────────────────┤
│  STEPS (6 total):                                                    │
│                                                                      │
│  1. Asset Selection    - Path, glob, or folder                       │
│  2. Type Detection     - Identify AMT_/CHT_/BS_/RTG_/ABP_            │
│  3. Parse Asset        - Extract via parse_uasset.py --deep          │
│  4. Type Analysis      - Notifies, dependencies, structure           │
│  5. Issue Detection    - Missing SFX/VFX/hitbox, TEMP refs           │
│  6. Generate Report    - Quality score + actionable items            │
├──────────────────────────────────────────────────────────────────────┤
│  OUTPUT: claude-agents/reports/anim-analysis/{type}/{name}.md        │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Asset Selection

<ask>
What would you like to analyze?

1. **Single asset** - Provide the full path to a .uasset file
2. **Glob pattern** - e.g., `Content/Animation/AMT_*.uasset`
3. **Folder** - Analyze all animation assets in a directory
</ask>

---

## Step 2: Asset Type Detection

Detect asset type from filename prefix or export class:

| Prefix | Export Class Contains | Asset Type |
|--------|----------------------|------------|
| `AMT_` | `AnimMontage` | AnimMontage |
| `CHT_` | `ChooserTable` | ChooserTable |
| `BS_` | `BlendSpace` | BlendSpace |
| `RTG_` | `IKRetargeter` | IK Retargeter |
| `ABP_` | `AnimBlueprint` | AnimBlueprint |
| `AS_` | `AnimSequence` | AnimSequence |
| `AO_` | `AimOffset` | AimOffset |

**Type Validation Warning:**
If user provides an AS_ (AnimSequence) when expecting AMT_ (Montage), warn them:
> "This appears to be an AnimSequence, not a Montage. AnimSequence analysis has limited scoring (no hitbox check). Continue anyway?"

<action>
Run parser to confirm type:
```bash
python scripts/parse_uasset.py "{asset_path}" --summary
```
Check `asset_type` field in output.
</action>

---

## Step 3: Parse Asset

<action>
Run deep parser to extract full structure:

```bash
python scripts/parse_uasset.py "{asset_path}" --deep --format text
```

Capture:
- **file_size** - Asset size
- **summary.engine_version** - UE version
- **summary.name_count** - Total FNames
- **summary.import_count** - External dependencies
- **names** - Full name table for pattern analysis
- **categorized_dependencies** - Dependencies by type
- **name_analysis.notifies** - Detected notify classes
</action>

---

## Step 4: Type-Specific Analysis

### 4.1 AMT_ (AnimMontage) Analysis

**Step 4.1.1: Notify Detection**

Scan name table for notify patterns:

| Pattern | Category | Significance |
|---------|----------|--------------|
| `AN_S2_Foley_*` | SFX | Project foley events |
| `AN_S2_Voice_*` | SFX | Voice events |
| `AnimNotify_Play*Sound*` | SFX | Engine audio notify |
| `AnimNotify_PlayNiagaraEffect` | VFX | Niagara trigger |
| `AnimNotifyState_TimedNiagaraEffect` | VFX | Duration Niagara |
| `BP_FXTrail` | VFX | Weapon trail effect |
| `NS_*` | VFX | Niagara system reference |
| `SipherAbilityNotifyData_Hitbox` | Combat | Hitbox activation |
| `DamageShape_*` | Combat | Damage shape type |
| `Sipher.Notify.Hitbox.*` | Combat | Gameplay tag hitbox (in tags section) |
| `Sipher.Notify.Ability.*` | Combat | Gameplay tag ability trigger |
| `BP_NotifyState_MotionWarping` | Movement | Motion warping window |
| `ANS_LockRotationAI` | AI | AI rotation lock state |
| `BP_AI_RotateToTarget_Notify` | AI | Target tracking rotation |
| `AN_GlobalCameraShake` | Camera | Global camera shake |
| `BP_CameraShake_*` | Camera | Screen shake variants |
| `BP_ActionState_Notify` | State | Combat action state |

**Step 4.1.1b: Gameplay Tags Detection**

Check `--- Gameplay Tags ---` section for combat indicators:

| Tag Pattern | Significance |
|------------|--------------|
| `Sipher.Notify.Hitbox.Melee` | Melee hitbox activation |
| `Sipher.Notify.Hitbox.Ranged` | Ranged hitbox |
| `Sipher.Notify.Ability.CreateProjectile` | Spawns projectile |
| `Sipher.Damage.Property.*` | Damage properties |
| `Sipher.Character.State.Action.*` | Action states |

**Note:** Foley notifies often appear in referenced AnimSequence (AS_*), not directly in montage. Parser detects these in dependency tree.

**Step 4.1.2: Categorize Notifies**

Group detected notifies into:
- **SFX Count**: Audio-related notifies
- **VFX Count**: Visual effect notifies
- **Combat Count**: Hitbox/damage notifies
- **Movement Count**: Motion warping, root motion
- **Camera Count**: Camera effects

**Step 4.1.3: Dependency Analysis**

Parser auto-categorizes dependencies. Key categories:

| Category | Pattern | Significance |
|----------|---------|--------------|
| Skeleton | `SK_*`, `SKEL_*` | Mesh/skeleton binding |
| Animation | `AS_*`, `AMT_*` | Animation references |
| VFX | `NS_*`, `*VFX*` | Niagara systems |
| Audio | `*Audio*`, `*SFX*`, `*Sound*` | Sound assets |
| Blueprint | `BP_*`, `AC_*` | Component/notify BPs |
| Ability | `GA_*`, `ANS_*` | GAS abilities |
| Montage | `AMT_*` | Other montages |
| Projectile | `*Projectile*` | Projectile references |

**Recursive Analysis**: Parser traverses 2 levels deep to capture foley notifies and audio dependencies that come from AnimSequence assets.

**Step 4.1.4: Quality Metrics**

For AMT_ assets, calculate:

| Metric | Weight | Scoring |
|--------|--------|---------|
| Has SFX notifies | 25% | 100 if ≥1, 0 if none |
| Has VFX notifies | 20% | 100 if ≥1, 0 if none |
| Has Hitbox (attack) | 30% | 100 if ≥1, 0 if none (attack montages only) |
| Has Motion Warp | 10% | 100 if present, 50 if not |
| No TEMP refs | 10% | 100 if clean, 0 if TEMP present |
| Valid skeleton | 5% | 100 if matches expected, 0 if wrong |

**Hitbox check only applies if:**
- Filename contains `Attack`, `Combo`, `Heavy`, `Light`, `Skill`

---

### 4.2 CHT_ (ChooserTable) Analysis - BLOCKED

**Status:** Parser incompatible with UE5.7 ChooserTable format (header `F8-FF-FF-FF` vs standard `F7-FF-FF-FF`)

**Planned analysis (when parser updated):**
- Parameter types and bindings
- Selection logic complexity
- Referenced animations
- Dead branches detection

---

### 4.3 BS_ (BlendSpace) Analysis - Implemented

**Step 4.3.1: Sample Detection**

Scan name table for animation sample references:

| Pattern | Category | Significance |
|---------|----------|--------------|
| `AS_*` | Animation | Sample animation sequence |
| `Walk_*`, `Run_*`, `Jog_*` | Locomotion | Movement sample |
| `*_F_*`, `*_B_*`, `*_L_*`, `*_R_*` | Directional | Cardinal direction sample |
| `*_45`, `*_90`, `*_180` | Angular | Angle-based sample |

**Step 4.3.2: Skeleton Validation**

| Pattern | Significance |
|---------|--------------|
| `SKEL_*` | Skeleton reference |
| `SK_*` | Skeletal mesh reference |

**Step 4.3.3: Quality Metrics**

For BS_ assets, calculate:

| Metric | Weight | Scoring |
|--------|--------|---------|
| Has samples | 40% | 100 if ≥4, 50 if 1-3, 0 if none |
| Valid skeleton | 20% | 100 if matches expected, 0 if wrong |
| Directional coverage | 25% | 100 if all cardinals, 50 if partial |
| No TEMP refs | 15% | 100 if clean, 0 if TEMP present |

**Sample Count Thresholds:**
- 1D BlendSpace: 3+ samples expected
- 2D BlendSpace: 9+ samples expected (3x3 grid minimum)

---

### 4.4 RTG_ (IK Retargeter) Analysis - BLOCKED

**Status:** Parser incompatible with UE5.7 IKRetargeter format

**Planned analysis (when parser updated):**
- Source skeleton reference
- Target skeleton reference
- Bone mapping completeness
- Chain definitions

---

### 4.5 ABP_ (AnimBlueprint) Analysis - BLOCKED

**Status:** Parser incompatible with UE5.7 AnimBlueprint format (header `F8-FF-FF-FF`)

**Planned analysis (when parser updated):**
- State machine count
- State transition patterns
- Referenced montages/sequences
- Blend node complexity

---

## Step 5: Issue Detection

<check>
Scan for issues by severity:

### Critical (P0)
| Issue | Detection | Impact |
|-------|-----------|--------|
| Missing hitbox | No `*Hitbox*` in attack montage | Combat broken |
| Broken reference | Import with no valid path | Asset won't load |
| Wrong skeleton | Skeleton mismatch | Animation won't play |

### High (P1)
| Issue | Detection | Impact |
|-------|-----------|--------|
| Missing SFX | No audio notifies | Silent action |
| Missing VFX | No Niagara notifies | No visual feedback |
| Orphaned hitbox | Hitbox start without end | Persistent damage |

### Medium (P2)
| Issue | Detection | Impact |
|-------|-----------|--------|
| TEMP references | `TEMP_*` in dependencies | WIP content |
| Prototype assets | `_prototype`, `_WIP` patterns | Not production ready |
| Missing motion warp | Attack without warping | Poor tracking |

### Low (P3)
| Issue | Detection | Impact |
|-------|-----------|--------|
| Non-standard naming | Doesn't match AMT_* pattern | Consistency |
| Missing camera shake | No shake on heavy attack | Reduced impact feel |
</check>

---

## Step 6: Generate Report

<template-output file="claude-agents/reports/anim-analysis/montages/{{asset_name}}-analysis.md">
Fill template with:
- Asset summary (file size, engine version, dependencies)
- Notify inventory (categorized by type)
- Quality score (0-100%)
- Status badge (Ready/Needs Polish/Incomplete/Not Ready)
- Issues found (by severity)
- Action items
</template-output>

### Quality Score → Status Mapping

| Score | Status | Badge |
|-------|--------|-------|
| 90-100% | Ready | ✅ |
| 70-89% | Needs Polish | 🟡 |
| 50-69% | Incomplete | 🟠 |
| <50% | Not Ready | 🔴 |

---

## Output Location

Reports saved to: `claude-agents/reports/anim-analysis/`

```
anim-analysis/
├── montages/           # AMT_* analysis
│   └── {name}-analysis.md
├── choosers/           # CHT_* analysis (Phase 2)
├── blendspaces/        # BS_* analysis (Phase 2)
├── retargeters/        # RTG_* analysis (Phase 2)
└── batch/              # Summary reports
    └── folder-summary.md
```

---

## Example Analysis Session

```
User: Analyze AMT_S2_Boss_Tiger_DomainExpansion_TigerClaw.uasset

Agent:
1. Locates: S:/Projects/s2/Content/Animation/Anim_Library/Male/S2_Tiger/AMT_S2_Boss_Tiger_DomainExpansion_TigerClaw.uasset
2. Detects type: AnimMontage (from AMT_ prefix + export class)
3. Runs parser: python parse_uasset.py --deep --format text
4. Extracts notifies:
   - SFX: AnimNotify_PlaySound (7 audio assets)
   - VFX: AnimNotify_PlayNiagaraEffect, BP_FXTrail, NS_Combat_Tiger_*
   - Combat: Sipher.Notify.Hitbox.Melee, Sipher.Notify.Ability.CreateProjectile
   - AI: ANS_LockRotationAI, BP_AI_RotateToTarget_Notify
   - Camera: AN_GlobalCameraShake, BP_CameraShake_Boss_HeavyHit
   - Foley: (in AS_ dependency) AN_S2_Foley_Jump, AN_S2_Foley_Land
5. Calculates score:
   - SFX: ✅ 25%
   - VFX: ✅ 20%
   - Hitbox: ✅ 30% (via gameplay tags)
   - Motion Warp: ✅ 10% (AI rotation lock)
   - No TEMP: ✅ 10%
   - Valid skeleton: ✅ 5%
   - Total: 100% → ✅ Ready
6. Generates report: claude-agents/reports/anim-analysis/montages/AMT_S2_Boss_Tiger_DomainExpansion_TigerClaw-analysis.md
```

### Tested Assets (v1.0.0)

| Asset | Type | Score | Status |
|-------|------|-------|--------|
| AMT_S2_Boss_Tiger_Attack01 | Attack | 85-90% | ✅ Ready |
| AMT_S2_Boss_Tiger_Dodge_Forward | Dodge | 80% | 🟡 Needs Polish |
| AMT_S2_Boss_Tiger_DomainExpansion_TigerClaw | Special | 100% | ✅ Ready |

---

## Extension Guide

See `references/extension-guide.md` for adding new asset types.

Quick steps:
1. Add detection pattern to Step 2 table
2. Create analysis section (Step 4.X)
3. Add issue patterns to Step 5
4. Create template in `templates/`
5. Update this SKILL.md routing table

---

## Pipeline Mode (v1.2.0)

For downstream tool consumption, use `--pipeline` to get structured JSON:

```bash
python parse_uasset.py "{asset_path}" --pipeline
```

### JSON Schema

```json
{
  "asset": {
    "path": "/Game/S2/Core_Ene/.../AMT_ene_dualsword_attack01",
    "file": "AMT_ene_dualsword_attack01.uasset",
    "type": "AnimMontage",
    "size": 47651,
    "ue_version": 1018
  },
  "skeleton": "SKEL_S2_ENM_STD_bodyA",
  "content": {
    "notifies": [
      {"class": "AnimNotify_PlaySound", "count": 3},
      {"class": "AN_AttackDamageDefinition", "count": 1}
    ],
    "tags": ["Sipher.Damage.Type.Physical"],
    "dependencies": {
      "audio": ["/Game/.../SFX_Combat_Whoosh"],
      "vfx": ["/Game/.../NS_Combat_Move_FootStep"],
      "blueprint": ["/Game/.../BP_NotifyState_MotionWarping"],
      "skeleton": ["/Game/.../SKEL_S2_ENM_STD_bodyA"]
    }
  },
  "flags": {
    "has_sfx": true,
    "has_vfx": true,
    "has_hitbox": true,
    "has_motion_warp": true,
    "has_temp_refs": false,
    "is_attack": true
  },
  "quality": {
    "score": 100,
    "status": "ready",
    "missing": [],
    "warnings": []
  }
}
```

### Design Principle: Facts, Not Actions

Parser outputs **facts** (what exists, what's missing). Consumers decide **actions**.

| Field | Type | Description |
|-------|------|-------------|
| `asset.type` | string | AnimMontage, BlendSpace, AnimBlueprint, etc. |
| `flags.*` | boolean | Quick checks for CI/CD validation |
| `quality.missing` | array | List of missing elements (sfx, vfx, hitbox) |
| `quality.status` | string | ready, needs_polish, incomplete, not_ready |

### Consumer Examples

**AI Agent:**
```
"I analyzed AMT_ene_dualsword_attack01. Missing: none. Score: 100%. Ready for production."
```

**CI/CD:**
```bash
python parse_uasset.py "$ASSET" --pipeline | jq '.quality.missing'
# Fail build if any critical issues
```

**Human Review:**
```bash
python parse_uasset.py "AMT_*.uasset" --pipeline | jq '.flags'
# Quick scan for missing elements
```

---

## Parser Limitations

The `parse_uasset.py` parser extracts:
- ✅ Name tables (all FNames → notify class detection)
- ✅ Import/export tables (dependencies)
- ✅ Package references

It **cannot** extract:
- ❌ Notify timing/position data
- ❌ Section durations
- ❌ Blend curves
- ❌ Animation keyframe data
- ❌ State machine graph structure (ABP)

For detailed timing analysis, open the asset in Unreal Editor.

## Legacy Metadata

```yaml
skill: anim-analyzer
invoke: /asset-management:anim-analyzer
```
