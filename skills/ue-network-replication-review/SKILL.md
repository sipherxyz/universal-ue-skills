---
name: ue-network-replication-review
description: Review network replication code for correctness including DOREPLIFETIME, RPCs, relevancy, and bandwidth optimization. Use when implementing multiplayer features, debugging replication issues, or auditing network code. Note - Lower priority for offline games. Triggers on "replication", "multiplayer", "RPC", "network", "DOREPLIFETIME", "net relevancy", "bandwidth".
---

# UE Network Replication Review

Review network replication implementation for correctness and efficiency.

**Note**: Lower priority for offline games like Huli, but useful if multiplayer/co-op is added later.

## Quick Start

1. Specify class or system to review
2. Analyze replication setup
3. Get correctness and bandwidth feedback

## Review Categories

### 1. Property Replication

| Check | Severity | Description |
|-------|----------|-------------|
| UPROPERTY Replicated | Error | Properties marked but not registered |
| DOREPLIFETIME | Error | Missing GetLifetimeReplicatedProps |
| Rep Condition | Warning | Inappropriate condition selected |
| Rep Notify | Info | OnRep callback correctness |

### 2. RPC Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Server/Client | Error | Wrong execution context |
| Validation | Error | Missing input validation |
| Reliability | Warning | Unreliable for critical data |
| Bandwidth | Warning | Large/frequent RPCs |

### 3. Relevancy

| Check | Severity | Description |
|-------|----------|-------------|
| Net Relevancy | Warning | Relevancy not considered |
| Cull Distance | Info | May need adjustment |
| Dormancy | Info | Not using dormancy optimization |

## Review Workflow

### Step 1: Analyze Replicated Properties

```markdown
## Property Replication Analysis: {ClassName}

### Replicated Properties
| Property | Type | Condition | Notify | Status |
|----------|------|-----------|--------|--------|
| Health | float | None | OnRep_Health | OK |
| bIsDead | bool | None | OnRep_IsDead | OK |
| Inventory | TArray | OwnerOnly | None | Warning |
| TargetLocation | FVector | None | None | Error |

### Issues Found

#### [ERROR] Missing DOREPLIFETIME
```cpp
// Property declaration
UPROPERTY(Replicated)
FVector TargetLocation;

// NOT registered in GetLifetimeReplicatedProps()
// FIX: Add to GetLifetimeReplicatedProps:
DOREPLIFETIME(AMyClass, TargetLocation);
```

#### [WARNING] Large Array Replication
- **Property**: Inventory
- **Type**: TArray<FInventoryItem>
- **Issue**: Full array replicated on any change
- **Fix**: Consider using Fast TArray Replication
```

### Step 2: Analyze RPCs

```markdown
## RPC Analysis: {ClassName}

### RPC Definitions
| Function | Type | Reliable | Validated | Status |
|----------|------|----------|-----------|--------|
| ServerAttack | Server | Yes | Yes | OK |
| ClientUpdateUI | Client | No | N/A | OK |
| ServerMoveRequest | Server | No | No | Error |
| MulticastDamage | NetMulticast | Yes | N/A | Warning |

### Issues Found

#### [ERROR] Missing Server Validation
```cpp
// Current
UFUNCTION(Server, Reliable)
void ServerMoveRequest(FVector TargetLocation);

// Problematic - No validation
void AMyCharacter::ServerMoveRequest_Implementation(FVector TargetLocation)
{
    SetActorLocation(TargetLocation);  // Trust client!
}

// FIX: Add validation
UFUNCTION(Server, Reliable, WithValidation)
void ServerMoveRequest(FVector TargetLocation);

bool AMyCharacter::ServerMoveRequest_Validate(FVector TargetLocation)
{
    // Validate move is reasonable
    float Distance = FVector::Dist(GetActorLocation(), TargetLocation);
    return Distance < MaxMoveDistance;
}
```

#### [WARNING] Multicast Reliable
- **Function**: MulticastDamage
- **Issue**: Reliable multicast is expensive
- **Fix**: Use unreliable if visuals can be missed
```

### Step 3: Analyze Network Efficiency

