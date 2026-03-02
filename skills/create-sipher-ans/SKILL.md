---
name: create-sipher-ans
description: Create SipherANS (AnimNotifyState) with proper GAS integration and UniversalDamage pipeline compliance
---

# Create SipherANS Skill

**Role:** Combat AnimNotifyState Generator
**Scope:** `Source/S2/Private/AnimNotify/SipherANS_*.cpp`, `Source/S2/Public/AnimNotify/SipherANS_*.h`
**Purpose:** Ensure consistent GAS integration quality for all combat animation notify states

## Overview

This skill guides creation of `SipherANS_*` classes that properly integrate with:
- **UniversalDamage Pipeline** - Hit reactions, damage feedback, combat events
- **Gameplay Ability System (GAS)** - Ability wait tasks, effect application
- **Combat Systems** - Team filtering, parry detection, AI threat perception

## Critical Requirements Checklist

Before marking ANY damage-dealing ANS as complete, verify ALL items:

- [ ] Uses `FSipherEntityDamageEvent` (NOT direct GE application)
- [ ] Calls `USipherDamageLibrary::ApplyFlatDamageWithContext()` for damage
- [ ] Sets `DamageImpact` in damage event (for hit reaction type)
- [ ] Sets `HitResult` in damage event (for hit direction)
- [ ] Sets `DamageInstigator` and `Causer` in damage event
- [ ] Async loads all soft references in `PostLoad()` (console cert)
- [ ] Includes team filtering via `IGenericTeamAgentInterface`
- [ ] Has hit deduplication to prevent multi-hit spam

## Required Includes

```cpp
// GAS Core
#include "AbilitySystemComponent.h"
#include "AbilitySystemGlobals.h"

// UniversalDamage Pipeline (CRITICAL)
#include "UniversalDamage/SipherDamageLibrary.h"
#include "UniversalDamage/SipherEntityDamageEvent.h"

// GAS Tags
#include "Core/ASC/SipherGasTags.h"

// Team System
#include "GenericTeamAgentInterface.h"

// Base Class
#include "SipherANS_VFXBase.h"  // or appropriate base
```

## Damage Application Pattern

### WRONG - Direct GE Application (Bypasses Pipeline)

```cpp
// DO NOT DO THIS - Bypasses hit reactions, damage feedback, and combat events
FGameplayEffectSpecHandle SpecHandle = OwnerASC->MakeOutgoingSpec(EffectClass, 1.f, Context);
SpecHandle.Data->SetSetByCallerMagnitude(SipherNativeParams::UniversalDamage_MotionValue, MotionValue);
OwnerASC->ApplyGameplayEffectSpecToTarget(*SpecHandle.Data.Get(), TargetASC);  // WRONG!
```

### CORRECT - UniversalDamage Pipeline

```cpp
// Create proper damage event with all required fields
FSipherEntityDamageEvent DamageEvent;
DamageEvent.DamageInstigator = Owner;           // Who dealt damage
DamageEvent.Causer = Owner;                     // What caused damage (can be different for projectiles)
DamageEvent.DamageEntity = HitActor;            // Who receives damage
DamageEvent.DamageImpact = DamageImpact;        // Hit reaction type (Light/Heavy/Knockdown)
DamageEvent.HitResult = Hit;                    // For hit direction calculation
DamageEvent.DamageForce.ForceDirection = ForceDir;  // Knockback direction

// Set damage params
TMap<FGameplayTag, float> FloatParams;
FloatParams.Add(SipherNativeParams::UniversalDamage_MotionValue, MotionValue);

// Apply through pipeline - enables hit reactions, damage feedback, ability wait tasks
USipherDamageLibrary::ApplyFlatDamageWithContext(HitActor, DamageEvent, FloatParams);
```

## Standard Property Template

Every damage-dealing ANS should have these configurable properties:

```cpp
// ============== Damage Configuration ==============

/** Motion value for damage calculation (ratio of BaseDamage) */
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Damage", meta = (ClampMin = "0.0", ClampMax = "5.0"))
float MotionValue = 1.0f;

/** Damage impact level (determines hit reaction type) */
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Damage")
EDamageImpact DamageImpact = EDamageImpact::EDI_LIGHT;

/** GameplayEffect for damage (uses UniversalDamage pipeline) */
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Damage")
TSoftClassPtr<UGameplayEffect> DamageEffect;

/** Status effect to apply on hit (optional) */
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Damage")
TSoftClassPtr<UGameplayEffect> StatusEffectGE;

/** Collision channel for damage detection */
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Damage")
TEnumAsByte<ECollisionChannel> DamageCollisionChannel = ECC_Pawn;

/** Only damage actors on opposing teams */
UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Damage")
bool bFilterByTeam = true;
```

