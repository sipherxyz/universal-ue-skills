---
name: ue-gas-ability-generator
description: Generate GAS (Gameplay Ability System) ability classes with proper structure, tags, costs, cooldowns, and Sipher project patterns. Use when creating new gameplay abilities, implementing combat actions, or scaffolding GAS ability code. Triggers on "create ability", "new ability", "GAS ability", "gameplay ability", "ability class", "combat ability".
---

# UE GAS Ability Generator

Generate fully-structured Gameplay Ability classes following Sipher/Huli project patterns.

## Quick Start

1. Specify ability name and type
2. Define activation requirements (cost, cooldown, tags)
3. Generate header + implementation files

## Ability Types

| Type | Base Class | Use Case |
|------|------------|----------|
| Basic | `USipherGameplayAbility` | Simple one-shot abilities |
| Combat | `USipherCombatAbility` | Melee/ranged attacks with hitboxes |
| Runtime | `USipherGameplayAbilityRuntime` | Data-driven abilities from DataAssets |
| Spell | `USipherSpellsAbility` | Projectile/area abilities |
| Execution | `USipherExecutionAbility` | Finisher/execution animations |

## Generation Workflow

### Step 1: Gather Requirements

Ask user for:
1. **Ability Name**: e.g., "GroundSlam", "DashAttack"
2. **Ability Type**: Combat, Spell, Basic, etc.
3. **Activation**: Input triggered, event triggered, passive
4. **Cost**: Stamina, Mana, or custom attribute
5. **Cooldown**: Duration and tag
6. **Gameplay Tags**: Required, blocked, activation tags

### Step 2: Generate Header

Template for `USipherGameplayAbility` subclass:

```cpp
// {AbilityName}.h
#pragma once

#include "CoreMinimal.h"
#include "GameplayAbilities/SipherGameplayAbility.h"
#include "{AbilityName}.generated.h"

/**
 * {Brief description of what the ability does}
 *
 * @note Activation: {How it activates}
 * @note Cost: {What it costs}
 * @note Cooldown: {Cooldown duration}
 */
UCLASS()
class S2_API U{AbilityName} : public USipherGameplayAbility
{
    GENERATED_BODY()

public:
    U{AbilityName}();

    //~ Begin UGameplayAbility Interface
    virtual bool CanActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayTagContainer* SourceTags = nullptr, const FGameplayTagContainer* TargetTags = nullptr, FGameplayTagContainer* OptionalRelevantTags = nullptr) const override;
    virtual void ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData) override;
    virtual void EndAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, bool bReplicateEndAbility, bool bWasCancelled) override;
    //~ End UGameplayAbility Interface

protected:
    /** Montage to play during ability */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Animation")
    TObjectPtr<UAnimMontage> AbilityMontage;

    /** Gameplay Effect applied on hit (if combat ability) */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Effects")
    TSubclassOf<UGameplayEffect> DamageEffectClass;

    /** Called when montage ends or is interrupted */
    UFUNCTION()
    void OnMontageCompleted();

    UFUNCTION()
    void OnMontageCancelled();

private:
    /** Handle for montage ended delegate */
    FOnMontageEnded MontageEndedDelegate;

    /** Handle for montage blending out delegate */
    FOnMontageBlendingOutStarted MontageBlendingOutDelegate;
};
```

### Step 3: Generate Implementation

