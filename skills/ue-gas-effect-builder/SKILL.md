---
name: ue-gas-effect-builder
description: Generate Gameplay Effect assets from design specifications including duration, modifiers, stacking, and tags. Use when creating damage effects, buffs, debuffs, or any GAS effect configuration. Triggers on "gameplay effect", "create effect", "GAS effect", "damage effect", "buff", "debuff", "status effect".
---

# UE GAS Effect Builder

Generate Gameplay Effect configurations from design parameters.

## Quick Start

1. Specify effect type (damage, buff, debuff, etc.)
2. Define modifiers, duration, stacking
3. Generate effect class or asset configuration

## Effect Types

| Type | Duration | Use Case |
|------|----------|----------|
| Instant | None | Immediate damage/heal |
| Duration | Fixed time | Timed buffs/debuffs |
| Infinite | Until removed | Passive abilities |
| Periodic | Interval | DoT/HoT effects |

## Generation Workflow

### Step 1: Gather Requirements

Ask user for:
1. **Effect Name**: e.g., "Burn", "ArmorBuff", "StaminaDrain"
2. **Duration Type**: Instant, Duration, Infinite, Periodic
3. **Modifiers**: What attributes to modify and how
4. **Stacking**: How multiple applications interact
5. **Tags**: Granted tags, removal tags, immunity

### Step 2: Generate Configuration

#### Instant Damage Effect

```cpp
// GE_Damage_Physical.h (or Blueprint asset)
UCLASS()
class UGE_Damage_Physical : public UGameplayEffect
{
    GENERATED_BODY()

public:
    UGE_Damage_Physical()
    {
        DurationPolicy = EGameplayEffectDurationType::Instant;

        // Modifier: Subtract from Health
        FGameplayModifierInfo Modifier;
        Modifier.Attribute = USipherBaseAttributeSet::GetHealthAttribute();
        Modifier.ModifierOp = EGameplayModOp::Additive;
        Modifier.ModifierMagnitude = FGameplayEffectModifierMagnitude(
            FScalableFloat(-100.f)  // Base damage, scaled by caller
        );
        Modifiers.Add(Modifier);

        // Execution for complex damage calculation
        // Executions.Add(USipherDamageExecution::StaticClass());
    }
};
```

#### Duration Buff Effect

```cpp
// GE_Buff_AttackSpeed
DurationPolicy = EGameplayEffectDurationType::HasDuration;
DurationMagnitude = FGameplayEffectModifierMagnitude(FScalableFloat(10.f)); // 10 seconds

// Modifier: Multiply Attack Speed
FGameplayModifierInfo Modifier;
Modifier.Attribute = USipherOffensiveAttributeSet::GetAttackSpeedAttribute();
Modifier.ModifierOp = EGameplayModOp::Multiply;
Modifier.ModifierMagnitude = FGameplayEffectModifierMagnitude(FScalableFloat(1.25f)); // +25%

// Granted Tag while active
InheritableOwnedTagsContainer.AddTag(FGameplayTag::RequestGameplayTag("State.Buff.AttackSpeed"));
```

#### Periodic DoT Effect

```cpp
// GE_DoT_Burn
DurationPolicy = EGameplayEffectDurationType::HasDuration;
DurationMagnitude = FGameplayEffectModifierMagnitude(FScalableFloat(5.f)); // 5 seconds

// Periodic damage
Period = 1.0f;  // Every 1 second
bExecutePeriodicEffectOnApplication = false;  // Don't tick immediately

// Periodic execution (damage per tick)
FGameplayEffectExecutionDefinition Execution;
Execution.CalculationClass = USipherBurnDamageCalculation::StaticClass();
Executions.Add(Execution);

// Visual cue tag
InheritableOwnedTagsContainer.AddTag(FGameplayTag::RequestGameplayTag("State.Effect.Burning"));
```

### Step 3: Stacking Configuration

#### Stack by Source

```cpp
// Multiple sources can apply stacks
StackingType = EGameplayEffectStackingType::AggregateBySource;
StackLimitCount = 5;
StackDurationRefreshPolicy = EGameplayEffectStackingDurationPolicy::RefreshOnSuccessfulApplication;
StackPeriodResetPolicy = EGameplayEffectStackingPeriodPolicy::ResetOnSuccessfulApplication;
```

#### Stack by Target

```cpp
// All applications merge into one stack
StackingType = EGameplayEffectStackingType::AggregateByTarget;
StackLimitCount = 10;

// Overflow handling
OverflowEffects.Add(USipherStackOverflowEffect::StaticClass());
bDenyOverflowApplication = false;
```

#### No Stacking

```cpp
// Only one instance allowed
StackingType = EGameplayEffectStackingType::None;
// Or use tags to block reapplication
```

### Step 4: Tag Configuration

