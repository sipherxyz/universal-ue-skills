---
name: ue-crash-callstack-linker
description: Map crash callstacks to source code lines, identify likely causes, and suggest fixes based on crash patterns. Use when investigating crashes, analyzing minidumps, or debugging fatal errors. Triggers on "crash analysis", "callstack", "minidump", "crash report", "fatal error", "access violation", "stack trace".
---

# UE Crash Callstack Linker

Map crash callstacks to source code and identify likely causes.

## Quick Start

1. Paste callstack or provide minidump path
2. Analyze crash pattern
3. Get source mapping and fix suggestions

## Analysis Workflow

### Step 1: Parse Callstack

```markdown
## Callstack Analysis

### Raw Callstack
```
Access violation - code c0000005 (first/second chance not available)

UE4Editor_S2!USipherAbilitySystemComponent::ApplyGameplayEffectSpecToSelf() [D:\Build\S2\Source\S2\Private\Core\ASC\SipherAbilitySystemComponent.cpp:342]
UE4Editor_Engine!UAbilitySystemComponent::ApplyGameplayEffectToSelf()
UE4Editor_GameplayAbilities!UGameplayAbility::ApplyGameplayEffectToOwner()
UE4Editor_S2!USipherGameplayAbility::CommitAbility() [D:\Build\S2\Source\S2\Private\GameplayAbilities\SipherGameplayAbility.cpp:128]
```

### Parsed Frames
| # | Module | Function | File | Line |
|---|--------|----------|------|------|
| 0 | S2 | USipherAbilitySystemComponent::ApplyGameplayEffectSpecToSelf | SipherAbilitySystemComponent.cpp | 342 |
| 1 | Engine | UAbilitySystemComponent::ApplyGameplayEffectToSelf | (engine) | - |
| 2 | GameplayAbilities | UGameplayAbility::ApplyGameplayEffectToOwner | (engine) | - |
| 3 | S2 | USipherGameplayAbility::CommitAbility | SipherGameplayAbility.cpp | 128 |
```

### Step 2: Source Mapping

```markdown
### Source Code Analysis

#### Frame 0: SipherAbilitySystemComponent.cpp:342
```cpp
// Line 340-345
FActiveGameplayEffectHandle USipherAbilitySystemComponent::ApplyGameplayEffectSpecToSelf(
    const FGameplayEffectSpec& Spec,
    FPredictionKey PredictionKey)
{
    // Line 342 - CRASH HERE
    AActor* Avatar = GetAvatarActor();  // Potential null
    return Super::ApplyGameplayEffectSpecToSelf(Spec, PredictionKey);
}
```

#### Frame 3: SipherGameplayAbility.cpp:128
```cpp
// Line 126-130
bool USipherGameplayAbility::CommitAbility(...)
{
    // Line 128 - Caller
    ApplyGameplayEffectToOwner(Handle, ActorInfo, ActivationInfo, CostEffect, ...);
}
```
```

### Step 3: Pattern Analysis

```markdown
### Crash Pattern Analysis

#### Error Type: Access Violation (0xC0000005)
- **Category**: Null pointer dereference
- **Likelihood**: 95% null pointer, 5% invalid memory

#### Common Causes for This Pattern
1. **ASC owner destroyed** during ability execution
2. **Avatar actor null** after death/respawn
3. **Effect spec** contains invalid references
4. **Prediction key** mismatch on client

#### Code Analysis
```cpp
// Line 342: GetAvatarActor() could return null if:
// - Owner was destroyed
// - Component not fully initialized
// - Called during GC
```
```

### Step 4: Fix Recommendations

```markdown
### Recommended Fixes

#### Primary Fix: Add Null Check
```cpp
FActiveGameplayEffectHandle USipherAbilitySystemComponent::ApplyGameplayEffectSpecToSelf(
    const FGameplayEffectSpec& Spec,
    FPredictionKey PredictionKey)
{
    AActor* Avatar = GetAvatarActor();
    if (!Avatar)
    {
        UE_LOG(LogSipherGAS, Warning, TEXT("ApplyGameplayEffectSpecToSelf: Avatar is null"));
        return FActiveGameplayEffectHandle();
    }
    return Super::ApplyGameplayEffectSpecToSelf(Spec, PredictionKey);
}
```

#### Secondary Fix: Check Caller
```cpp
// In CommitAbility, verify ability can still execute
if (!IsActive() || !CurrentActorInfo || !CurrentActorInfo->AvatarActor.IsValid())
{
    return false;
}
```

#### Defensive Fix: Add Ensure
```cpp
if (!ensureMsgf(Avatar, TEXT("Avatar null during effect application")))
{
    return FActiveGameplayEffectHandle();
}
```
```

## Common Crash Patterns

### 1. Null Pointer (0xC0000005)

```markdown
**Symptoms**: Access violation at 0x000000000000XXXX
**Common Causes**:
- Uninitialized pointer
- Destroyed UObject accessed
- Array out of bounds (extreme)

**Investigation**:
1. Check if crashing on member access
2. Verify object validity
3. Check lifecycle (BeginPlay/EndPlay order)
```

### 2. Pure Virtual Call

```markdown
**Symptoms**: "Pure virtual function being called"
**Common Causes**:
- Virtual call in constructor/destructor
- Destroyed object's virtual called
- Corrupted vtable

**Investigation**:
1. Check constructor/destructor for virtual calls
2. Verify object lifecycle
3. Check for dangling pointers
```

### 3. Stack Overflow

```markdown
**Symptoms**: Stack overflow, deep recursion
**Common Causes**:
- Infinite recursion
- Excessive stack allocation
- Circular function calls

**Investigation**:
1. Look for repeated frames in callstack
2. Check recursion termination conditions
3. Move large arrays to heap
```

### 4. Assertion Failed

```markdown
**Symptoms**: "Assertion failed" with condition
**Common Causes**:
- Precondition violation
- Invalid state
- Programmer error caught by check()

**Investigation**:
1. Read assertion condition
2. Find why condition was false
3. Fix upstream cause
```

## Crash Categories

| Category | Error Code | Common Cause |
|----------|------------|--------------|
| Access Violation | 0xC0000005 | Null pointer, invalid memory |
| Stack Overflow | 0xC00000FD | Infinite recursion |
| Illegal Instruction | 0xC000001D | Corrupted code |
| Integer Overflow | 0xC0000095 | Arithmetic error |
| Heap Corruption | 0xC0000374 | Memory overwrite |

## Report Template

```markdown
# Crash Analysis Report

## Crash Summary
- **Error**: {Error type}
- **Module**: {Module name}
- **Function**: {Function name}
- **File**: {File:Line}

## Callstack
{Formatted callstack with source mapping}

## Pattern Analysis
- **Crash Type**: {Type}
- **Likely Cause**: {Cause}
- **Confidence**: {High/Medium/Low}

## Source Context
{Relevant code snippet}

## Recommendations

### Immediate Fix
{Code fix}

### Defensive Improvements
{Additional hardening}

### Prevention
{Process/review suggestions}

## Similar Crashes
{Links to related crash reports if any}
```

## Integration

### Crash Reporter Setup

```cpp
// Add context to crash reports
FGenericCrashContext::SetGameData(TEXT("LastAbility"), *GetNameSafe(CurrentAbility));
FGenericCrashContext::SetGameData(TEXT("GameState"), *GetGameStateString());
```

### Automated Analysis

```bash
# Script to fetch and analyze crashes
./analyze-crash.py --minidump crash.dmp --symbols ./Symbols --source ./Source
```
