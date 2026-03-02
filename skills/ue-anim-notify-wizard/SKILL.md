---
name: ue-anim-notify-wizard
description: Interactive wizard for creating Animation Notify States (ANS) with proper GAS integration, Sipher patterns, and boilerplate generation. Use when creating new animation notifies, implementing montage-driven gameplay, or scaffolding ANS classes. Triggers on "create notify", "animation notify", "ANS", "anim notify state", "notify wizard", "montage notify".
---

# UE Animation Notify Wizard

Interactive wizard for creating Animation Notify States following Sipher project patterns.

## Quick Start

1. Choose notify type (combat, VFX, audio, gameplay)
2. Configure parameters
3. Generate header, implementation, and BP asset

## Notify Types

| Type | Base Class | Use Case |
|------|------------|----------|
| Combat Action | `USipherANS_CombatAction` | Hitboxes, damage windows |
| Gameplay Cue | `USipherANS_GameplayCue` | VFX/Audio via GAS |
| Warp/Position | `USipherANS_Warp` | Root motion warping |
| State Tag | `USipherANS_GrantTag` | Temporary tag grant |
| Ability Trigger | `USipherANS_TriggerAbility` | Ability activation |
| Custom | `UAnimNotifyState` | General purpose |

## Wizard Workflow

### Step 1: Gather Requirements

**Questions:**
1. Notify name (e.g., "HeavyAttack", "ParryWindow")
2. Notify type (combat, VFX, gameplay, custom)
3. Duration-based or instant?
4. Parameters needed (exposed to designers)
5. GAS integration required?

### Step 2: Generate Header

```cpp
// USipherANS_{NotifyName}.h
#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "GameplayTagContainer.h"
#include "USipherANS_{NotifyName}.generated.h"

/**
 * {Description of what this notify does}
 *
 * @note Duration: {Begin to End}
 * @note Usage: {When to use this notify}
 */
UCLASS(meta = (DisplayName = "{Display Name}"))
class S2_API USipherANS_{NotifyName} : public UAnimNotifyState
{
    GENERATED_BODY()

public:
    USipherANS_{NotifyName}();

    //~ Begin UAnimNotifyState Interface
    virtual void NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration, const FAnimNotifyEventReference& EventReference) override;
    virtual void NotifyTick(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float FrameDeltaTime, const FAnimNotifyEventReference& EventReference) override;
    virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference) override;
    virtual FString GetNotifyName_Implementation() const override;
    //~ End UAnimNotifyState Interface

protected:
    /** {Parameter description} */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "{Category}")
    {ParameterType} {ParameterName};

    /** Gameplay tag granted during notify */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Tags")
    FGameplayTag GrantedTag;

private:
    /** Cached owner reference */
    TWeakObjectPtr<AActor> CachedOwner;
};
```

### Step 3: Generate Implementation

```cpp
// USipherANS_{NotifyName}.cpp
#include "AnimNotify/USipherANS_{NotifyName}.h"
#include "Components/SkeletalMeshComponent.h"
#include "AbilitySystemComponent.h"
#include "AbilitySystemBlueprintLibrary.h"

USipherANS_{NotifyName}::USipherANS_{NotifyName}()
{
    // Default values
    GrantedTag = FGameplayTag::RequestGameplayTag(FName("{DefaultTag}"));
}

void USipherANS_{NotifyName}::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
    Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);

    if (!MeshComp)
    {
        return;
    }

    AActor* Owner = MeshComp->GetOwner();
    if (!Owner)
    {
        return;
    }

    CachedOwner = Owner;

    // Grant tag via ASC if configured
    if (GrantedTag.IsValid())
    {
        if (UAbilitySystemComponent* ASC = UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(Owner))
        {
            ASC->AddLooseGameplayTag(GrantedTag);
        }
    }

    // TODO: Custom begin logic
}

void USipherANS_{NotifyName}::NotifyTick(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float FrameDeltaTime, const FAnimNotifyEventReference& EventReference)
{
    Super::NotifyTick(MeshComp, Animation, FrameDeltaTime, EventReference);

    // TODO: Per-frame logic (if needed)
}

void USipherANS_{NotifyName}::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference)
{
    // Remove granted tag
    if (GrantedTag.IsValid() && CachedOwner.IsValid())
    {
        if (UAbilitySystemComponent* ASC = UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(CachedOwner.Get()))
        {
            ASC->RemoveLooseGameplayTag(GrantedTag);
        }
    }

    CachedOwner.Reset();

    Super::NotifyEnd(MeshComp, Animation, EventReference);
}

FString USipherANS_{NotifyName}::GetNotifyName_Implementation() const
{
    return TEXT("{DisplayName}");
}
```

## Common Patterns

### Combat Hitbox Notify

```cpp
// Parameters
UPROPERTY(EditAnywhere, Category = "Combat")
TSubclassOf<USipherHitboxComponent> HitboxClass;

UPROPERTY(EditAnywhere, Category = "Combat")
FName AttachSocket;

// NotifyBegin - Spawn hitbox
// NotifyEnd - Destroy hitbox
```

### Gameplay Cue Notify

```cpp
// Parameters
UPROPERTY(EditAnywhere, Category = "GameplayCue")
FGameplayTag GameplayCueTag;

UPROPERTY(EditAnywhere, Category = "GameplayCue")
FGameplayCueParameters CueParameters;

// NotifyBegin - Execute cue
// NotifyEnd - Remove cue (if looping)
```

### Warp Notify

```cpp
// Parameters
UPROPERTY(EditAnywhere, Category = "Warp")
FName WarpTargetName;

UPROPERTY(EditAnywhere, Category = "Warp")
UCurveFloat* WarpCurve;

// NotifyTick - Update warp progress
```

## Output Structure

```
Source/S2/
├── Public/AnimNotify/
│   └── USipherANS_{NotifyName}.h
└── Private/AnimNotify/
    └── USipherANS_{NotifyName}.cpp
```

## Naming Conventions

| Type | Prefix | Example |
|------|--------|---------|
| Combat | `USipherANS_Combat_` | `USipherANS_Combat_HeavySlash` |
| VFX | `USipherANS_VFX_` | `USipherANS_VFX_TrailStart` |
| Audio | `USipherANS_Audio_` | `USipherANS_Audio_Footstep` |
| State | `USipherANS_State_` | `USipherANS_State_Invulnerable` |
| Warp | `USipherANS_Warp_` | `USipherANS_Warp_ToTarget` |

## Best Practices

1. **Cache owner in NotifyBegin** - Don't look up every tick
2. **Clean up in NotifyEnd** - Remove tags, destroy spawned actors
3. **Handle null checks** - MeshComp and Owner can be null
4. **Use weak pointers** - Avoid preventing garbage collection
5. **Expose parameters** - Let designers tune in montage
6. **Override GetNotifyName** - Better editor display

## Integration Checklist

- [ ] Header in `Public/AnimNotify/`
- [ ] Implementation in `Private/AnimNotify/`
- [ ] Added to build dependencies if using external modules
- [ ] Tested in standalone montage
- [ ] Tested in combo graph context
- [ ] Parameters documented with tooltips