```cpp
// {AbilityName}.cpp
#include "GameplayAbilities/{AbilityName}.h"
#include "AbilitySystemComponent.h"
#include "GameFramework/Character.h"

U{AbilityName}::U{AbilityName}()
{
    // Ability configuration
    InstancingPolicy = EGameplayAbilityInstancingPolicy::InstancedPerActor;
    NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;

    // Activation
    AbilityTags.AddTag(FGameplayTag::RequestGameplayTag(FName("{Ability.Tag.Name}")));
    ActivationOwnedTags.AddTag(FGameplayTag::RequestGameplayTag(FName("{State.Ability.Active}")));

    // Blocking/Cancellation
    CancelAbilitiesWithTag.AddTag(FGameplayTag::RequestGameplayTag(FName("{Ability.Cancelable}")));
    BlockAbilitiesWithTag.AddTag(FGameplayTag::RequestGameplayTag(FName("{Ability.Blocked}")));

    // Activation requirements
    ActivationBlockedTags.AddTag(FGameplayTag::RequestGameplayTag(FName("{State.Dead}")));
    ActivationBlockedTags.AddTag(FGameplayTag::RequestGameplayTag(FName("{State.Stunned}")));
}

bool U{AbilityName}::CanActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayTagContainer* SourceTags, const FGameplayTagContainer* TargetTags, FGameplayTagContainer* OptionalRelevantTags) const
{
    if (!Super::CanActivateAbility(Handle, ActorInfo, SourceTags, TargetTags, OptionalRelevantTags))
    {
        return false;
    }

    // Custom activation checks
    // e.g., check for valid target, sufficient resources, etc.

    return true;
}

void U{AbilityName}::ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData)
{
    if (!CommitAbility(Handle, ActorInfo, ActivationInfo))
    {
        EndAbility(Handle, ActorInfo, ActivationInfo, true, true);
        return;
    }

    ACharacter* Character = Cast<ACharacter>(ActorInfo->AvatarActor.Get());
    if (!Character)
    {
        EndAbility(Handle, ActorInfo, ActivationInfo, true, true);
        return;
    }

    // Play montage
    if (AbilityMontage)
    {
        UAbilitySystemComponent* ASC = ActorInfo->AbilitySystemComponent.Get();
        if (ASC)
        {
            MontageEndedDelegate.BindUObject(this, &U{AbilityName}::OnMontageCompleted);
            MontageBlendingOutDelegate.BindUObject(this, &U{AbilityName}::OnMontageCancelled);

            ASC->PlayMontageWithBlendSettings(this, ActivationInfo, AbilityMontage, 1.0f, NAME_None, MontageEndedDelegate, MontageBlendingOutDelegate);
        }
    }
    else
    {
        // No montage - end immediately or implement custom logic
        EndAbility(Handle, ActorInfo, ActivationInfo, true, false);
    }
}

void U{AbilityName}::EndAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, bool bReplicateEndAbility, bool bWasCancelled)
{
    // Cleanup
    MontageEndedDelegate.Unbind();
    MontageBlendingOutDelegate.Unbind();

    Super::EndAbility(Handle, ActorInfo, ActivationInfo, bReplicateEndAbility, bWasCancelled);
}

void U{AbilityName}::OnMontageCompleted()
{
    if (IsActive())
    {
        EndAbility(CurrentSpecHandle, CurrentActorInfo, CurrentActivationInfo, true, false);
    }
}

void U{AbilityName}::OnMontageCancelled()
{
    if (IsActive())
    {
        EndAbility(CurrentSpecHandle, CurrentActorInfo, CurrentActivationInfo, true, true);
    }
}
```

### Step 4: Generate Gameplay Effect (Cost/Cooldown)

```cpp
// In DataAsset or Blueprint
// Cost Effect - GE_{AbilityName}_Cost
// - Duration: Instant
// - Modifier: Attribute (e.g., Stamina) - Add - Magnitude: -{CostValue}

// Cooldown Effect - GE_{AbilityName}_Cooldown
// - Duration: {CooldownSeconds}
// - Granted Tag: Ability.Cooldown.{AbilityName}
```

## Tag Structure

Follow Sipher tag conventions:

```
Ability.{Category}.{Name}          // Ability identity
Ability.Cooldown.{Name}            // Cooldown tag
State.Ability.{Name}.Active        // Active state
Ability.Blocked.By.{Condition}     // Blocking tags
```

## Output Files

Generate these files:
1. `Source/S2/Public/GameplayAbilities/{AbilityName}.h`
2. `Source/S2/Private/GameplayAbilities/{AbilityName}.cpp`
3. Tag definitions for `Config/Tags/SipherAbilitiesTags.ini`

## Combat Ability Variant

For combat abilities with hitboxes:

```cpp
// Additional includes
#include "SipherHitbox/SipherHitboxComponent.h"

// Additional properties
UPROPERTY(EditDefaultsOnly, Category = "Combat")
TSubclassOf<USipherHitboxComponent> HitboxClass;

// In ActivateAbility - spawn hitbox via AnimNotify or directly
// Hitbox handles damage application via DamageEffectClass
```

## Best Practices

1. **Always use CommitAbility** before executing ability logic
2. **Bind and unbind delegates** properly in EndAbility
3. **Check IsActive()** before ending from callbacks
4. **Use InstancedPerActor** for abilities with state
5. **Apply tags** for state tracking and ability blocking
6. **Handle cancellation** gracefully in OnMontageCancelled
