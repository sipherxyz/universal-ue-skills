---
name: ue-ai-coordinator-debugger
description: Debug AI combat coordinator including ticket allocation, slot management, threat assessment, and group coordination. Use when debugging AI coordination issues, investigating stuck enemies, or analyzing combat ticket flow. Triggers on "combat coordinator", "AI coordinator", "combat ticket", "slot allocation", "threat system", "AI coordination", "group combat".
---

# UE AI Coordinator Debugger

Debug AI combat coordination systems including tickets, slots, and threat management.

## Quick Start

1. Enable coordinator debug logging
2. Describe coordination issue
3. Trace ticket/slot allocation

## Debug Categories

### 1. Combat Tickets

| Issue | Symptoms | Cause |
|-------|----------|-------|
| No Ticket | AI won't attack | Pool exhausted or blocked |
| Stuck Ticket | AI holds but doesn't act | BT not releasing |
| Ticket Starvation | Some AI never attack | Priority imbalance |

### 2. Slot Allocation

| Issue | Symptoms | Cause |
|-------|----------|-------|
| No Slot | AI circles but can't engage | Slots full |
| Wrong Slot | AI in bad position | Slot calculation error |
| Slot Overlap | AI clumping | Slot spacing too small |

### 3. Threat Assessment

| Issue | Symptoms | Cause |
|-------|----------|-------|
| Wrong Target | AI ignores player | Threat calculation bug |
| Target Thrashing | Constant target switch | Tie-breaking issue |
| Stuck Threat | Dead target still threatened | Cleanup failure |

## Debug Workflow

### Step 1: Enable Logging

```cpp
// Console commands
Log LogSipherCombatCoordinator VeryVerbose
Log LogSipherThreatSystem VeryVerbose

// Visual debug
SipherAI.Debug.ShowCombatSlots 1
SipherAI.Debug.ShowTicketHolders 1
SipherAI.Debug.ShowThreatLines 1
```

### Step 2: Capture State

```markdown
## Coordinator State Dump

### Active Tickets
| AI | Ticket Type | Granted At | Duration | Status |
|----|-------------|------------|----------|--------|
| Enemy_01 | MeleeAttack | 0:15.3 | 2.5s | Active |
| Enemy_02 | MeleeAttack | 0:14.1 | 3.0s | Expired |
| Enemy_03 | None | - | - | Waiting |

### Slot Allocation
| Slot | Position | Assigned AI | Distance |
|------|----------|-------------|----------|
| 0 (Front) | (100, 0) | Enemy_01 | 150 |
| 1 (Left) | (0, 100) | Enemy_02 | 200 |
| 2 (Right) | (0, -100) | None | - |
| 3 (Back) | (-100, 0) | None | - |

### Threat Table
| Target | Threat Value | Threatening AIs |
|--------|--------------|-----------------|
| Player | 100 | Enemy_01, Enemy_02, Enemy_03 |
| Companion | 25 | Enemy_04 |
```

### Step 3: Analyze Issues

```markdown
### Issue Analysis

#### Problem: Enemy_03 Won't Attack
**Observation**: Enemy_03 has been waiting for 15 seconds
**Ticket Pool Status**: 2/3 active
**Available**: Yes (1 ticket available)

**Root Cause Analysis**:
1. ✓ Ticket available
2. ✓ Slot available (slot 2, 3 open)
3. ✗ BT condition: `HasCombatTicket` returns false
4. → Blackboard key `CombatTicket` not being set

**Diagnosis**: BT task `RequestCombatTicket` not running
**Fix**: Check BT flow - decorator blocking task execution
```

### Step 4: Trace Ticket Flow

```markdown
### Ticket Request Trace: Enemy_03

| Time | Event | Result |
|------|-------|--------|
| 0:12.0 | RequestTicket called | Pending |
| 0:12.0 | CheckSlotAvailable | Slot 2 assigned |
| 0:12.1 | ValidateRequest | BLOCKED |
| 0:12.1 | Block Reason | Cooldown active (1.5s remaining) |

**Issue**: Request blocked by cooldown from previous failed attack
**Fix**: Clear cooldown on successful dodge/interrupt
```

## Common Issues & Fixes

### 1. Ticket Pool Exhaustion

```markdown
**Symptoms**: All AI waiting, none attacking
**Diagnosis**:
- Check active ticket count vs pool size
- Verify tickets are being released

**Common Causes**:
1. Ticket not released in BT task failure
2. Long attack animations holding tickets
3. Dead AI still holding ticket

**Fix**:
```cpp
void OnAIDeath(AActor* DeadAI)
{
    CombatCoordinator->ReleaseAllTickets(DeadAI);
    CombatCoordinator->ReleaseSlot(DeadAI);
}
```
```

### 2. Slot Calculation Error

```markdown
**Symptoms**: AI standing in walls/overlapping
**Diagnosis**:
- Visualize slot positions
- Check slot spacing configuration

**Common Causes**:
1. Slot radius smaller than AI capsule
2. No nav mesh validation
3. Static slots ignoring environment

**Fix**:
- Increase slot spacing
- Add nav mesh reachability check
- Use dynamic slot calculation
```

### 3. Threat Tie-Breaking

```markdown
**Symptoms**: AI rapidly switching targets
**Diagnosis**:
- Log threat values per frame
- Check for equal threat scenarios

**Common Causes**:
1. Multiple targets with same threat
2. Threat decay causing oscillation
3. Distance calculation jitter

**Fix**:
```cpp
// Add hysteresis
if (NewTarget != CurrentTarget)
{
    float SwitchThreshold = 1.2f; // 20% higher to switch
    if (NewThreat < CurrentThreat * SwitchThreshold)
    {
        return; // Keep current target
    }
}
```
```

### 4. Coordinator Group Issues

```markdown
**Symptoms**: Group attacks not coordinating
**Diagnosis**:
- Check group membership
- Verify group sync calls

**Common Causes**:
1. AI not registered to group
2. Group coordinator inactive
3. Sync signal not propagating

**Fix**:
- Register AI on spawn
- Ensure coordinator ticks
- Verify broadcast reach
```

## Debug Visualization

### Slot Visualization

```
Player
  ·
  |
[2]---·---[3]    Slot Layout (Top-down)
  |   ·   |
  | Enemy |
  |   ·   |
[1]---·---[0]
```

### Ticket Timeline

```
Time: 0:00 ─────────────────────────── 0:30
Enemy_01: ████░░░░░████░░░░░████░░░░░░
Enemy_02: ░░░░████░░░░░████░░░░░████░░
Enemy_03: ░░░░░░░░████░░░░░░░░████░░░░
          [Attack windows shown]
```

## Output Report

```markdown
# Combat Coordinator Debug Report

## Situation
- **AI Count**: {N}
- **Active Tickets**: {N}/{Max}
- **Occupied Slots**: {N}/{Max}
- **Player Threat**: {N}

## Issues Identified
1. {Issue with root cause}

## Ticket Flow
{Timeline or trace}

## Recommendations
1. {Fix with code/config change}

## Logs
{Relevant log excerpts}
```
