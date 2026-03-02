---
name: ue-enemy-preflight-check
description: Pre-commit validation for enemy content including BT references, animations, GAS abilities, collision, and data assets. Use before committing enemy changes, validating enemy implementations, or checking enemy readiness. Triggers on "enemy validation", "enemy check", "preflight check", "enemy preflight", "validate enemy", "enemy readiness".
---

# UE Enemy Preflight Check

Comprehensive pre-commit validation for enemy content.

## Quick Start

1. Specify enemy class/blueprint
2. Run full validation suite
3. Get go/no-go status with issues

## Validation Suite

### 1. Blueprint Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Parent Class | Error | Must derive from ASipherAICharacter |
| Required Components | Error | Must have all core components |
| Property Defaults | Warning | Check sensible default values |
| BP Compile | Error | Must compile without errors |

### 2. Behavior Tree Validation

| Check | Severity | Description |
|-------|----------|-------------|
| BT Assigned | Error | Must have behavior tree |
| BT Valid | Error | BT passes validation |
| Blackboard Match | Error | BB keys match BT requirements |
| Services Configured | Warning | Required services present |

### 3. Animation Validation

| Check | Severity | Description |
|-------|----------|-------------|
| ABP Assigned | Error | Must have animation blueprint |
| Required Anims | Error | Core animations present |
| Montage References | Error | All montages exist and valid |
| Notify Coverage | Warning | Combat montages have notifies |

### 4. GAS Validation

| Check | Severity | Description |
|-------|----------|-------------|
| ASC Present | Error | Must have ability system |
| Abilities Granted | Error | Required abilities configured |
| Attributes Set | Error | Core attributes initialized |
| Effects Valid | Error | All referenced GE classes exist |

### 5. Collision Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Capsule Size | Warning | Appropriate for mesh |
| Collision Profile | Error | Uses project profile |
| Query Channels | Warning | Responds to expected queries |

### 6. Data Asset Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Visual Set | Warning | Visual set data assigned |
| Stats Data | Error | Stats data asset configured |
| Loot Table | Warning | Loot configured (if applicable) |

## Validation Workflow

### Step 1: Identify Enemy Assets

```markdown
## Enemy: {EnemyName}

### Asset Inventory
| Asset Type | Path | Status |
|------------|------|--------|
| Blueprint | BP_{EnemyName} | {Found/Missing} |
| Behavior Tree | BT_{EnemyName} | {Found/Missing} |
| Animation BP | ABP_{EnemyName} | {Found/Missing} |
| Blackboard | BB_{EnemyName} | {Found/Missing} |
| Stats Data | DA_{EnemyName}_Stats | {Found/Missing} |
```

### Step 2: Run Validation

```markdown
## Preflight Validation: {EnemyName}

### Quick Status
| Category | Status |
|----------|--------|
| Blueprint | {PASS/FAIL} |
| Behavior | {PASS/FAIL} |
| Animation | {PASS/FAIL} |
| Combat/GAS | {PASS/FAIL} |
| Collision | {PASS/FAIL} |
| Data | {PASS/FAIL} |

### Overall: {GO/NO-GO}
```

### Step 3: Detailed Report

```markdown
### Blueprint Validation

#### Components
| Component | Type | Status |
|-----------|------|--------|
| AbilitySystem | USipherAbilitySystemComponent | {Present/Missing} |
| CombatComponent | USipherEnemyCombatComponent | {Present/Missing} |
| CharacteristicsComponent | USipherEnemyCharacteristicsComponent | {Present/Missing} |
| HitReaction | USipherHitReaction | {Present/Missing} |

#### [ERROR] Missing Required Component
- **Component**: USipherEnemyCombatComponent
- **Fix**: Add component in BP Components panel

---

### Behavior Tree Validation

#### BT Analysis
- **Tree**: BT_{EnemyName}
- **Blackboard**: BB_{EnemyName}
- **Node Count**: {N}

#### Blackboard Keys
| Key | Type | Used | Set |
|-----|------|------|-----|
| TargetActor | Object | {Yes/No} | {Yes/No} |
| HomeLocation | Vector | {Yes/No} | {Yes/No} |

#### [ERROR] Blackboard Key Mismatch
- **Key**: TargetActor
- **Expected Type**: AActor*
- **Actual Type**: None (not defined)
- **Fix**: Add key to BB_{EnemyName}

---

### Animation Validation

#### Required Animations
| Animation | Slot | Status |
|-----------|------|--------|
| Idle | DefaultSlot | {Present/Missing} |
| Walk | DefaultSlot | {Present/Missing} |
| Attack_01 | FullBody | {Present/Missing} |
| Hit_Front | FullBody | {Present/Missing} |
| Death | FullBody | {Present/Missing} |

#### Montage Issues
| Montage | Issue |
|---------|-------|
| AMT_{EnemyName}_Attack_01 | Missing hitbox notify |

---

### GAS Validation

#### Abilities
| Ability | Granted | Status |
|---------|---------|--------|
| GA_{EnemyName}_Attack | {Yes/No} | {Valid/Invalid} |
| GA_Common_Death | {Yes/No} | {Valid/Invalid} |

#### Attributes
| Attribute | Initial Value | Status |
|-----------|---------------|--------|
| Health | {Value} | {OK/Warning} |
| MaxHealth | {Value} | {OK/Warning} |
| AttackPower | {Value} | {OK/Warning} |

---

### Collision Validation

#### Capsule
- **Radius**: {N} cm
- **Half Height**: {N} cm
- **Mesh Fit**: {Good/Adjust}

#### Profile
- **Current**: {ProfileName}
- **Expected**: EnemyCharacter
- **Status**: {Match/Mismatch}
```

## Required Components Checklist

### ASipherAICharacter Derivatives

| Component | Required | Purpose |
|-----------|----------|---------|
| USipherAbilitySystemComponent | Yes | GAS functionality |
| USipherEnemyCombatComponent | Yes | Combat coordination |
| USipherEnemyCharacteristicsComponent | Yes | AI characteristics |
| USipherHitReaction | Yes | Hit reaction handling |
| USipherEnemyAnimationComponent | Yes | Animation control |
| USipherVisualSetComponent | No | Visual customization |
| USipherRetributionComponent | No | Finisher support |

## Common Issues & Fixes

### Missing Behavior Tree

```
Issue: Enemy has no behavior tree assigned
Impact: AI will not function
Fix:
1. Create BT_{EnemyName} in Content/S2/BehaviorTrees/Enemies/
2. Assign to AIControllerClass or character default
```

### Ability Not Granting

```
Issue: Ability configured but not granting
Impact: Enemy cannot use ability
Fix:
1. Check ability is in GrantedAbilities array
2. Verify ability class exists and compiles
3. Check ASC initialization order
```

### Animation Montage Missing

```
Issue: BT references montage that doesn't exist
Impact: Animation will fail, potential crash
Fix:
1. Create missing montage
2. Or update BT task to use existing montage
```

## Output Report

```markdown
# Enemy Preflight Report: {EnemyName}

## Status: {GO / NO-GO / CONDITIONAL}

## Blocking Issues (Must Fix)
1. {Issue}

## Warnings (Should Review)
1. {Issue}

## Passed Checks
- {Check}: OK

## Commit Recommendation
{Recommendation based on findings}

## Testing Notes
- {Specific things to test}
```

## Integration with Git Hooks

```bash
# Pre-commit hook example
# Run preflight for modified enemy BPs
for file in $(git diff --cached --name-only | grep "BP_.*Enemy"); do
    claude-code run ue-enemy-preflight-check "$file"
done
```
