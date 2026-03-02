---
name: ue-montage-sync-checker
description: Validate animation montage configurations including section timing, notify placement, root motion curves, and slot alignment. Use when debugging montage issues, validating combat animations, or ensuring montage quality standards. Triggers on "montage validation", "montage sync", "animation montage", "montage check", "notify timing", "montage sections".
---

# UE Montage Sync Checker

Validate montage configurations against project standards and detect common issues.

## Quick Start

1. Specify montage asset(s) to validate
2. Run validation rules
3. Get issues and fixes

## Validation Categories

### 1. Section Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Section Names | Warning | Must follow naming convention |
| Section Timing | Error | No zero-length sections |
| Section Links | Error | All links must be valid |
| Default Section | Warning | Should be explicitly set |

### 2. Notify Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Notify Timing | Error | Notifies within section bounds |
| Notify Overlap | Warning | ANS overlaps may cause issues |
| Required Notifies | Warning | Combat montages need hitbox notify |
| Orphan Notifies | Warning | Notifies outside any section |

### 3. Root Motion Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Root Motion Enabled | Info | Check if intentional |
| Translation Curve | Warning | Verify expected movement |
| Rotation Curve | Warning | Verify expected rotation |
| Scale Consistency | Error | Scale should be uniform |

### 4. Slot Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Slot Assignment | Error | Must have valid slot |
| Slot Conflicts | Warning | Multiple montages same slot |
| Blend Settings | Warning | Verify blend in/out times |

## Validation Workflow

### Step 1: Load Montage Data

Extract from montage asset:
- Sections (name, start, end)
- Notifies (class, time, duration)
- Slot name
- Root motion settings
- Blend in/out times

### Step 2: Run Validation Rules

```markdown
## Montage Validation: AMT_{MontageName}

### Summary
- **Status**: {PASS/WARNING/FAIL}
- **Errors**: {N}
- **Warnings**: {N}
- **Info**: {N}

### Asset Info
| Property | Value |
|----------|-------|
| Duration | {N}s |
| Sections | {N} |
| Notifies | {N} |
| Slot | {SlotName} |
| Root Motion | {Yes/No} |
```

### Step 3: Issue Report

```markdown
### Section Issues

#### [ERROR] Zero-Length Section
- **Section**: {SectionName}
- **Start**: {Time}s
- **End**: {Time}s
- **Fix**: Extend section or remove if unused

#### [WARNING] Non-Standard Section Name
- **Section**: {SectionName}
- **Expected**: {Convention}
- **Fix**: Rename to follow pattern: `{Prefix}_{Action}_{Modifier}`

---

### Notify Issues

#### [ERROR] Notify Out of Bounds
- **Notify**: {NotifyClass}
- **Time**: {Time}s
- **Section**: {SectionName} ({Start}s - {End}s)
- **Fix**: Move notify within section bounds

#### [WARNING] Missing Combat Notify
- **Expected**: USipherANS_Hitbox or derivative
- **Reason**: Montage has combat tag but no hitbox
- **Fix**: Add hitbox notify during damage window

---

### Root Motion Issues

#### [WARNING] Unexpected Root Motion
- **Translation**: {Vector}
- **Max Velocity**: {N} cm/s
- **Expected**: {Expected or None}
- **Fix**: Verify root motion is intentional for this animation

---

### Slot Issues

#### [ERROR] Invalid Slot
- **Current**: {SlotName}
- **Available**: {ValidSlots}
- **Fix**: Assign to valid slot from skeleton's slot groups
```

## Sipher Montage Standards

### Naming Convention

```
AMT_{Character}_{Action}_{Variant}
Examples:
- AMT_Player_LightAttack_01
- AMT_Enemy_HitReaction_Front
- AMT_Boss_Phase2_Slam
```

### Required Sections

| Montage Type | Required Sections |
|--------------|-------------------|
| Combat Attack | Start, Anticipation, Attack, Recovery |
| Hit Reaction | Start, Impact, Recovery |
| Ability | Start, Loop (if looping), End |
| Transition | From, To |

### Notify Requirements

| Montage Type | Required Notifies |
|--------------|-------------------|
| Attack | USipherANS_Hitbox (during Attack section) |
| Parryable | USipherANS_ParryWindow |
| Movement | USipherANS_RootMotionWarp (if warping) |
| Combo | USipherAN_ComboWindow |

### Section Timing Guidelines

| Section | Duration | Notes |
|---------|----------|-------|
| Anticipation | 0.1-0.3s | Telegraphs attack |
| Attack | 0.1-0.5s | Active damage window |
| Recovery | 0.2-0.5s | Punish window |
| Combo Window | 0.2-0.4s | Within Recovery |

## Batch Validation

### Validate All Combat Montages

```markdown
## Batch Validation: Combat Montages

### Summary
| Status | Count |
|--------|-------|
| Pass | {N} |
| Warning | {N} |
| Fail | {N} |

### Failures
| Montage | Issues |
|---------|--------|
| AMT_{Name} | {Summary} |

### Warnings
| Montage | Issues |
|---------|--------|
| AMT_{Name} | {Summary} |
```

### Validate by Character

```markdown
## Montages for: {CharacterName}

### Coverage
| Action | Montage | Status |
|--------|---------|--------|
| Light Attack 1 | AMT_{...} | {Status} |
| Light Attack 2 | AMT_{...} | {Status} |
| Heavy Attack | AMT_{...} | MISSING |
```

## Auto-Fix Capabilities

| Issue | Auto-Fix Available |
|-------|-------------------|
| Section naming | Yes (rename) |
| Notify timing | No (requires review) |
| Slot assignment | Yes (suggest default) |
| Zero-length section | No (requires decision) |

## Output Report

```markdown
# Montage Validation Report

## Executive Summary
- **Montages Checked**: {N}
- **Pass**: {N}
- **Warnings**: {N}
- **Failures**: {N}

## Critical Issues (Must Fix)
1. {Montage}: {Issue}

## Warnings (Should Review)
1. {Montage}: {Issue}

## Standards Compliance
- Naming: {N}% compliant
- Required Notifies: {N}% present
- Section Structure: {N}% correct

## Recommendations
1. {Recommendation}
```