```cpp
// Tags granted while effect is active
InheritableOwnedTagsContainer.AddTag(FGameplayTag::RequestGameplayTag("State.Debuff.Slow"));

// Tags that block this effect from applying
ApplicationTagRequirements.RequireTags.AddTag(FGameplayTag::RequestGameplayTag("State.Alive"));
ApplicationTagRequirements.IgnoreTags.AddTag(FGameplayTag::RequestGameplayTag("State.Immune.Debuff"));

// Tags that remove this effect when gained
OngoingTagRequirements.RequireTags.AddTag(FGameplayTag::RequestGameplayTag("State.Alive"));
RemovalTagRequirements.RemoveTags.AddTag(FGameplayTag::RequestGameplayTag("State.Cleansed"));

// Asset tags (for querying/grouping)
InheritableGameplayEffectTags.AddTag(FGameplayTag::RequestGameplayTag("Effect.Damage.Physical"));
```

## Common Effect Patterns

### Damage Effect with Execution

```cpp
// For complex damage with armor, crit, resistances
FGameplayEffectExecutionDefinition Execution;
Execution.CalculationClass = USipherDamageExecution::StaticClass();

// Pass data via SetByCaller
Execution.CalculationModifiers.Add(FGameplayEffectExecutionScopedModifierInfo(
    FGameplayTag::RequestGameplayTag("Data.Damage.Base"),
    EGameplayModOp::Override,
    FSetByCallerFloat()
));
```

### Cooldown Effect

```cpp
// Standard cooldown pattern
DurationPolicy = EGameplayEffectDurationType::HasDuration;
DurationMagnitude = FGameplayEffectModifierMagnitude(FScalableFloat(CooldownDuration));

// Cooldown tag (blocks ability reactivation)
InheritableOwnedTagsContainer.AddTag(FGameplayTag::RequestGameplayTag("Ability.Cooldown.Slash"));
```

### Cost Effect

```cpp
// Resource cost pattern
DurationPolicy = EGameplayEffectDurationType::Instant;

FGameplayModifierInfo Modifier;
Modifier.Attribute = USipherConsumableAttributeSet::GetStaminaAttribute();
Modifier.ModifierOp = EGameplayModOp::Additive;
Modifier.ModifierMagnitude = FGameplayEffectModifierMagnitude(FScalableFloat(-25.f));
```

## Output Formats

### Blueprint Asset (Recommended for Designers)

```
Asset: Content/S2/Core/GAS/Effects/GE_{EffectName}
Type: GameplayEffect Blueprint
Configure via Details panel
```

### C++ Class (For Programmers)

```cpp
// Header in Source/S2/Public/GAS/Effects/
// Implementation with constructor configuration
// Register in module startup or use default subobject
```

### DataTable Row (For Data-Driven Effects)

```cpp
USTRUCT()
struct FEffectDefinition : public FTableRowBase
{
    UPROPERTY(EditAnywhere)
    TSubclassOf<UGameplayEffect> EffectClass;

    UPROPERTY(EditAnywhere)
    float BaseMagnitude;

    UPROPERTY(EditAnywhere)
    FGameplayTagContainer RequiredTags;
};
```

## Sipher Effect Conventions

### Naming

| Type | Prefix | Example |
|------|--------|---------|
| Damage | `GE_Damage_` | `GE_Damage_Physical` |
| Buff | `GE_Buff_` | `GE_Buff_AttackSpeed` |
| Debuff | `GE_Debuff_` | `GE_Debuff_Slow` |
| Cost | `GE_Cost_` | `GE_Cost_Stamina` |
| Cooldown | `GE_Cooldown_` | `GE_Cooldown_Slash` |
| DoT | `GE_DoT_` | `GE_DoT_Burn` |
| HoT | `GE_HoT_` | `GE_HoT_Regen` |

### Tag Hierarchy

```
Effect.
├── Damage.
│   ├── Physical
│   ├── Elemental.Fire
│   └── True
├── Buff.
│   ├── Offensive
│   └── Defensive
├── Debuff.
│   ├── Slow
│   └── Weaken
└── Status.
    ├── Burning
    └── Frozen
```

## Report Template

```markdown
# Gameplay Effect Specification: {EffectName}

## Configuration
| Property | Value |
|----------|-------|
| Duration Type | {Type} |
| Duration | {N}s |
| Period | {N}s |
| Stacking | {Type} |
| Stack Limit | {N} |

## Modifiers
| Attribute | Operation | Magnitude |
|-----------|-----------|-----------|
| {Attr} | {Op} | {Value} |

## Tags
| Category | Tags |
|----------|------|
| Granted | {Tags} |
| Required | {Tags} |
| Blocked | {Tags} |
| Removal | {Tags} |

## Generated Code
{Code snippet or asset path}
```
