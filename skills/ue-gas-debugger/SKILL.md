---
name: ue-gas-debugger
description: Debug GAS (Gameplay Ability System) issues including ability activation failures, tag queries, attribute modifications, and effect application. Use when troubleshooting ability bugs, investigating GAS state, or tracing gameplay effect flow. Triggers on "GAS debug", "ability not activating", "gameplay tag issue", "attribute problem", "effect not applying", "ability system debug".
---

# UE GAS Debugger

Debug Gameplay Ability System issues with systematic analysis and tracing.

## Quick Start

1. Describe the GAS issue (ability not activating, effect not applying, etc.)
2. Enable debug logging
3. Analyze system state and trace execution

## Common Issues & Diagnosis

### 1. Ability Won't Activate

**Checklist:**

```markdown
## Activation Failure Diagnosis

### 1. Ability Granted?
Check: `AbilitySystemComponent->GetActivatableAbilities()`
- [ ] Ability class is in the list
- [ ] Ability spec handle is valid

### 2. Can Activate?
Check: `Ability->CanActivateAbility()`
- [ ] Cooldown not active (check cooldown tag)
- [ ] Cost can be paid (check resource attributes)
- [ ] No blocking tags present
- [ ] Required tags present

### 3. Tag Analysis
```cpp
// Current tags on ASC
FGameplayTagContainer OwnedTags;
ASC->GetOwnedGameplayTags(OwnedTags);

// Ability's blocking tags
FGameplayTagContainer BlockingTags = Ability->ActivationBlockedTags;

// Check intersection
if (OwnedTags.HasAny(BlockingTags)) {
    // Blocked by tags
}
```

### 4. Input Binding
- [ ] Input action mapped correctly
- [ ] Ability input ID matches
- [ ] Input not consumed by UI
```

**Debug Commands:**

```
# Enable GAS logging
Log LogAbilitySystem VeryVerbose
Log LogGameplayEffects VeryVerbose

# Show ability debug
ShowDebug AbilitySystem
AbilitySystem.Debug.NextCategory
AbilitySystem.Debug.NextTarget
```

### 2. Gameplay Effect Not Applying

**Checklist:**

```markdown
## Effect Application Failure

### 1. Application Attempt
```cpp
// Verify ApplyGameplayEffect is called
FGameplayEffectSpecHandle SpecHandle = ASC->MakeOutgoingSpec(EffectClass, Level, Context);
if (SpecHandle.IsValid()) {
    FActiveGameplayEffectHandle ActiveHandle = ASC->ApplyGameplayEffectSpecToSelf(*SpecHandle.Data.Get());
    // Check ActiveHandle validity
}
```

### 2. Application Requirements
```cpp
// Check ApplicationTagRequirements
FGameplayTagContainer TargetTags;
Target->GetOwnedGameplayTags(TargetTags);

// RequireTags - target must have ALL
// IgnoreTags - target must have NONE
```

### 3. Immunity Check
```cpp
// Check for immunity tags
if (ASC->HasMatchingGameplayTag(ImmunityTag)) {
    // Effect blocked by immunity
}
```

### 4. Stacking Rules
- [ ] Stack limit reached?
- [ ] Existing effect with higher priority?
- [ ] Overflow policy configured?
```

### 3. Attribute Not Changing

**Checklist:**

```markdown
## Attribute Modification Failure

### 1. Attribute Exists
```cpp
// Verify attribute is replicated/valid
if (AttributeSet->GetHealthAttribute().IsValid()) {
    float CurrentValue = AttributeSet->GetHealth();
}
```

### 2. Modifier Applied
```cpp
// Check active modifiers
TArray<FActiveGameplayEffectHandle> ActiveEffects;
ASC->GetActiveEffectsWithAllTags(EffectTags, ActiveEffects);

for (auto& Handle : ActiveEffects) {
    // Inspect modifiers
    const FActiveGameplayEffect* AGE = ASC->GetActiveGameplayEffect(Handle);
}
```

### 3. Clamping
```cpp
// Check PreAttributeChange / PostGameplayEffectExecute
// Values may be clamped to valid range
void UMyAttributeSet::PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue)
{
    if (Attribute == GetHealthAttribute()) {
        NewValue = FMath::Clamp(NewValue, 0.f, GetMaxHealth());
    }
}
```

### 4. Replication
- [ ] Authority has correct value?
- [ ] Attribute marked for replication?
- [ ] Net relevancy correct?
```

### 4. Tag Mismatch Issues

**Diagnosis:**

