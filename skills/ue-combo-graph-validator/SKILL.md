---
name: ue-combo-graph-validator
description: Validate SipherComboGraph assets for dead ends, missing transitions, timing issues, and combat flow problems. Use when debugging combo systems, validating attack chains, or reviewing combat graphs. Triggers on "combo graph", "combo validation", "attack chain", "combo system", "combat graph", "combo flow".
---

# UE Combo Graph Validator

Validate SipherComboGraph configurations for combat flow and correctness.

## Quick Start

1. Specify ComboGraph asset
2. Run validation suite
3. Get flow issues and timing problems

## Validation Categories

### 1. Flow Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Entry Node | Error | Must have valid entry |
| Dead Ends | Warning | Actions with no follow-up |
| Orphan Nodes | Error | Unreachable combo actions |
| Loop Detection | Warning | Infinite combo loops |

### 2. Timing Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Input Window | Warning | Window too short/long |
| Recovery Frames | Warning | Recovery allows infinite spam |
| Animation Sync | Error | Window exceeds animation |

### 3. Action Validation

| Check | Severity | Description |
|-------|----------|-------------|
| Montage Exists | Error | Referenced montage valid |
| Ability Exists | Error | Linked ability valid |
| Damage Config | Warning | Damage values reasonable |

## Validation Workflow

### Step 1: Parse Combo Graph

```markdown
## Combo Graph Analysis: CG_{GraphName}

### Overview
| Metric | Value |
|--------|-------|
| Total Nodes | {N} |
| Entry Points | {N} |
| Max Combo Length | {N} |
| Branches | {N} |

### Combo Tree
```
Entry
├── Light_1 [Input: LightAttack]
│   ├── Light_2 [Input: LightAttack]
│   │   ├── Light_3 [Input: LightAttack] → Finisher
│   │   └── Heavy_Combo [Input: HeavyAttack]
│   └── Heavy_1 [Input: HeavyAttack]
└── Heavy_1 [Input: HeavyAttack]
    └── Heavy_2 [Input: HeavyAttack] → Slam
```
```

### Step 2: Analyze Flow

```markdown
### Flow Analysis

#### Entry Points
| Entry | Condition | Status |
|-------|-----------|--------|
| Default | None | OK |
| Aerial | InAir | OK |
| Sprint | IsSprinting | Missing Montage |

#### Dead Ends (No Follow-up)
| Node | Intentional | Issue |
|------|-------------|-------|
| Light_3 | Yes | Finisher (OK) |
| Heavy_Slam | Yes | Ender (OK) |
| Light_2_B | No | Missing transition |

#### Orphan Nodes
| Node | Issue |
|------|-------|
| Special_Attack_Old | No incoming transitions |
```

### Step 3: Timing Analysis

```markdown
### Timing Validation

| Node | Animation | Input Window | Status |
|------|-----------|--------------|--------|
| Light_1 | 0.5s | 0.2-0.4s | OK |
| Light_2 | 0.6s | 0.3-0.5s | OK |
| Heavy_1 | 1.0s | 0.5-0.8s | Warning: Long |
| Heavy_2 | 1.2s | 0.1-0.3s | Error: Too Short |

### Timing Issues

#### [ERROR] Input Window Too Short
- **Node**: Heavy_2
- **Window**: 0.1-0.3s (200ms)
- **Minimum Recommended**: 250ms
- **Fix**: Extend window end frame in ComboGraph

#### [WARNING] Recovery Allows Spam
- **Node**: Light_1
- **Recovery End**: 0.4s
- **Next Input Start**: 0.2s
- **Issue**: Can cancel recovery into self
- **Fix**: Add cooldown or adjust window
```

### Step 4: Action Validation

```markdown
### Action Configuration

| Node | Montage | Ability | Damage | Status |
|------|---------|---------|--------|--------|
| Light_1 | AMT_Light_01 | GA_LightAttack | 25 | OK |
| Light_2 | AMT_Light_02 | GA_LightAttack | 30 | OK |
| Heavy_1 | AMT_Heavy_01 | GA_HeavyAttack | 60 | Warning |
| Special | MISSING | GA_Special | 100 | Error |

### Action Issues

#### [ERROR] Missing Montage
- **Node**: Special
- **Expected**: AMT_{Weapon}_Special
- **Fix**: Create montage or update reference

#### [WARNING] Damage Scaling
- **Node**: Heavy_1
- **Damage**: 60
- **Expected Range**: 40-50 for combo position
- **Fix**: Review damage curve for combo depth
```

## Combo Flow Patterns

### Standard Light Chain

```
Light_1 (0.5s)
├── Window: 0.2-0.4s → Light_2
└── Window: 0.2-0.4s → Heavy_1 (Branch)

Light_2 (0.6s)
├── Window: 0.3-0.5s → Light_3
└── Window: 0.3-0.5s → Heavy_2 (Branch)

Light_3 (0.8s) [Finisher]
└── Recovery: Return to Idle
```

### Branch Points

```
Good Branch Design:
- Clear input differentiation (Light vs Heavy)
- Similar timing windows
- Meaningful gameplay difference

Bad Branch Design:
- Same input, condition-only branch (confusing)
- Vastly different timing (inconsistent feel)
```

## Common Issues

### Infinite Combo Loop

```
Issue: Light_1 → Light_2 → Light_1 (loops forever)
Impact: Balance-breaking, unintended infinite
Fix: Add combo counter limit or energy cost
```

### Unreachable Finisher

```
Issue: Finisher node exists but no path reaches it
Impact: Content never experienced
Fix: Add transition from combo chain
```

### Window Overlap

```
Issue: Two branches have same input and overlapping windows
Impact: Unpredictable combo selection
Fix: Prioritize or separate windows
```

## Performance Considerations

| Metric | Budget | Notes |
|--------|--------|-------|
| Nodes per graph | <50 | Complexity limit |
| Conditions per node | <5 | Evaluation cost |
| Active graphs | 1 per character | Memory |

## Output Report

```markdown
# Combo Graph Validation: CG_{GraphName}

## Summary
- **Status**: {PASS/WARNING/FAIL}
- **Nodes**: {N}
- **Max Depth**: {N}
- **Issues**: {N}

## Flow Issues
1. {Issue}

## Timing Issues
1. {Issue}

## Missing Assets
1. {Asset}

## Combo Flow Diagram
{Visual representation}

## Recommendations
1. {Recommendation}
```