```markdown
## Bandwidth Analysis

### Property Bandwidth
| Property | Size | Frequency | Est. Bandwidth |
|----------|------|-----------|----------------|
| Health | 4 bytes | On change | Low |
| Location | 12 bytes | Tick | High |
| Rotation | 12 bytes | Tick | High |
| Inventory | Variable | On change | Medium |

### Optimization Opportunities

#### [INFO] Consider Quantization
```cpp
// Current: Full precision
UPROPERTY(Replicated)
FVector Location;

// Optimized: Quantized
UPROPERTY(Replicated)
FVector_NetQuantize Location;  // Rounds to 1/10 unit
```

#### [INFO] Consider Dormancy
```cpp
// Enable dormancy for static actors
void AMyActor::BeginPlay()
{
    SetNetDormancy(DORM_DormantAll);
}

// Wake up when needed
void AMyActor::OnInteraction()
{
    SetNetDormancy(DORM_Awake);
    // Do replicated action
    SetNetDormancy(DORM_DormantAll);
}
```
```

## Common Patterns

### Correct Property Replication

```cpp
// Header
UPROPERTY(ReplicatedUsing = OnRep_Health)
float Health;

UFUNCTION()
void OnRep_Health();

// Implementation
void AMyCharacter::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);

    DOREPLIFETIME(AMyCharacter, Health);
    // Or with condition
    DOREPLIFETIME_CONDITION(AMyCharacter, Health, COND_OwnerOnly);
}

void AMyCharacter::OnRep_Health()
{
    // Update UI, play effects, etc.
    UpdateHealthUI();
}
```

### Correct Server RPC

```cpp
// Header
UFUNCTION(Server, Reliable, WithValidation)
void ServerUseAbility(int32 AbilityIndex);

// Implementation
bool AMyCharacter::ServerUseAbility_Validate(int32 AbilityIndex)
{
    // Validate input
    return AbilityIndex >= 0 && AbilityIndex < Abilities.Num();
}

void AMyCharacter::ServerUseAbility_Implementation(int32 AbilityIndex)
{
    // Execute on server
    if (CanUseAbility(AbilityIndex))
    {
        ExecuteAbility(AbilityIndex);
    }
}
```

### Fast TArray Replication

```cpp
// For large arrays that change frequently
USTRUCT()
struct FInventoryArray : public FFastArraySerializer
{
    GENERATED_BODY()

    UPROPERTY()
    TArray<FInventoryItem> Items;

    bool NetDeltaSerialize(FNetDeltaSerializeInfo& DeltaParms)
    {
        return FFastArraySerializer::FastArrayDeltaSerialize<FInventoryItem>(Items, DeltaParms, *this);
    }
};
```

## Replication Conditions

| Condition | Use Case |
|-----------|----------|
| COND_None | Always replicate (default) |
| COND_InitialOnly | Only on spawn |
| COND_OwnerOnly | Only to owning client |
| COND_SkipOwner | Everyone except owner |
| COND_SimulatedOnly | Simulated proxies only |
| COND_AutonomousOnly | Autonomous proxy only |
| COND_SimulatedOrPhysics | Simulated or physics |
| COND_InitialOrOwner | Initial or owner |
| COND_Custom | Custom condition callback |

## Report Template

```markdown
# Network Replication Review: {ClassName}

## Summary
- **Replicated Properties**: {N}
- **RPCs**: {N}
- **Issues**: {N} errors, {N} warnings

## Property Replication
{Table of properties with status}

## RPC Analysis
{Table of RPCs with status}

## Bandwidth Estimate
- **Per-frame**: ~{N} bytes/actor
- **Peak**: ~{N} bytes/actor

## Issues

### Errors (Must Fix)
1. {Error}

### Warnings (Should Fix)
1. {Warning}

## Recommendations
1. {Recommendation}

## Checklist
- [ ] All replicated props registered in DOREPLIFETIME
- [ ] Server RPCs have validation
- [ ] No reliable multicast for non-critical data
- [ ] Large arrays use Fast TArray
- [ ] Appropriate rep conditions used
```

## Console Commands

| Command | Purpose |
|---------|---------|
| `net.ListActorChannels` | List replicated actors |
| `net.TrackReplicationGraph` | Track replication |
| `stat Net` | Network statistics |
| `net.DormancyDraw` | Visualize dormancy |
