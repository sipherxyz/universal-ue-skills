---
name: ue-collision-preset-auditor
description: Audit collision channels and presets including response matrices, channel conflicts, and trace channel usage. Use when debugging collision issues, reviewing physics setup, or validating collision configuration. Triggers on "collision preset", "collision channel", "collision audit", "physics collision", "trace channel", "collision matrix".
---

# UE Collision Preset Auditor

Audit collision channel configuration and preset assignments.

## Quick Start

1. Specify scope (project, actor type, or specific preset)
2. Run collision audit
3. Get conflict detection and optimization suggestions

## Audit Categories

### 1. Channel Configuration

| Check | Severity | Description |
|-------|----------|-------------|
| Unused Channels | Info | Channels defined but not used |
| Channel Conflicts | Warning | Overlapping response patterns |
| Missing Responses | Error | Expected responses not configured |

### 2. Preset Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Preset Exists | Error | Referenced preset must exist |
| Response Complete | Warning | All channels have explicit response |
| Preset Consistency | Warning | Similar actors use same preset |

### 3. Trace Channel Audit

| Check | Severity | Description |
|-------|----------|-------------|
| Trace Usage | Info | Where traces are used |
| Response Coverage | Warning | Actors respond to common traces |

## Audit Workflow

### Step 1: Extract Configuration

```markdown
## Collision Configuration

### Object Channels
| Channel | Name | Default Response |
|---------|------|------------------|
| ECC_GameTraceChannel1 | SipherHitbox | Block |
| ECC_GameTraceChannel2 | SipherProjectile | Block |
| ECC_GameTraceChannel3 | SipherInteractable | Overlap |

### Trace Channels
| Channel | Name | Default Response |
|---------|------|------------------|
| ECC_GameTraceChannel10 | SipherDamageTrace | Block |
| ECC_GameTraceChannel11 | SipherVisibilityTrace | Block |
| ECC_GameTraceChannel12 | SipherInteractionTrace | Overlap |
```

### Step 2: Analyze Presets

```markdown
### Collision Presets

#### EnemyCharacter
| Response To | Setting |
|-------------|---------|
| WorldStatic | Block |
| WorldDynamic | Block |
| Pawn | Block |
| PlayerCharacter | Block |
| EnemyCharacter | Overlap |
| SipherHitbox | Block |
| SipherProjectile | Block |

#### PlayerCharacter
| Response To | Setting |
|-------------|---------|
| WorldStatic | Block |
| WorldDynamic | Block |
| Pawn | Block |
| PlayerCharacter | Ignore |
| EnemyCharacter | Block |
| SipherHitbox | Block |
| SipherProjectile | Block |
```

### Step 3: Build Response Matrix

```markdown
### Response Matrix (Block = ■, Overlap = ○, Ignore = ·)

              | World | Pawn | Player | Enemy | Hitbox | Proj |
--------------|-------|------|--------|-------|--------|------|
WorldStatic   |   ■   |  ■   |   ■    |   ■   |   ·    |  ■   |
PlayerChar    |   ■   |  ■   |   ·    |   ■   |   ■    |  ■   |
EnemyChar     |   ■   |  ■   |   ■    |   ○   |   ■    |  ■   |
Projectile    |   ■   |  ○   |   ■    |   ■   |   ·    |  ·   |
Hitbox        |   ·   |  ○   |   ■    |   ■   |   ·    |  ·   |
```

### Step 4: Identify Issues

```markdown
### Issues Found

#### [ERROR] Asymmetric Response
- **Between**: PlayerCharacter ↔ EnemyCharacter
- **Player→Enemy**: Block
- **Enemy→Player**: Block
- **Status**: OK (symmetric)

#### [WARNING] Missing Hitbox Response
- **Preset**: InteractableObject
- **Channel**: SipherHitbox
- **Current**: Not specified (uses default)
- **Expected**: Overlap or Ignore
- **Fix**: Add explicit response in preset

#### [WARNING] Unused Channel
- **Channel**: ECC_GameTraceChannel5 (SipherDebugTrace)
- **Usage**: No actors or traces reference this
- **Fix**: Remove or document purpose

#### [INFO] Overlapping Presets
- **Presets**: EnemyCharacter, BossCharacter
- **Difference**: Only Boss blocks SipherInteractable
- **Suggestion**: Consider inheriting or documenting reason
```

## Common Collision Patterns

### Character Collision

```cpp
// Standard character preset pattern
Profile = "SipherCharacter"
ObjectType = ECC_Pawn

// Responses
WorldStatic: Block
WorldDynamic: Block
Pawn: Block (or Overlap for AI-to-AI)
PhysicsBody: Block
Vehicle: Block
Destructible: Block

// Custom channels
SipherHitbox: Block (receive damage)
SipherProjectile: Block (hit by projectiles)
SipherInteractable: Overlap (can interact)
```

### Hitbox Collision

```cpp
// Hitbox preset pattern
Profile = "SipherHitbox"
ObjectType = ECC_GameTraceChannel1

// Responses
WorldStatic: Ignore
WorldDynamic: Ignore
Pawn: Overlap (detect hit, don't block)
SipherHitbox: Ignore (don't hit other hitboxes)

// Enable overlap events
bGenerateOverlapEvents = true
```

### Projectile Collision

```cpp
// Projectile preset pattern
Profile = "SipherProjectile"
ObjectType = ECC_GameTraceChannel2

// Responses
WorldStatic: Block (stop on walls)
WorldDynamic: Block
Pawn: Block (hit characters)
SipherHitbox: Ignore (don't interact with melee hitboxes)
SipherProjectile: Ignore (don't hit other projectiles)
```

## Trace Channel Best Practices

| Trace Type | Channel | Use For |
|------------|---------|---------|
| Damage | SipherDamageTrace | Hit detection, line traces |
| Visibility | SipherVisibilityTrace | AI sight, cover checks |
| Interaction | SipherInteractionTrace | Interactable detection |
| Navigation | SipherNavTrace | Path validation |

## Report Template

```markdown
# Collision Audit Report

## Executive Summary
- **Channels Defined**: {N}
- **Presets Defined**: {N}
- **Issues Found**: {N}

## Channel Usage
| Channel | Presets Using | Actors Using |
|---------|---------------|--------------|
| {Channel} | {N} | {N} |

## Preset Coverage
| Actor Type | Preset | Status |
|------------|--------|--------|
| Player | PlayerCharacter | OK |
| Enemy | EnemyCharacter | OK |
| Boss | BossCharacter | Missing response |

## Response Matrix
{Visual matrix}

## Issues by Severity
### Errors
1. {Error}

### Warnings
1. {Warning}

## Recommendations
1. {Recommendation}

## Cleanup Opportunities
- Unused channels to remove: {List}
- Redundant presets to merge: {List}
```

## Console Commands

| Command | Purpose |
|---------|---------|
| `show Collision` | Visualize collision |
| `p.DebugDraw 1` | Physics debug draw |
| `CollisionAnalyzer` | Built-in collision tool |