## Async Loading (Console Certification)

**NEVER use `LoadSynchronous()` in shipping builds.** Always async load in `PostLoad()`:

```cpp
void USipherANS_MyNotify::PostLoad()
{
    Super::PostLoad();

    FStreamableManager& StreamableManager = UAssetManager::Get().GetStreamableManager();

    // Async load class references
    if (!DamageEffect.IsNull())
    {
        DamageEffectHandle = StreamableManager.RequestAsyncLoad(DamageEffect.ToSoftObjectPath());
    }

    if (!StatusEffectGE.IsNull())
    {
        StatusEffectHandle = StreamableManager.RequestAsyncLoad(StatusEffectGE.ToSoftObjectPath());
    }

    // VFX assets - use base class helper if inheriting from SipherANS_VFXBase
    RequestVFXAsyncLoad(ImpactVFX);
}
```

## Team Filtering Pattern

```cpp
bool USipherANS_MyNotify::ShouldDamageActor(AActor* TargetActor) const
{
    if (!IsValid(TargetActor) || !CachedOwner.IsValid())
    {
        return false;
    }

    // Get team agents (checks Controller first for Pawns per UE convention)
    const IGenericTeamAgentInterface* OwnerTeamAgent = Cast<IGenericTeamAgentInterface>(CachedOwner.Get());
    const IGenericTeamAgentInterface* TargetTeamAgent = Cast<IGenericTeamAgentInterface>(TargetActor);

    // Check controller if pawn doesn't have interface
    if (!OwnerTeamAgent)
    {
        if (const APawn* OwnerPawn = Cast<APawn>(CachedOwner.Get()))
        {
            OwnerTeamAgent = Cast<IGenericTeamAgentInterface>(OwnerPawn->GetController());
        }
    }

    if (!TargetTeamAgent)
    {
        if (const APawn* TargetPawn = Cast<APawn>(TargetActor))
        {
            TargetTeamAgent = Cast<IGenericTeamAgentInterface>(TargetPawn->GetController());
        }
    }

    // If either doesn't have team info, allow damage (neutral)
    if (!OwnerTeamAgent || !TargetTeamAgent)
    {
        return true;
    }

    // Only damage hostile or neutral, not friendly
    const ETeamAttitude::Type Attitude = OwnerTeamAgent->GetTeamAttitudeTowards(*TargetActor);
    return Attitude != ETeamAttitude::Friendly;
}
```

## Hit Deduplication Pattern

Prevent same actor from being hit multiple times per damage tick:

```cpp
// In class header
TSet<TWeakObjectPtr<AActor>> HitActorsThisTick;

// In damage tick
void USipherANS_MyNotify::ApplyDamage(const TArray<FHitResult>& Hits)
{
    // Reset at start of each damage tick
    HitActorsThisTick.Empty();

    for (const FHitResult& Hit : Hits)
    {
        AActor* HitActor = Hit.GetActor();

        // Deduplication check
        TWeakObjectPtr<AActor> WeakHitActor = HitActor;
        if (HitActorsThisTick.Contains(WeakHitActor))
        {
            continue;
        }
        HitActorsThisTick.Add(WeakHitActor);

        // Apply damage...
    }
}
```

## Status Effect Application

Status effects go through GAS directly (they have their own stacking/duration rules):

```cpp
// Apply status effect via GameplayEffect (separate from damage)
if (UClass* StatusEffectClass = StatusEffectGE.Get())
{
    UAbilitySystemComponent* TargetASC = UAbilitySystemGlobals::GetAbilitySystemComponentFromActor(HitActor);
    if (TargetASC)
    {
        FGameplayEffectContextHandle Context = OwnerASC->MakeEffectContext();
        Context.AddSourceObject(Owner);
        Context.AddHitResult(Hit);

        FGameplayEffectSpecHandle StatusSpecHandle = OwnerASC->MakeOutgoingSpec(StatusEffectClass, 1.f, Context);
        if (StatusSpecHandle.IsValid())
        {
            OwnerASC->ApplyGameplayEffectSpecToTarget(*StatusSpecHandle.Data.Get(), TargetASC);
        }
    }
}
```