```cpp
// Dump all tags on an actor
void DebugDumpTags(UAbilitySystemComponent* ASC)
{
    FGameplayTagContainer AllTags;
    ASC->GetOwnedGameplayTags(AllTags);

    for (const FGameplayTag& Tag : AllTags) {
        UE_LOG(LogTemp, Log, TEXT("Tag: %s"), *Tag.ToString());
    }
}

// Check specific tag query
FGameplayTagQuery Query = FGameplayTagQuery::MakeQuery_MatchAllTags(RequiredTags);
bool bMatches = Query.Matches(OwnedTags);
```

## Debug Logging Setup

### Enable Verbose Logging

```cpp
// In DefaultEngine.ini or runtime
[Core.Log]
LogAbilitySystem=VeryVerbose
LogGameplayEffects=VeryVerbose
LogGameplayTags=Verbose
```

### Custom Debug Logging

```cpp
// Add to USipherAbilitySystemComponent
void USipherAbilitySystemComponent::DebugLogAbilityActivation(const UGameplayAbility* Ability, bool bSuccess)
{
#if !UE_BUILD_SHIPPING
    if (bSuccess) {
        UE_LOG(LogSipherGAS, Log, TEXT("[%s] Ability ACTIVATED: %s"),
            *GetOwner()->GetName(), *Ability->GetName());
    } else {
        FGameplayTagContainer BlockingTags;
        // ... gather blocking info
        UE_LOG(LogSipherGAS, Warning, TEXT("[%s] Ability BLOCKED: %s - Tags: %s"),
            *GetOwner()->GetName(), *Ability->GetName(), *BlockingTags.ToString());
    }
#endif
}
```

## Visual Debugging

### ShowDebug AbilitySystem

Displays:
- Active abilities
- Active gameplay effects
- Owned gameplay tags
- Attribute values

Navigate with:
- `AbilitySystem.Debug.NextCategory` - Cycle categories
- `AbilitySystem.Debug.NextTarget` - Cycle targets

### Gameplay Debugger

```
// Enable in editor
' (apostrophe) key → GAS category

// Shows:
- Ability status
- Effect timers
- Tag state
- Attribute bars
```

## Trace Templates

### Ability Activation Trace

```markdown
## Ability Activation Trace: {AbilityName}

### Request
- Timestamp: {Time}
- Source: {Actor}
- Trigger: {Input/Event/Passive}

### Pre-Activation State
- Cooldown Active: {Yes/No} ({Remaining}s)
- Cost Available: {Yes/No} ({Current}/{Required})
- Blocking Tags: {TagList}
- Required Tags: {TagList}

### Result
- Activated: {Yes/No}
- Failure Reason: {Reason}

### Post-Activation State
- Tags Granted: {TagList}
- Effects Applied: {EffectList}
```

### Effect Application Trace

```markdown
## Effect Application Trace: {EffectName}

### Request
- Timestamp: {Time}
- Source: {Actor}
- Target: {Actor}
- Level: {N}

### Pre-Application State
- Target Tags: {TagList}
- Existing Stacks: {N}
- Immunity Tags: {TagList}

### Modifiers Calculated
| Attribute | Operation | Base | Final |
|-----------|-----------|------|-------|
| {Attr} | {Op} | {N} | {N} |

### Result
- Applied: {Yes/No}
- Handle: {Handle}
- Failure Reason: {Reason}
```

## Common Fixes

### Fix: Ability Blocked by Dead State

```cpp
// Remove blocking tags on respawn
void ASipherCharacter::Respawn()
{
    AbilitySystemComponent->RemoveLooseGameplayTag(FGameplayTag::RequestGameplayTag("State.Dead"));
    AbilitySystemComponent->RemoveActiveEffectsWithGrantedTags(DeathEffectTags);
}
```

### Fix: Effect Not Stacking

```cpp
// Ensure stacking is configured
StackingType = EGameplayEffectStackingType::AggregateBySource;
StackLimitCount = 5;  // Must be > 1 for stacking
```

### Fix: Attribute Clamped to Zero

```cpp
// Check for missing max attribute initialization
void UMyAttributeSet::InitFromMetaDataTable(const UDataTable* DataTable)
{
    // Initialize max values BEFORE current values
    MaxHealth = InitialMaxHealth;
    Health = MaxHealth;  // Now clamping works correctly
}
```

## Huli/S2 Specifics

Check these common issues:
1. **Combat Ticket**: Ability requires combat ticket but AI doesn't have one
2. **Parry State**: Parry tags blocking ability activation
3. **Hit Reaction**: Character in hit stun, blocking input abilities
4. **Combo Phase**: Combo graph state conflicting with ability tags
5. **Queue System**: `FSipherAbilitySpecQueueItem` data not passed correctly
