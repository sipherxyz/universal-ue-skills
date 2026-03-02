---
name: ue-weapon-data-validator
description: Validate weapon DataAssets including damage curves, combo references, VFX links, sound cues, and stat configurations. Use when creating weapons, validating weapon data, or debugging weapon issues. Triggers on "weapon validation", "weapon data", "validate weapon", "weapon check", "damage curves", "weapon asset".
---

# UE Weapon Data Validator

Validate weapon DataAssets and configurations.

## Quick Start

1. Specify weapon DataAsset
2. Run validation suite
3. Get issues and recommendations

## Validation Categories

### 1. Core Data Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Asset Exists | Error | DataAsset must exist |
| Required Fields | Error | All required fields populated |
| Reference Integrity | Error | All soft refs resolve |
| Value Ranges | Warning | Values within expected bounds |

### 2. Damage Configuration

| Check | Severity | Description |
|-------|----------|-------------|
| Base Damage | Error | Must be > 0 |
| Damage Type | Error | Valid damage type enum |
| Scaling Curve | Warning | Curve exists and reasonable |
| Crit Multiplier | Warning | Typically 1.5-3.0 |

### 3. Combo References

| Check | Severity | Description |
|-------|----------|-------------|
| Combo Graph | Error | Valid combo graph reference |
| Attack Montages | Error | All montages exist |
| Transition Rules | Warning | Combo transitions valid |

### 4. Visual/Audio

| Check | Severity | Description |
|-------|----------|-------------|
| Mesh Reference | Error | Weapon mesh exists |
| Materials | Warning | Materials assigned |
| VFX References | Warning | Trail/impact VFX valid |
| Sound Cues | Warning | Attack/impact sounds valid |

## Validation Workflow

### Step 1: Load Weapon Data

```markdown
## Weapon Analysis: DA_Weapon_{WeaponName}

### Basic Info
| Property | Value |
|----------|-------|
| Display Name | {Name} |
| Weapon Type | {Type} |
| Rarity | {Rarity} |
| Base Damage | {N} |
| Attack Speed | {N} |
```

### Step 2: Validate Core Data

```markdown
### Core Data Validation

#### Required Fields
| Field | Value | Status |
|-------|-------|--------|
| WeaponName | {Value} | {OK/Empty} |
| WeaponType | {Value} | {OK/Invalid} |
| BaseDamage | {Value} | {OK/Zero/Negative} |
| AttackSpeed | {Value} | {OK/OutOfRange} |
| Weight | {Value} | {OK/Warning} |

#### [ERROR] Missing Required Field
- **Field**: BaseDamage
- **Expected**: > 0
- **Current**: 0
- **Fix**: Set BaseDamage to appropriate value for weapon tier
```

### Step 3: Validate Damage

```markdown
### Damage Configuration

#### Damage Stats
| Stat | Value | Range | Status |
|------|-------|-------|--------|
| Base Damage | {N} | 10-500 | {OK/Warning} |
| Damage Type | {Type} | Physical/Elemental | {OK/Invalid} |
| Crit Chance | {N}% | 0-100 | {OK/Warning} |
| Crit Multiplier | {N}x | 1.5-3.0 | {OK/Warning} |

#### Scaling Curve
- **Curve Asset**: {CurvePath}
- **Status**: {Valid/Missing/Empty}
- **Sample Values**:
  | Level | Multiplier |
  |-------|------------|
  | 1 | {N} |
  | 10 | {N} |
  | 50 | {N} |

#### [WARNING] Crit Multiplier Out of Range
- **Current**: 5.0x
- **Expected**: 1.5-3.0x
- **Impact**: May cause balance issues
- **Fix**: Reduce to 2.0-2.5x for standard weapons
```

### Step 4: Validate Combo References

```markdown
### Combo Configuration

#### Combo Graph
- **Graph**: CG_{WeaponType}_{Variant}
- **Status**: {Valid/Missing}
- **Moves**: {N}

#### Attack Montages
| Attack | Montage | Status |
|--------|---------|--------|
| Light 1 | AMT_{Weapon}_Light_01 | {Found/Missing} |
| Light 2 | AMT_{Weapon}_Light_02 | {Found/Missing} |
| Heavy | AMT_{Weapon}_Heavy | {Found/Missing} |
| Special | AMT_{Weapon}_Special | {Found/Missing} |

#### [ERROR] Missing Attack Montage
- **Attack**: Heavy
- **Expected**: AMT_{WeaponName}_Heavy
- **Fix**: Create montage or update reference
```

### Step 5: Validate Visual/Audio

```markdown
### Visual Configuration

#### Mesh
- **Static Mesh**: SM_{WeaponName}
- **Status**: {Found/Missing}
- **LODs**: {N}
- **Triangles**: {N}

#### Materials
| Slot | Material | Status |
|------|----------|--------|
| 0 | MI_{WeaponName}_Base | {Found/Missing} |

#### VFX
| Effect | Asset | Status |
|--------|-------|--------|
| Trail | NS_{Weapon}_Trail | {Found/Missing} |
| Impact | NS_{Weapon}_Impact | {Found/Missing} |
| Special | NS_{Weapon}_Special | {Found/Missing} |

---

### Audio Configuration

| Sound | Cue | Status |
|-------|-----|--------|
| Swing | SC_{Weapon}_Swing | {Found/Missing} |
| Impact | SC_{Weapon}_Impact | {Found/Missing} |
| Draw | SC_{Weapon}_Draw | {Found/Missing} |
| Sheathe | SC_{Weapon}_Sheathe | {Found/Missing} |
```

## Validation Rules

### Damage Ranges by Tier

| Tier | Base Damage | Crit Chance | Crit Multi |
|------|-------------|-------------|------------|
| Common | 10-25 | 5-10% | 1.5x |
| Uncommon | 25-50 | 10-15% | 1.5-1.75x |
| Rare | 50-100 | 15-20% | 1.75-2.0x |
| Epic | 100-200 | 20-25% | 2.0-2.25x |
| Legendary | 200-500 | 25-30% | 2.25-2.5x |

### Attack Speed Ranges

| Weapon Type | Speed Range | Typical |
|-------------|-------------|---------|
| Dagger | 1.5-2.5 | 2.0 |
| Sword | 1.0-1.5 | 1.2 |
| Axe | 0.7-1.0 | 0.85 |
| Hammer | 0.5-0.8 | 0.65 |
| Spear | 0.8-1.2 | 1.0 |

## Batch Validation

```markdown
## Weapon Batch Validation

### Summary
| Status | Count |
|--------|-------|
| Pass | {N} |
| Warning | {N} |
| Fail | {N} |

### By Type
| Type | Count | Pass | Fail |
|------|-------|------|------|
| Sword | {N} | {N} | {N} |
| Axe | {N} | {N} | {N} |

### Common Issues
| Issue | Occurrences |
|-------|-------------|
| {Issue} | {N} |
```

## Output Report

```markdown
# Weapon Validation Report: {WeaponName}

## Status: {PASS / WARNING / FAIL}

## Blocking Issues
1. {Issue}

## Warnings
1. {Warning}

## Recommendations
1. {Recommendation}

## Balance Notes
- Damage relative to tier: {Assessment}
- Speed/damage tradeoff: {Assessment}
- Special effects: {Assessment}
```
