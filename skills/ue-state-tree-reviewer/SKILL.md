---
name: ue-state-tree-reviewer
description: Review State Tree assets for transition logic, unreachable states, condition validation, and performance issues. Use when debugging AI state trees, validating state machine logic, or optimizing state transitions. Triggers on "state tree", "state tree review", "state machine", "AI state", "transition logic", "state validation".
---

# UE State Tree Reviewer

Review and validate State Tree configurations for correctness and performance.

## Quick Start

1. Specify State Tree asset
2. Run validation analysis
3. Get issues and optimization suggestions

## Validation Categories

### 1. Structural Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Entry State | Error | Must have valid entry |
| Reachability | Error | All states must be reachable |
| Dead Ends | Warning | States with no outgoing transitions |
| Cycles | Warning | Detect infinite loops |

### 2. Transition Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Condition Logic | Error | Conditions must be valid |
| Priority Conflicts | Warning | Overlapping conditions |
| Missing Fallback | Warning | No default transition |
| Transition Cost | Info | Performance of conditions |

### 3. Task Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Task Exists | Error | Task class must exist |
| Task Config | Warning | Required parameters set |
| Task Performance | Info | Tick-heavy tasks flagged |

## Review Workflow

### Step 1: Parse State Tree

```markdown
## State Tree Analysis: ST_{TreeName}

### Overview
| Metric | Value |
|--------|-------|
| States | {N} |
| Transitions | {N} |
| Tasks | {N} |
| Max Depth | {N} |
| Estimated Complexity | {Low/Medium/High} |

### State Hierarchy
```
Root
├── State_Idle
│   ├── State_Idle_Standing
│   └── State_Idle_Looking
├── State_Combat
│   ├── State_Combat_Approach
│   ├── State_Combat_Attack
│   └── State_Combat_Retreat
└── State_Dead
```
```

### Step 2: Analyze Transitions

```markdown
### Transition Map

| From | To | Condition | Priority |
|------|-----|-----------|----------|
| Idle | Combat | HasTarget | 1 |
| Combat | Idle | !HasTarget | 1 |
| * | Dead | Health <= 0 | 0 (Highest) |

### Transition Issues

#### [ERROR] Unreachable State
- **State**: State_Combat_Flank
- **Issue**: No incoming transitions
- **Fix**: Add transition from State_Combat_Approach

#### [WARNING] Conflicting Priorities
- **States**: State_Combat_Attack, State_Combat_Retreat
- **Conditions**: Both can be true simultaneously
- **Current Priority**: Same (1)
- **Fix**: Assign explicit priorities
```

### Step 3: Validate Tasks

```markdown
### Task Analysis

| State | Task | Type | Status |
|-------|------|------|--------|
| State_Idle | UST_LookAround | Simple | OK |
| State_Combat_Attack | UST_ExecuteAttack | Complex | Warning |

### Task Issues

#### [WARNING] Heavy Task
- **State**: State_Combat_Attack
- **Task**: UST_ExecuteAttack
- **Tick Frequency**: Every frame
- **Recommendation**: Consider interval-based execution
```

### Step 4: Reachability Analysis

```markdown
### Reachability Matrix

| State | Reachable From Entry | Can Exit |
|-------|---------------------|----------|
| State_Idle | Yes | Yes |
| State_Combat | Yes | Yes |
| State_Patrol | No | N/A |
| State_Dead | Yes | No (Terminal) |

### Unreachable States
1. **State_Patrol** - No path from entry state
```

## Common Issues & Fixes

### Missing Entry Transition

```
Issue: State has no way to be entered
Impact: State logic never executes
Fix: Add transition from parent or sibling state
```

### Infinite Loop

```
Issue: State A → State B → State A with always-true conditions
Impact: CPU spin, potential freeze
Fix: Add exit condition or cooldown
```

### Condition Never True

```
Issue: Transition condition references invalid data
Impact: Dead transition, state stuck
Fix: Verify condition variable bindings
```

## State Tree Patterns

### Combat State Pattern

```
State_Combat (Selector)
├── State_Combat_Attack [Priority 1]
│   └── Condition: InAttackRange && HasCombatTicket
├── State_Combat_Approach [Priority 2]
│   └── Condition: !InAttackRange
└── State_Combat_Idle [Priority 3]
    └── Condition: Default (always)
```

### Patrol State Pattern

```
State_Patrol (Sequence)
├── State_Patrol_MoveTo
│   └── Task: MoveToPatrolPoint
├── State_Patrol_Wait
│   └── Task: WaitAtPoint
└── Transition: Loop to MoveTo
```

## Performance Guidelines

| Pattern | Good | Warning | Critical |
|---------|------|---------|----------|
| States per tree | <20 | 20-50 | >50 |
| Transition conditions | <5 per state | 5-10 | >10 |
| Nested depth | <4 | 4-6 | >6 |
| Tasks per state | 1-2 | 3-5 | >5 |

## Output Report

```markdown
# State Tree Review: ST_{TreeName}

## Summary
- **Status**: {PASS/WARNING/FAIL}
- **States**: {N}
- **Issues**: {N} errors, {N} warnings

## Critical Issues
1. {Issue}

## Warnings
1. {Warning}

## Optimization Suggestions
1. {Suggestion}

## Diagram
{Mermaid or text diagram of state flow}
```
