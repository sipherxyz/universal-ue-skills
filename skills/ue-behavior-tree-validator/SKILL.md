---
name: ue-behavior-tree-validator
description: Validate Behavior Tree assets for common issues including infinite loops, missing decorators, orphan branches, and performance problems. Use when reviewing AI behavior, debugging BT issues, or validating enemy AI. Triggers on "behavior tree", "BT validation", "AI validation", "behavior tree review", "BT issues", "AI debugging".
---

# UE Behavior Tree Validator

Lint and validate Behavior Tree assets for correctness, performance, and best practices.

## Quick Start

1. Provide BT asset path or enemy class name
2. Run validation checks
3. Get categorized issues with fixes

## Validation Categories

### 1. Structural Issues (Critical)

| Issue | Detection | Impact |
|-------|-----------|--------|
| Infinite Loop | Sequence with no failure condition | Game freeze |
| Orphan Branch | Subtree never executed | Dead code |
| Missing Root | No valid root node | BT won't run |
| Circular Reference | BT references itself | Stack overflow |

### 2. Logic Issues (High)

| Issue | Detection | Impact |
|-------|-----------|--------|
| Unreachable Node | Decorator always fails | Logic never executes |
| Race Condition | Parallel with shared blackboard keys | Unpredictable behavior |
| Missing Abort | No AbortSelf/AbortBoth on time-sensitive decorators | Stuck AI |
| Duplicate Conditions | Same check in sequence | Redundant processing |

### 3. Performance Issues (Medium)

| Issue | Detection | Impact |
|-------|-----------|--------|
| Expensive Service | Service tick interval < 0.1s | CPU overhead |
| Heavy Task in Parallel | Complex task under Parallel node | Thread contention |
| No Cooldown | Action can spam without delay | Performance spike |
| Missing Blackboard Cache | GetActorOfClass in Task | O(n) every tick |

### 4. Best Practice Issues (Low)

| Issue | Detection | Impact |
|-------|-----------|--------|
| Missing Comments | Complex branch without description | Maintainability |
| Hardcoded Values | Magic numbers in decorators | Tuning difficulty |
| Inconsistent Naming | Task names don't match function | Confusion |

## Validation Workflow

### Step 1: Parse BT Structure

Extract from `.uasset`:
- Node hierarchy
- Decorator configurations
- Service tick rates
- Blackboard key usage
- Task class references

### Step 2: Run Validation Rules

```markdown
## Behavior Tree Validation: {BTName}

### Summary
- **Status**: {PASS/WARNING/FAIL}
- **Critical Issues**: {N}
- **Warnings**: {N}
- **Suggestions**: {N}

### Node Statistics
| Type | Count |
|------|-------|
| Selectors | {N} |
| Sequences | {N} |
| Parallels | {N} |
| Tasks | {N} |
| Decorators | {N} |
| Services | {N} |

### Blackboard Usage
| Key | Type | Read By | Written By |
|-----|------|---------|------------|
| {Key} | {Type} | {Nodes} | {Nodes} |
```

### Step 3: Issue Report

```markdown
### Critical Issues

#### 1. Infinite Loop Detected
**Location**: Sequence_Combat → Attack_Loop
**Problem**: Sequence has no failure path - all children always succeed
**Fix**: Add decorator with failure condition or timeout

**Current Structure**:
```
Sequence_Combat
├── BTTask_FaceTarget (Always Succeed)
├── BTTask_Attack (Always Succeed)
└── BTDecorator_Loop (Infinite)
```

**Recommended Fix**:
```
Sequence_Combat
├── BTDecorator_Blackboard (TargetActor IsSet)
├── BTTask_FaceTarget
├── BTTask_Attack
└── BTDecorator_Cooldown (0.5s)
```

---

#### 2. Orphan Branch
**Location**: Selector_Root → Sequence_Unused
**Problem**: Branch has decorator that always evaluates false
**Fix**: Remove branch or fix decorator condition
```

## Common Sipher BT Patterns

### Valid Combat Loop

```
Selector_Root
├── Sequence_Combat [BTDecorator_HasCombatTicket]
│   ├── BTService_UpdateTarget (0.2s)
│   ├── BTTask_SipherMoveTo (Target)
│   ├── BTTask_SipherAttack
│   └── BTDecorator_Cooldown (AttackCooldown)
├── Sequence_Patrol [BTDecorator_Not HasTarget]
│   ├── BTTask_SipherMoveToPatrol
│   └── BTDecorator_Wait (PatrolWait)
└── BTTask_Idle [Fallback]
```

### Valid Decorator Stack

```
Sequence
├── BTDecorator_Blackboard (TargetActor IsSet) [AbortBoth]
├── BTDecorator_IsInRange (AttackRange) [AbortSelf]
├── BTDecorator_Cooldown (0.5s)
└── BTTask_Attack
```

## Abort Mode Guidelines

| Scenario | Abort Mode | Reason |
|----------|------------|--------|
| Target validation | AbortBoth | Re-evaluate if target changes |
| Range check | AbortSelf | Exit if out of range |
| Cooldown | None | Timer-based, not condition |
| Health threshold | AbortBoth | Immediate reaction to damage |

## Service Tick Guidelines

| Service Type | Recommended Interval | Reason |
|--------------|---------------------|--------|
| Target selection | 0.2-0.5s | Balance responsiveness/cost |
| Threat update | 0.3-0.5s | Threat changes gradually |
| Path validity | 0.5-1.0s | Path rarely invalidates |
| Blackboard cleanup | 1.0s+ | Housekeeping only |

## Blackboard Key Validation

Check for:
1. **Uninitialized reads**: Key read before any write
2. **Type mismatches**: Task expects different type than key
3. **Stale data**: Key not updated but used for decisions
4. **Orphan keys**: Keys defined but never used

## Report Output

```markdown
# BT Validation Report: BT_{EnemyName}

## Executive Summary
- **Overall Status**: {PASS/FAIL}
- **Estimated Tick Cost**: {N}ms per AI
- **Scalability**: {Good for 50+ AI / Needs optimization}

## Issues by Priority

### P0 - Critical (Must Fix)
1. {Issue}

### P1 - High (Should Fix)
1. {Issue}

### P2 - Medium (Consider Fixing)
1. {Issue}

## Optimization Opportunities
1. {Opportunity with expected improvement}

## Sipher Standards Compliance
- [ ] Uses SipherBTTask_ base classes
- [ ] Combat ticket system integrated
- [ ] Coordinator group support
- [ ] Threat action validation
```
