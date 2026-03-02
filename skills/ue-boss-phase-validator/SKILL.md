---
name: ue-boss-phase-validator
description: Validate boss phase configurations including health thresholds, ability unlocks, transition triggers, and phase-specific behavior trees. Use when implementing bosses, debugging phase transitions, or reviewing boss encounters. Triggers on "boss phase", "boss validation", "phase transition", "boss encounter", "boss fight", "phase trigger".
---

# UE Boss Phase Validator

Validate boss phase configurations for correct transitions and balanced gameplay.

## Quick Start

1. Specify boss class/blueprint
2. Run phase validation
3. Get transition issues and balance feedback

## Validation Categories

### 1. Phase Configuration

| Check | Severity | Description |
|-------|----------|-------------|
| Phase Count | Info | Number of phases |
| Health Thresholds | Error | Valid percentage splits |
| Threshold Gaps | Warning | No skippable phases |
| Entry Conditions | Error | Phase entry logic valid |

### 2. Ability Unlocks

| Check | Severity | Description |
|-------|----------|-------------|
| Phase Abilities | Warning | Each phase has abilities |
| Unlock Timing | Warning | Abilities unlock correctly |
| Ability Overlap | Info | Cross-phase ability usage |

### 3. Behavior Validation

| Check | Severity | Description |
|-------|----------|-------------|
| BT Per Phase | Warning | Behavior tree assigned |
| Transition Logic | Error | Clean phase handoff |
| Invulnerability | Warning | I-frames during transition |

### 4. Balance Checks

| Check | Severity | Description |
|-------|----------|-------------|
| Phase Duration | Warning | Each phase has minimum time |
| Damage Windows | Warning | Player can deal damage |
| Recovery Time | Warning | Phase transition recovery |

## Validation Workflow

### Step 1: Parse Boss Configuration

```markdown
## Boss Analysis: BP_Boss_{BossName}

### Overview
| Property | Value |
|----------|-------|
| Total Health | {N} |
| Phase Count | {N} |
| Estimated Fight Duration | {N}min |

### Phase Configuration
| Phase | Health Range | Duration Est | BT |
|-------|--------------|--------------|-----|
| 1 | 100-70% | 60s | BT_Boss_Phase1 |
| 2 | 70-40% | 90s | BT_Boss_Phase2 |
| 3 | 40-0% | 120s | BT_Boss_Phase3 |
```

### Step 2: Validate Thresholds

```markdown
### Health Threshold Analysis

#### Threshold Values
| Phase | Entry Threshold | Exit Threshold | Gap |
|-------|-----------------|----------------|-----|
| 1 | 100% | 70% | 30% |
| 2 | 70% | 40% | 30% |
| 3 | 40% | 0% | 40% |

#### Issues

##### [WARNING] Uneven Phase Distribution
- **Phase 3**: 40% health (longest phase)
- **Phase 1**: 30% health (shortest phase)
- **Recommendation**: Consider 33%/33%/34% for even pacing

##### [ERROR] Threshold Gap
- **Between Phase 1 & 2**: 70%
- **Issue**: High burst damage could skip Phase 2 trigger
- **Fix**: Add phase transition lock or reduce gap
```

### Step 3: Validate Abilities

```markdown
### Phase Abilities

| Phase | Abilities | New Unlocks |
|-------|-----------|-------------|
| 1 | Slash, Stomp | Base set |
| 2 | Slash, Stomp, Charge, AoE | Charge, AoE |
| 3 | All + Enrage, Ultimate | Enrage, Ultimate |

### Ability Issues

#### [WARNING] Ability Without Unlock
- **Ability**: GA_Boss_DesperationAttack
- **Issue**: Referenced but never unlocked in any phase
- **Fix**: Add to Phase 3 ability list or remove

#### [INFO] Cross-Phase Ability
- **Ability**: GA_Boss_Slash
- **Usage**: All phases
- **Status**: OK (basic attack should persist)
```

### Step 4: Validate Transitions

```markdown
### Phase Transition Analysis

| Transition | Trigger | Duration | I-Frames |
|------------|---------|----------|----------|
| 1 → 2 | Health ≤ 70% | 3s | Yes |
| 2 → 3 | Health ≤ 40% | 5s | Yes |

### Transition Issues

#### [ERROR] Missing Invulnerability
- **Transition**: 2 → 3
- **Issue**: No I-frames during 5s transition
- **Impact**: Player can skip transition animation
- **Fix**: Grant invulnerability tag during transition

#### [WARNING] Long Transition
- **Transition**: 2 → 3
- **Duration**: 5s
- **Recommendation**: Keep transitions under 3s for pacing
```

### Step 5: Behavior Tree Validation

```markdown
### Behavior Tree Per Phase

| Phase | BT | Status | Issues |
|-------|-----|--------|--------|
| 1 | BT_Boss_Phase1 | Valid | None |
| 2 | BT_Boss_Phase2 | Valid | Heavy task |
| 3 | BT_Boss_Phase3 | Missing | Not found |

#### [ERROR] Missing Phase BT
- **Phase**: 3
- **Expected**: BT_Boss_{BossName}_Phase3
- **Fix**: Create BT or link existing
```

## Boss Phase Patterns

### Standard 3-Phase Boss

```
Phase 1: Introduction (100-70%)
├── Basic moveset only
├── Teach player patterns
└── Moderate aggression

Phase 2: Escalation (70-40%)
├── Add new abilities
├── Increase aggression
├── Environmental changes (optional)
└── Transition cutscene

Phase 3: Desperation (40-0%)
├── Full ability set
├── Enrage mechanics
├── Higher aggression/damage
└── Final push to victory
```

### Health Threshold Guidelines

| Phases | Recommended Splits |
|--------|-------------------|
| 2 | 50% / 50% |
| 3 | 33% / 33% / 34% |
| 4 | 25% / 25% / 25% / 25% |

### Transition Best Practices

1. **Invulnerability**: Always grant during transition
2. **Clear Visual**: Player knows phase changed
3. **Reset Position**: Move boss to arena center
4. **Brief Duration**: 2-4 seconds max
5. **Interruptible Attacks**: Cancel in-progress attacks

## Balance Validation

```markdown
### Balance Metrics

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total Health | 50000 | - | - |
| Expected DPS | 500 | - | - |
| Phase 1 Duration | 60s | 45-90s | OK |
| Phase 2 Duration | 60s | 60-120s | OK |
| Phase 3 Duration | 80s | 90-180s | Short |
| Damage Windows/Phase | 3-5 | 3-6 | OK |

### Balance Issues

#### [WARNING] Short Final Phase
- **Phase 3 Duration**: 80s estimated
- **Expected**: 90-180s
- **Issue**: Final phase may feel rushed
- **Fix**: Reduce Phase 3 damage taken or add health
```

## Output Report

```markdown
# Boss Phase Validation: {BossName}

## Summary
- **Status**: {PASS/WARNING/FAIL}
- **Phases**: {N}
- **Critical Issues**: {N}

## Phase Overview
{Table of phases with health/duration/BT}

## Critical Issues
1. {Issue}

## Warnings
1. {Warning}

## Balance Assessment
- Phase pacing: {Assessment}
- Difficulty curve: {Assessment}
- Player engagement: {Assessment}

## Recommendations
1. {Recommendation}
```