## DamageImpact Values Reference

| Value | Use Case | Hit Reaction |
|-------|----------|--------------|
| `EDI_NONE` | No hit reaction desired | None |
| `EDI_LIGHT` | Light attacks, DoT ticks | Small flinch |
| `EDI_HEAVY` | Heavy attacks, charged hits | Stagger |
| `EDI_KNOCKDOWN` | Knockdown attacks | Full knockdown |
| `EDI_KNOCKBACK` | Pushback attacks | Knockback + stagger |
| `EDI_LAUNCHER` | Launcher attacks | Launch into air |

## What UniversalDamage Pipeline Enables

When using `USipherDamageLibrary::ApplyFlatDamageWithContext()`:

| Feature | Description |
|---------|-------------|
| **Hit Reactions** | Target plays appropriate reaction animation based on `DamageImpact` |
| **Damage Feedback VFX** | Visual feedback via `DamageFeedbackVFXTag` |
| **BroadcastOnHitBeforeApplyDamage** | Ability wait tasks (parry detection) get notified |
| **AI Threat Perception** | AI systems update threat levels |
| **Damage Numbers** | UI damage number spawning |
| **Combat Events** | Combat log, analytics, achievements |

## Common Mistakes to Avoid

| Mistake | Impact | Fix |
|---------|--------|-----|
| Direct `ApplyGameplayEffectSpecToTarget()` | No hit reactions | Use `ApplyFlatDamageWithContext()` |
| `DamageImpact` property unused | No stagger/flinch | Set in `FSipherEntityDamageEvent` |
| Missing `HitResult` | Wrong hit direction | Set `DamageEvent.HitResult = Hit` |
| `LoadSynchronous()` in tick | Console cert fail | Async load in `PostLoad()` |
| No team filtering | Friendly fire | Implement `ShouldDamageActor()` |
| No hit deduplication | Multi-hit spam | Use `HitActorsThisTick` set |

## File Naming Convention

```
Source/S2/Public/AnimNotify/SipherANS_{Category}{Name}.h
Source/S2/Private/AnimNotify/SipherANS_{Category}{Name}.cpp

Examples:
- SipherANS_EnemyBreathCone.h    (Enemy breath attack)
- SipherANS_PlayerGroundSlam.h   (Player ground slam)
- SipherANS_BeamTrace.h          (Generic beam attack)
- SipherANS_AOEExplosion.h       (Area explosion)
```

## Class Metadata

Use UCLASS meta for montage notify picker:

```cpp
UCLASS(meta = (
    DisplayName = "[Combat] My Attack Name",
    CombatCategory = "Enemy|Attack",  // or "Player|Attack", "Boss|Special"
    CombatTooltip = "Brief description of what this notify does",
    CombatSortPriority = "4"
))
class S2_API USipherANS_MyNotify : public USipherANS_VFXBase
{
    // ...
};
```

## Review Checklist Before PR

1. [ ] All damage uses `USipherDamageLibrary::ApplyFlatDamageWithContext()`
2. [ ] `DamageImpact` property is set in damage event
3. [ ] `HitResult` is set in damage event
4. [ ] All `TSoftClassPtr`/`TSoftObjectPtr` async loaded in `PostLoad()`
5. [ ] Team filtering implemented if `bFilterByTeam` is true
6. [ ] Hit deduplication prevents multi-hit per tick
7. [ ] No `LoadSynchronous()` calls (console cert)
8. [ ] UCLASS meta includes DisplayName and CombatCategory
9. [ ] Debug visualization toggled by `bDrawDebug` property

## Related Files

- `Source/S2/Public/UniversalDamage/SipherDamageLibrary.h` - Damage application API
- `Source/S2/Public/UniversalDamage/SipherEntityDamageEvent.h` - Damage event struct
- `Source/S2/Public/Core/ASC/SipherGasTags.h` - SetByCaller tag definitions
- `Source/S2/Public/Combat/CombatEnums.h` - EDamageImpact enum
- `.claude/rules/animation-notifies.md` - Montage track standards

## Legacy Metadata

```yaml
skill: create-sipher-ans
invoke: /combat-systems:create-sipher-ans
type: code-generation
category: combat
scope: Source/S2/Private/AnimNotify/*, Source/S2/Public/AnimNotify/*
```
